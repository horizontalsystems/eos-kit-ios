import GRDB

public class Action: Record {
    public let accountActionSequence: Int
    public let blockNumber: Int
    public let blockTime: String
    public let transactionId: String
    public let account: String
    public let name: String
    public let receiver: String

    public var quantity: Quantity?
    public var from: String?
    public var to: String?
    public var memo: String?

    init(accountActionSequence: Int, blockNumber: Int, blockTime: String, transactionId: String, account: String, name: String, receiver: String, quantity: Quantity?, from: String?, to: String?, memo: String?) {
        self.accountActionSequence = accountActionSequence
        self.blockNumber = blockNumber
        self.blockTime = blockTime
        self.transactionId = transactionId
        self.account = account
        self.name = name
        self.receiver = receiver

        self.quantity = quantity
        self.from = from
        self.to = to
        self.memo = memo

        super.init()
    }

    override public class var databaseTableName: String {
        return "actions"
    }

    enum Columns: String, ColumnExpression {
        case accountActionSequence
        case blockNumber
        case blockTime
        case transactionId
        case account
        case name
        case receiver

        case amount
        case symbol
        case from
        case to
        case memo
    }

    required init(row: Row) {
        accountActionSequence = row[Columns.accountActionSequence]
        blockNumber = row[Columns.blockNumber]
        blockTime = row[Columns.blockTime]
        transactionId = row[Columns.transactionId]
        account = row[Columns.account]
        name = row[Columns.name]
        receiver = row[Columns.receiver]

        let amount: Decimal? = row[Columns.amount]
        let symbol: String? = row[Columns.symbol]

        if let amount = amount, let symbol = symbol {
            quantity = Quantity(amount: amount, symbol: symbol)
        }

        from = row[Columns.from]
        to = row[Columns.to]
        memo = row[Columns.memo]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.accountActionSequence] = accountActionSequence
        container[Columns.blockNumber] = blockNumber
        container[Columns.blockTime] = blockTime
        container[Columns.transactionId] = transactionId
        container[Columns.account] = account
        container[Columns.name] = name
        container[Columns.receiver] = receiver

        container[Columns.amount] = quantity?.amount
        container[Columns.symbol] = quantity?.symbol
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.memo] = memo
    }

}
