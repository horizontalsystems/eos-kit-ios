import EosKit
import RxSwift

class EosAdapter {
    private let eosKit: EosKit
    private let token: String
    private let symbol: String

    init(eosKit: EosKit, token: String, symbol: String) {
        self.eosKit = eosKit
        self.token = token
        self.symbol = symbol
    }

}

extension EosAdapter: IAdapter {

    var name: String {
        return "\(symbol) - \(token)"
    }

    var coin: String {
        return symbol
    }

    var lastBlockHeight: Int? {
        return nil
    }

    var syncState: EosKit.SyncState {
        return eosKit.syncState
    }

    var balance: Decimal {
        return eosKit.balance(token: token, symbol: symbol) ?? 0
    }

    var receiveAddress: String {
        return ""
    }

    var lastBlockHeightObservable: Observable<Void> {
        return Observable.empty()
    }

    var syncStateObservable: Observable<Void> {
        return eosKit.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return eosKit.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return Observable.empty()
    }

    func validate(address: String) throws {

    }

    func sendSingle(to: String, amount: Decimal) -> Single<Void> {
        return Single.just(())
    }

    func transactionsSingle(fromActionSequence: Int?, limit: Int?) -> Single<[Transaction]> {
        return eosKit.transactionsSingle(token: token, symbol: symbol, fromActionSequence: fromActionSequence, limit: limit)
    }

}
