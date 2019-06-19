import EosKit
import RxSwift

class EosAdapter {
    private let eosKit: EosKit

    init(eosKit: EosKit) {
        self.eosKit = eosKit
    }

}

extension EosAdapter: IAdapter {

    var name: String {
        return "Eos"
    }

    var coin: String {
        return "EOS"
    }

    var lastBlockHeight: Int? {
        return nil
    }

    var syncState: EosKit.SyncState {
        return eosKit.syncState
    }

    var balance: Double {
        return eosKit.balance ?? 0
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

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int?) -> Single<[TransactionRecord]> {
        return Single.just([])
    }

}
