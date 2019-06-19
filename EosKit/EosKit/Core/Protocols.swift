import RxSwift

protocol IStorage {
    func balance(symbol: String) -> Balance?
    func save(balances: [Balance])
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}
