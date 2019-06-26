import RxSwift

protocol IStorage {
    var irreversibleBlock: IrreversibleBlock? { get }
    func save(irreversibleBlock: IrreversibleBlock)

    func balance(token: String, symbol: String) -> Balance?
    func save(balances: [Balance])

    var lastAction: Action? { get }
    func save(actions: [Action])

    func actionsSingle(receiver: String, token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]>
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IBalanceManagerDelegate: AnyObject {
    func didSync(token: String, balances: [Balance])
    func didFailToSync(token: String)
}

protocol IActionManagerDelegate: AnyObject {
    func didSync(irreversibleBlock: IrreversibleBlock)
    func didSync(actions: [Action])
}
