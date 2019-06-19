import GRDB

class Balance: Record {
    let symbol: String
    let value: Decimal

    init(symbol: String, value: Decimal) {
        self.symbol = symbol
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case symbol
        case value
    }

    required init(row: Row) {
        symbol = row[Columns.symbol]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.symbol] = symbol
        container[Columns.value] = value
    }

}
