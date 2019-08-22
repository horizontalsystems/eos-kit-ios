import RxSwift
import EosioSwift
import EosioSwiftAbieosSerializationProvider
import EosioSwiftSoftkeySignatureProvider

public class EosKit {
    private let disposeBag = DisposeBag()

    private let balanceManager: BalanceManager
    private let actionManager: ActionManager
    private let transactionManager: TransactionManager
    private let reachabilityManager: ReachabilityManager

    private let logger: Logger

    public let account: String
    public var irreversibleBlockHeight: Int?
    private let irreversibleBlockHeightSubject = PublishSubject<Int>()

    private var assets = [Asset]()
    private var syncingAssets = [Asset]()

    init(account: String, balanceManager: BalanceManager, actionManager: ActionManager, transactionManager: TransactionManager, reachabilityManager: ReachabilityManager, logger: Logger) {
        self.account = account
        self.balanceManager = balanceManager
        self.actionManager = actionManager
        self.transactionManager = transactionManager
        self.reachabilityManager = reachabilityManager
        self.logger = logger

        irreversibleBlockHeight = actionManager.irreversibleBlock?.height

        reachabilityManager.reachabilitySignal
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.refresh()
                })
                .disposed(by: disposeBag)
    }

    private func asset(token: String, symbol: String) -> Asset? {
        return assets.first { $0.token == token && $0.symbol == symbol }
    }

    private func sync(asset: Asset) {
        guard reachabilityManager.isReachable else {
            asset.syncState = .notSynced
            return
        }

        guard !syncingAssets.contains(asset) else {
            logger.verbose("Already syncing: \(asset)")
            return
        }

        logger.verbose("Syncing asset: \(asset)")

        asset.syncState = .syncing

        let token = asset.token
        let alreadySyncingToken = syncingAssets.contains { $0.token == token }

        syncingAssets.append(asset)

        guard !alreadySyncingToken else {
            logger.verbose("Already syncing token: \(token)")
            return
        }

        balanceManager.sync(account: account, token: token)
    }

    private func syncActions() {
        guard reachabilityManager.isReachable else {
            return
        }

        actionManager.sync(account: account)
    }

}

// Public API Extension

extension EosKit {

    public func register(token: String, symbol: String, decimalCount: Int) -> Asset {
        let balance = balanceManager.balance(token: token, symbol: symbol)?.quantity.amount ?? 0
        let asset = Asset(token: token, symbol: symbol, decimalCount: decimalCount, balance: balance)

        assets.append(asset)
        sync(asset: asset)

        return asset
    }

    public func unregister(asset: Asset) {
        assets.removeAll { $0 == asset }
    }

    public func refresh() {
        for asset in assets {
            sync(asset: asset)
        }

        syncActions()
    }

    public var irreversibleBlockHeightObservable: Observable<Int> {
        return irreversibleBlockHeightSubject.asObservable()
    }

    public func transactionsSingle(asset: Asset, fromActionSequence: Int? = nil, limit: Int? = nil) -> Single<[Transaction]> {
        return actionManager.actionsSingle(account: account, token: asset.token, symbol: asset.symbol, fromActionSequence: fromActionSequence, limit: limit)
                .map { $0.compactMap { Transaction(action: $0) } }
    }

    public func sendSingle(asset: Asset, to: String, amount: Decimal, memo: String) -> Single<String?> {
        let formatter = EosKit.formatter
        formatter.minimumFractionDigits = asset.decimalCount
        formatter.maximumFractionDigits = asset.decimalCount
        let amountString = formatter.string(from: amount as NSDecimalNumber) ?? ""
        let quantityString = "\(amountString) \(asset.symbol)"

        return transactionManager.sendSingle(account: account, token: asset.token, to: to, quantityString: quantityString, memo: memo)
                .do(onSuccess: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.refresh()
                    }
                })
    }

}

extension EosKit {

    public static func validate(privateKey: String) throws {
        do {
            _ = try EosioSoftkeySignatureProvider(privateKeys: [privateKey])
        } catch {
            throw ValidationError.invalidPrivateKey
        }
    }

}

extension EosKit: IBalanceManagerDelegate {

    func didSync(token: String, balances: [Balance]) {
        let matchingAssets = syncingAssets.filter { $0.token == token }

        for asset in matchingAssets {
            let balance = balances.first(where: { $0.quantity.symbol == asset.symbol })

            asset.balance = balance?.quantity.amount ?? 0
            asset.syncState = .synced
        }

        syncingAssets.removeAll { matchingAssets.contains($0) }
    }

    func didFailToSync(token: String) {
        let matchingAssets = syncingAssets.filter { $0.token == token }

        for asset in matchingAssets {
            asset.syncState = .notSynced
        }

        syncingAssets.removeAll { matchingAssets.contains($0) }
    }

}

extension EosKit: IActionManagerDelegate {

    func didSync(irreversibleBlock: IrreversibleBlock) {
        irreversibleBlockHeight = irreversibleBlock.height
        irreversibleBlockHeightSubject.onNext(irreversibleBlock.height)
    }

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

    public static func instance(account: String, activePrivateKey: String, networkType: NetworkType = .mainNet, walletId: String, minLogLevel: Logger.Level = .error) throws -> EosKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "eos-\(uniqueId)")

        let rpcProvider = EosioRpcProvider(endpoint: URL(string: "https://eos.greymass.com")!)

        let balanceManager = BalanceManager(storage: storage, rpcProvider: rpcProvider, logger: logger)
        let actionManager = ActionManager(storage: storage, rpcProvider: rpcProvider, logger: logger)

        let serializationProvider = EosioAbieosSerializationProvider()
        let signatureProvider = try EosioSoftkeySignatureProvider(privateKeys: [activePrivateKey])
        let transactionFactory = EosioTransactionFactory(rpcProvider: rpcProvider, signatureProvider: signatureProvider, serializationProvider: serializationProvider)

        let transactionManager = TransactionManager(storage: storage, transactionFactory: transactionFactory, logger: logger)
        let reachabilityManager = ReachabilityManager()

        let eosKit = EosKit(account: account, balanceManager: balanceManager, actionManager: actionManager, transactionManager: transactionManager, reachabilityManager: reachabilityManager, logger: logger)

        balanceManager.delegate = eosKit
        actionManager.delegate = eosKit

        return eosKit
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
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

    public enum ValidationError: Error {
        case invalidPrivateKey
    }

}

extension EosKit {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.decimalSeparator = "."
        formatter.minimumIntegerDigits = 1

        return formatter
    }()

}
