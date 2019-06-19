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
                t.column(Balance.Columns.symbol.name, .text).notNull()
                t.column(Balance.Columns.value.name, .text).notNull()

                t.primaryKey([Balance.Columns.symbol.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension Storage: IStorage {

    func balance(symbol: String) -> Balance? {
        return try? dbPool.read { db in
            try Balance.filter(Balance.Columns.symbol == symbol).fetchOne(db)
        }
    }

    func save(balances: [Balance]) {
        _ = try? dbPool.write { db in
            for balance in  balances {
                try balance.insert(db)
            }
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
