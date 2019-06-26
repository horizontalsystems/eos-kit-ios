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

extension EosAdapter {

    var name: String {
        return "\(asset.symbol) - \(asset.token)"
    }

    var coin: String {
        return asset.symbol
    }

    var irreversibleBlockHeight: Int? {
        return eosKit.irreversibleBlockHeight
    }

    var syncState: EosKit.SyncState {
        return asset.syncState
    }

    var balance: Decimal {
        return asset.balance
    }

    var irreversibleBlockHeightObservable: Observable<Void> {
        return eosKit.irreversibleBlockHeightObservable.map { _ in () }
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

    func sendSingle(to: String, amount: Decimal, memo: String) -> Single<String?> {
        return eosKit.sendSingle(asset: asset, to: to, amount: amount, memo: memo)
    }

    func transactionsSingle(fromActionSequence: Int?, limit: Int?) -> Single<[Transaction]> {
        return eosKit.transactionsSingle(asset: asset, fromActionSequence: fromActionSequence, limit: limit)
    }

}
