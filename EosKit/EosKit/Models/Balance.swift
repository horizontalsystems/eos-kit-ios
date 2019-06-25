import GRDB

class Balance: Record {
    let token: String
    let quantity: Quantity

    init(token: String, quantity: Quantity) {
        self.token = token
        self.quantity = quantity

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case token
        case amount
        case symbol
    }

    required init(row: Row) {
        token = row[Columns.token]
        quantity = Quantity(amount: row[Columns.amount], symbol: row[Columns.symbol])

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.token] = token
        container[Columns.amount] = quantity.amount
        container[Columns.symbol] = quantity.symbol
    }

}

extension Balance: CustomStringConvertible {

    public var description: String {
        return "BALANCE: [token: \(token); quantity: \(quantity)]"
    }

}
