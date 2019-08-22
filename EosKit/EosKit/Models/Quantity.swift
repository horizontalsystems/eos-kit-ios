public class Quantity {
    public let amount: Decimal
    public let symbol: String

    init(amount: Decimal, symbol: String) {
        self.amount = amount
        self.symbol = symbol
    }

    convenience init?(string: String) {
        let parts = string.split(separator: " ")

        guard parts.count == 2 else {
            return nil
        }

        let valueString = String(parts[0])
        let symbol = String(parts[1])

        guard let amount = Decimal(string: valueString) else {
            return nil
        }

        self.init(amount: amount, symbol: symbol)
    }

}
