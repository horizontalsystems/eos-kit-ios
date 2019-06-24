import RxSwift
import EosioSwift
import EosioSwiftAbieosSerializationProvider
import EosioSwiftSoftkeySignatureProvider

public class EosKit {
    private let balanceSubject = PublishSubject<Decimal>()
    private let syncStateSubject = PublishSubject<SyncState>()

    private let balanceManager: BalanceManager
    private let actionManager: ActionManager
    private let transactionManager: TransactionManager

    private let logger: Logger

    private var assets = [Asset]()

    init(balanceManager: BalanceManager, actionManager: ActionManager, transactionManager: TransactionManager, logger: Logger) {
        self.balanceManager = balanceManager
        self.actionManager = actionManager
        self.transactionManager = transactionManager
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
            balanceManager.sync(token: token)
        }

        actionManager.sync()
    }

    public func transactionsSingle(asset: Asset, fromActionSequence: Int? = nil, limit: Int? = nil) -> Single<[Transaction]> {
        return actionManager.actionsSingle(token: asset.token, symbol: asset.symbol, fromActionSequence: fromActionSequence, limit: limit)
                .map { $0.compactMap { Transaction(action: $0) } }
    }

    public func sendSingle(asset: Asset, to: String, amount: Decimal, memo: String) -> Single<String?> {
        let quantity = Quantity(amount: amount, symbol: asset.symbol)
        return transactionManager.sendSingle(token: asset.token, to: to, quantity: quantity, memo: memo)
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

extension EosKit: IActionManagerDelegate {

    func didSync(actions: [Action]) {
        let tokensMap = Dictionary(grouping: actions, by: { $0.account })

        for (token, actions) in tokensMap {
            let transactions = actions.compactMap { Transaction(action: $0) }

            let transactionsMap = Dictionary(grouping: transactions, by: { $0.quantity.symbol })

            for (symbol, transactions) in transactionsMap {
                asset(token: token, symbol: symbol)?.transactionsSubject.onNext(transactions)
            }
        }
    }

}

extension EosKit {

    public static func instance(account: String, activePrivateKey: String, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> EosKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "eos-\(uniqueId)")

        let rpcProvider = EosioRpcProvider(endpoint: URL(string: "https://eos.greymass.com")!)

        let balanceManager = BalanceManager(account: account, storage: storage, rpcProvider: rpcProvider, logger: logger)
        let actionManager = ActionManager(account: account, storage: storage, rpcProvider: rpcProvider, logger: logger)

        let serializationProvider = EosioAbieosSerializationProvider()
        let signatureProvider = try EosioSoftkeySignatureProvider(privateKeys: [activePrivateKey])
        let transactionFactory = EosioTransactionFactory(rpcProvider: rpcProvider, signatureProvider: signatureProvider, serializationProvider: serializationProvider)

        let transactionManager = TransactionManager(account: account, storage: storage, transactionFactory: transactionFactory, logger: logger)

        let eosKit = EosKit(balanceManager: balanceManager, actionManager: actionManager, transactionManager: transactionManager, logger: logger)

        balanceManager.delegate = eosKit
        actionManager.delegate = eosKit

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
