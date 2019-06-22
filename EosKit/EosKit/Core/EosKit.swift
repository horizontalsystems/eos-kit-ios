import RxSwift
import HSHDWalletKit
import EosioSwift

public class EosKit {
    private let balanceSubject = PublishSubject<Decimal>()
    private let syncStateSubject = PublishSubject<SyncState>()

    private let balanceManager: BalanceManager
    private let actionManager: ActionManager

    public let account: String
    public let uniqueId: String
    public let logger: Logger

    init(balanceManager: BalanceManager, actionManager: ActionManager, account: String, uniqueId: String, logger: Logger) {
        self.balanceManager = balanceManager
        self.actionManager = actionManager
        self.account = account
        self.uniqueId = uniqueId
        self.logger = logger
    }

}

// Public API Extension

extension EosKit {

    public func start() {
        balanceManager.sync(token: "eosio.token", account: account)
        balanceManager.sync(token: "betdicetoken", account: account)
        actionManager.sync(account: account)
    }

    public func stop() {
    }

    public func refresh() {
    }

    public func balance(token: String, symbol: String) -> Decimal? {
        return balanceManager.balance(token: token, symbol: symbol)?.quantity.amount
    }

    public var balanceObservable: Observable<Decimal> {
        return balanceSubject.asObservable()
    }

    public var syncState: SyncState {
        return .notSynced
    }

    public var syncStateObservable: Observable<SyncState> {
        return syncStateSubject.asObservable()
    }

    public func transactionsSingle(token: String, symbol: String, fromActionSequence: Int? = nil, limit: Int? = nil) -> Single<[Transaction]> {
        return actionManager.transactionsSingle(token: token, symbol: symbol, fromActionSequence: fromActionSequence, limit: limit)
    }

}

extension EosKit {

    public static func instance(networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EosKit {
        let account = "esseexchange"

        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "eos-\(uniqueId)")

        let rpcProvider = EosioRpcProvider(endpoint: URL(string: "https://eos.greymass.com")!)

        let balanceManager = BalanceManager(storage: storage, rpcProvider: rpcProvider)
        let actionManager = ActionManager(storage: storage, rpcProvider: rpcProvider)

        let eosKit = EosKit(balanceManager: balanceManager, actionManager: actionManager, account: account, uniqueId: uniqueId, logger: logger)

        return eosKit
    }

    public static func instance(words: [String], networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EosKit {
//        let coinType: UInt32 = networkType == .mainNet ? 60 : 1
//
//        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: coinType, xPrivKey: 0, xPubKey: 0)
//        let privateKey = try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw

        return try instance(networkType: networkType, walletId: walletId, minLogLevel: minLogLevel)
    }

    public static func clear() throws {
        let fileManager = FileManager.default

        let urls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for url in urls {
            try fileManager.removeItem(at: url)
        }
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("eos-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}

extension EosKit {

    public enum SyncState: Equatable {
        case synced
        case syncing(progress: Double?)
        case notSynced

        public static func ==(lhs: EosKit.SyncState, rhs: EosKit.SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.synced, .synced), (.notSynced, .notSynced): return true
            case (.syncing(let lhsProgress), .syncing(let rhsProgress)): return lhsProgress == rhsProgress
            default: return false
            }
        }
    }

    public enum NetworkType {
        case mainNet
        case testNet
    }

}
