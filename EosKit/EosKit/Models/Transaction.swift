public class Transaction {
    public let id: String
    public let blockNumber: Int
    public let quantity: Quantity
    public let from: String
    public let to: String
    public let memo: String?
    public let date: Date
    public let actionSequence: Int

    init?(action: Action) {
        guard let quantity = action.quantity else {
            return nil
        }

        guard let from = action.from else {
            return nil
        }

        guard let to = action.to else {
            return nil
        }

        guard let date = Transaction.dateFormatter.date(from: action.blockTime) else {
            return nil
        }

        self.id = action.transactionId
        self.blockNumber = action.blockNumber
        self.quantity = quantity
        self.from = from
        self.to = to
        self.memo = action.memo
        self.date = date
        self.actionSequence = action.accountActionSequence
    }

}

extension Transaction {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

}
