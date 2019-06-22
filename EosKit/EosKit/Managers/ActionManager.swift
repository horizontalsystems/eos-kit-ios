import RxSwift
import EosioSwift

class ActionManager {
    weak var delegate: IActionManagerDelegate?

    private let account: String
    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider

    init(account: String, storage: IStorage, rpcProvider: EosioRpcProvider) {
        self.account = account
        self.storage = storage
        self.rpcProvider = rpcProvider
    }

    func transactionsSingle(token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Transaction]> {
        return storage.actionsSingle(token: token, symbol: symbol, fromActionSequence: fromActionSequence, limit: limit)
                .map {
                    $0.compactMap { Transaction(action: $0) }
                }
    }

    func sync() {
        let lastSequence = storage.lastAction?.accountActionSequence ?? -1

        let request = EosioRpcHistoryActionsRequest(position: Int32(lastSequence + 1), offset: 1000, accountName: account)

        rpcProvider.getActions(requestParameters: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handle(response: response)
            case .failure(let error):
                print("ActionManager sync failure: \(error.reason)")
            }
        }
    }

    private func handle(response: EosioRpcActionsResponse) {
        print("Actions: \(response.actions.count)")

        let actions = response.actions.map { action(from: $0) }

        guard !actions.isEmpty else {
            return
        }

        storage.save(actions: actions)

        delegate?.didSync(actions: actions)

        sync()
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
                quantity: quantity,
                from: from,
                to: to,
                memo: memo
        )
    }

}
