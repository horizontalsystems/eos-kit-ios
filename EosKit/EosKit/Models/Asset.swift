import RxSwift

class Asset {
    let token: String
    let symbol: String

    var balance: Decimal {
        didSet {
            balanceSubject.onNext(balance)
        }
    }

    var syncState: EosKit.SyncState = .notSynced {
        didSet {
            syncStateSubject.onNext(syncState)
        }
    }

    let syncStateSubject = PublishSubject<EosKit.SyncState>()
    let balanceSubject = PublishSubject<Decimal>()
    let transactionsSubject = PublishSubject<Transaction>()

    init(token: String, symbol: String, balance: Decimal) {
        self.token = token
        self.symbol = symbol
        self.balance = balance
    }
}
