import GRDB

class Balance: Record {
    private static let primaryKey = "primaryKey"

    private let primaryKey: String = Balance.primaryKey

    let value: Double

    init(value: Double) {
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case value
    }

    required init(row: Row) {
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.value] = value
    }

}
