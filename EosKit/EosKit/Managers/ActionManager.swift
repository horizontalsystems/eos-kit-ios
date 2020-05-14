import RxSwift
import EosioSwift
import HsToolKit

class ActionManager {
    private static let maxRecordFetchCount: Int32 = 100

    weak var delegate: IActionManagerDelegate?

    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider
    private let logger: Logger

    init(storage: IStorage, rpcProvider: EosioRpcProvider, logger: Logger) {
        self.storage = storage
        self.rpcProvider = rpcProvider
        self.logger = logger
    }

    var irreversibleBlock: IrreversibleBlock? {
        return storage.irreversibleBlock
    }

    func actionsSingle(account: String, token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]> {
        storage.actionsSingle(receiver: account, token: token, symbol: symbol, fromActionSequence: fromActionSequence, limit: limit)
    }

    func action(account: String, token: String, symbol: String, actionSequence: Int) -> Action? {
        storage.action(receiver: account, token: token, symbol: symbol, actionSequence: actionSequence)
    }

    func sync(account: String) {
        let lastSequence = storage.lastAction?.accountActionSequence ?? -1

        logger.verbose("Syncing actions starting from \(lastSequence)")

        let request = EosioRpcHistoryActionsRequest(position: Int32(lastSequence + 1), offset: ActionManager.maxRecordFetchCount, accountName: account)

        rpcProvider.getActions(requestParameters: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handle(response: response, account: account)
            case .failure(let error):
                self?.logger.error("ActionManager sync failure: \(error.reason)")
            }
        }
    }

    private func handle(response: EosioRpcActionsResponse, account: String) {
        logger.debug("Actions received: \(response.actions.count) --- \(response.lastIrreversibleBlock)")

        let irreversibleBlock = IrreversibleBlock(height: Int(response.lastIrreversibleBlock.value))
        let actions = response.actions.map { action(from: $0) }

        storage.save(irreversibleBlock: irreversibleBlock)
        delegate?.didSync(irreversibleBlock: irreversibleBlock)

        guard !actions.isEmpty else {
            return
        }

        storage.save(actions: actions)

        let filteredActions = actions.filter { $0.receiver == account && $0.name == "transfer" }
        delegate?.didSync(actions: filteredActions)

        sync(account: account)
    }

    private func action(from actionResponse: EosioRpcActionsResponseAction) -> Action {
        let data = actionResponse.actionTrace.action.data

        let quantityString = data["quantity"] as? String
        let quantity = quantityString.flatMap { Quantity(string: $0) }

        let from = data["from"] as? String
        let to = data["to"] as? String
        let memo = data["memo"] as? String

        return Action(
                accountActionSequence: Int(actionResponse.accountActionSequence),
                blockNumber: Int(actionResponse.blockNumber),
                blockTime: actionResponse.blockTime,
                transactionId: actionResponse.actionTrace.transactionId,
                account: actionResponse.actionTrace.action.account,
                name: actionResponse.actionTrace.action.name,
                receiver: actionResponse.actionTrace.receipt.receiver,
                quantity: quantity,
                from: from,
                to: to,
                memo: memo
        )
    }

}
