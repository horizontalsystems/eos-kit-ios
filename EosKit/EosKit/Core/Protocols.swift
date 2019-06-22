import RxSwift

protocol IStorage {
    func balance(token: String, symbol: String) -> Balance?
    func save(balances: [Balance])

    func save(actions: [Action])

    func actionsSingle(token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]>
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}
