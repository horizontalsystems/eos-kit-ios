import EosKit
import RxSwift

class EosAdapter {
    private let eosKit: EosKit
    private let asset: Asset

    init(eosKit: EosKit, token: String, symbol: String) {
        self.eosKit = eosKit

        asset = eosKit.register(token: token, symbol: symbol)
    }

}

extension EosAdapter: IAdapter {

    var name: String {
        return "\(asset.symbol) - \(asset.token)"
    }

    var coin: String {
        return asset.symbol
    }

    var lastBlockHeight: Int? {
        return nil
    }

    var syncState: EosKit.SyncState {
        return asset.syncState
    }

    var balance: Decimal {
        return asset.balance
    }

    var receiveAddress: String {
        return ""
    }

    var lastBlockHeightObservable: Observable<Void> {
        return Observable.empty()
    }

    var syncStateObservable: Observable<Void> {
        return asset.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return asset.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return asset.transactionsObservable.map { _ in () }
    }

    func validate(address: String) throws {

    }

    func sendSingle(to: String, amount: Decimal) -> Single<Void> {
        return Single.just(())
    }

    func transactionsSingle(fromActionSequence: Int?, limit: Int?) -> Single<[Transaction]> {
        return eosKit.transactionsSingle(asset: asset, fromActionSequence: fromActionSequence, limit: limit)
    }

}
