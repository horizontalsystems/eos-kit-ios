import RxSwift
import EosioSwift

class ActionManager {
    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider

    init(storage: IStorage, rpcProvider: EosioRpcProvider) {
        self.storage = storage
        self.rpcProvider = rpcProvider
    }

    func transactionsSingle(token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Transaction]> {
        return storage.actionsSingle(token: token, symbol: symbol, fromActionSequence: fromActionSequence, limit: limit)
                .map {
                    $0.compactMap { Transaction(action: $0) }
                }
    }

    func sync(account: String) {
        let request = EosioRpcHistoryActionsRequest(position: 0, offset: 20, accountName: account)

        rpcProvider.getActions(requestParameters: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handle(response: response)
            case .failure(let error):
                print("ACTIONS REFRESH FAILURE")
                print(error)
                print(error.reason)
            }
        }
    }

    private func handle(response: EosioRpcActionsResponse) {
        print("Actions: \(response.actions.count)")

        let actions = response.actions.map { action(from: $0) }

        storage.save(actions: actions)
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
