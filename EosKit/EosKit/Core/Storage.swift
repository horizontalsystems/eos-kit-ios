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
                t.column(Balance.Columns.primaryKey.name, .text).notNull()
                t.column(Balance.Columns.value.name, .text).notNull()

                t.primaryKey([Balance.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension Storage: IStorage {

    var balance: Double? {
        return try! dbPool.read { db in
            try Balance.fetchOne(db)?.value
        }
    }

    func save(balance: Double) {
        _ = try? dbPool.write { db in
            let balanceObject = Balance(value: balance)
            try balanceObject.insert(db)
        }
    }

}
