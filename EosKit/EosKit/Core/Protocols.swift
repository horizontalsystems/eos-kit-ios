import RxSwift

protocol IStorage {
    var irreversibleBlock: IrreversibleBlock? { get }
    func save(irreversibleBlock: IrreversibleBlock)

    func balance(token: String, symbol: String) -> Balance?
    func save(balances: [Balance])

    var lastAction: Action? { get }
    func save(actions: [Action])

    func actionsSingle(receiver: String, token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]>
    func action(receiver: String, token: String, symbol: String, actionSequence: Int) -> Action?
}

protocol IBalanceManagerDelegate: AnyObject {
    func didSync(token: String, balances: [Balance])
    func didFailToSync(token: String, error: Error)
}

protocol IActionManagerDelegate: AnyObject {
    func didSync(irreversibleBlock: IrreversibleBlock)
    func didSync(actions: [Action])
}
