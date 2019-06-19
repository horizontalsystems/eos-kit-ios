import RxSwift

protocol IStorage {
    var balance: Double? { get }
    func save(balance: Double)
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}
