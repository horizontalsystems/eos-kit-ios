import GRDB

class IrreversibleBlock: Record {
    private let primaryKey = "primary_key"
    let height: Int

    init(height: Int) {
        self.height = height

        super.init()
    }

    override class var databaseTableName: String {
        return "irreversible_block"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case height
    }

    required init(row: Row) {
        height = row[Columns.height]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.height] = height
    }

}

extension IrreversibleBlock: CustomStringConvertible {

    public var description: String {
        return "IRREVERSIBLE BLOCK: [height: \(height)]"
    }

}
