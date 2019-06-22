import RxSwift

protocol IStorage {
    func balance(token: String, symbol: String) -> Balance?
    func save(balances: [Balance])

    var lastAction: Action? { get }
    func save(actions: [Action])

    func actionsSingle(token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]>
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IBalanceManagerDelegate: AnyObject {
    func didSync(balance: Balance)
    func didFailToSync(token: String)
}

protocol IActionManagerDelegate: AnyObject {
    func didSync(actions: [Action])
}
