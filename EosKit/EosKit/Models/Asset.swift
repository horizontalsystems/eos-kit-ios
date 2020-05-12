import RxSwift

public class Asset {
    public let token: String
    public let symbol: String
    public let decimalCount: Int

    public var balance: Decimal {
        didSet {
            balanceSubject.onNext(balance)
        }
    }

    public var syncState: EosKit.SyncState = .notSynced(error: EosKit.SyncError.notStarted) {
        didSet {
            syncStateSubject.onNext(syncState)
        }
    }

    private let syncStateSubject = PublishSubject<EosKit.SyncState>()
    private let balanceSubject = PublishSubject<Decimal>()
    let transactionsSubject = PublishSubject<[Transaction]>()

    init(token: String, symbol: String, decimalCount: Int, balance: Decimal) {
        self.token = token
        self.symbol = symbol
        self.decimalCount = decimalCount
        self.balance = balance
    }

    public var syncStateObservable: Observable<EosKit.SyncState> {
        return syncStateSubject.asObservable()
    }

    public var balanceObservable: Observable<Decimal> {
        return balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[Transaction]> {
        return transactionsSubject.asObservable()
    }

}

extension Asset: Equatable {

    public static func ==(lhs: Asset, rhs: Asset) -> Bool {
        return lhs.token == rhs.token && lhs.symbol == rhs.symbol
    }

}

extension Asset: CustomStringConvertible {

    public var description: String {
        return "ASSET: [token: \(token); symbol: \(symbol); balance: \(balance); syncState: \(syncState)]"
    }

}
