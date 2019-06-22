import RxSwift
import EosioSwift

public class EosKit {
    private let balanceSubject = PublishSubject<Decimal>()
    private let syncStateSubject = PublishSubject<SyncState>()

    private let balanceManager: BalanceManager
    private let actionManager: ActionManager

    public let account: String
    public let uniqueId: String
    public let logger: Logger

    private var assets = [Asset]()

    init(balanceManager: BalanceManager, actionManager: ActionManager, account: String, uniqueId: String, logger: Logger) {
        self.balanceManager = balanceManager
        self.actionManager = actionManager
        self.account = account
        self.uniqueId = uniqueId
        self.logger = logger
    }

    private func asset(token: String, symbol: String) -> Asset? {
        return assets.first { $0.token == token && $0.symbol == symbol }
    }

}

// Public API Extension

extension EosKit {

    public func register(token: String, symbol: String) -> Asset {
        let balance = balanceManager.balance(token: token, symbol: symbol)?.quantity.amount ?? 0
        let asset = Asset(token: token, symbol: symbol, balance: balance)
        assets.append(asset)
        return asset
    }

    public func unregister(asset: Asset) {
        assets.removeAll { $0 == asset }
    }

    public func refresh() {
        for asset in assets {
            asset.syncState = .syncing
        }

        let tokens = assets.map { $0.token }

        for token in Set(tokens) {
            balanceManager.sync(token: token, account: account)
        }

        actionManager.sync(account: account)
    }

    public func transactionsSingle(asset: Asset, fromActionSequence: Int? = nil, limit: Int? = nil) -> Single<[Transaction]> {
        return actionManager.transactionsSingle(token: asset.token, symbol: asset.symbol, fromActionSequence: fromActionSequence, limit: limit)
    }

}

extension EosKit: IBalanceManagerDelegate {

    func didSync(balance: Balance) {
        if let asset = asset(token: balance.token, symbol: balance.quantity.symbol) {
            asset.balance = balance.quantity.amount
            asset.syncState = .synced
        }
    }

    func didFailToSync(token: String) {
        for asset in assets.filter({ $0.token == token }) {
            asset.syncState = .notSynced
        }
    }

}

extension EosKit {

    public static func instance(account: String, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EosKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "eos-\(uniqueId)")

        let rpcProvider = EosioRpcProvider(endpoint: URL(string: "https://eos.greymass.com")!)

        let balanceManager = BalanceManager(storage: storage, rpcProvider: rpcProvider)
        let actionManager = ActionManager(storage: storage, rpcProvider: rpcProvider)

        let eosKit = EosKit(balanceManager: balanceManager, actionManager: actionManager, account: account, uniqueId: uniqueId, logger: logger)

        balanceManager.delegate = eosKit

        return eosKit
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

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

    public enum NetworkType {
        case mainNet
        case testNet
    }

}
