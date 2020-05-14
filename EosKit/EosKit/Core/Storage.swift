import RxSwift
import GRDB

class Storage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBalance") { db in
            try db.create(table: Balance.databaseTableName) { t in
                t.column(Balance.Columns.token.name, .text).notNull()
                t.column(Balance.Columns.symbol.name, .text).notNull()
                t.column(Balance.Columns.amount.name, .text).notNull()

                t.primaryKey([Balance.Columns.token.name, Balance.Columns.symbol.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createAction") { db in
            try db.create(table: Action.databaseTableName) { t in
                t.column(Action.Columns.accountActionSequence.name, .integer).notNull()
                t.column(Action.Columns.blockNumber.name, .integer).notNull()
                t.column(Action.Columns.blockTime.name, .text).notNull()
                t.column(Action.Columns.transactionId.name, .text).notNull()
                t.column(Action.Columns.account.name, .text).notNull()
                t.column(Action.Columns.name.name, .text).notNull()
                t.column(Action.Columns.receiver.name, .text).notNull()

                t.column(Action.Columns.amount.name, .text)
                t.column(Action.Columns.symbol.name, .text)
                t.column(Action.Columns.from.name, .text)
                t.column(Action.Columns.to.name, .text)
                t.column(Action.Columns.memo.name, .text)

                t.primaryKey([Action.Columns.accountActionSequence.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createIrreversibleBlock") { db in
            try db.create(table: IrreversibleBlock.databaseTableName) { t in
                t.column(IrreversibleBlock.Columns.primaryKey.name, .text).notNull()
                t.column(IrreversibleBlock.Columns.height.name, .integer).notNull()

                t.primaryKey([IrreversibleBlock.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension Storage: IStorage {

    var irreversibleBlock: IrreversibleBlock? {
        return try? dbPool.read { db in
            try IrreversibleBlock.fetchOne(db)
        }
    }

    func save(irreversibleBlock: IrreversibleBlock) {
        _ = try? dbPool.write { db in
            try irreversibleBlock.insert(db)
        }
    }

    func balance(token: String, symbol: String) -> Balance? {
        return try? dbPool.read { db in
            try Balance.filter(Balance.Columns.token == token && Balance.Columns.symbol == symbol).fetchOne(db)
        }
    }

    func save(balances: [Balance]) {
        _ = try? dbPool.write { db in
            for balance in  balances {
                try balance.insert(db)
            }
        }
    }

    var lastAction: Action? {
        return try? dbPool.read { db in
            try Action.order(Action.Columns.accountActionSequence.desc).fetchOne(db)
        }
    }

    func save(actions: [Action]) {
        _ = try? dbPool.write { db in
            for action in actions {
                try action.insert(db)
            }
        }
    }

    func actionsSingle(receiver: String, token: String, symbol: String, fromActionSequence: Int?, limit: Int?) -> Single<[Action]> {
        return Single.create { [weak self] observer in
            try? self?.dbPool.read { db in
                var request = Action.filter(Action.Columns.receiver == receiver && Action.Columns.account == token && Action.Columns.name == "transfer" && Action.Columns.symbol == symbol)

                if let fromActionSequence = fromActionSequence {
                    request = request.filter(Action.Columns.accountActionSequence < fromActionSequence)
                }

                if let limit = limit {
                    request = request.limit(limit)
                }

                let actions = try request.order(Action.Columns.accountActionSequence.desc).fetchAll(db)

                observer(.success(actions))
            }

            return Disposables.create()
        }
    }

    func action(receiver: String, token: String, symbol: String, actionSequence: Int) -> Action? {
        try? dbPool.read { db in
            try Action.filter(Action.Columns.receiver == receiver && Action.Columns.account == token && Action.Columns.name == "transfer" && Action.Columns.symbol == symbol && Action.Columns.accountActionSequence == actionSequence).fetchOne(db)
        }
    }

}

extension Decimal: DatabaseValueConvertible {

    public var databaseValue: DatabaseValue {
        return NSDecimalNumber(decimal: self).stringValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Decimal? {
        guard case .string(let rawValue) = dbValue.storage else {
            return nil
        }
        return Decimal(string: rawValue)
    }

}
