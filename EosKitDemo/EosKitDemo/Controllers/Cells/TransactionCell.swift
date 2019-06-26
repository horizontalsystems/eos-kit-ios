import UIKit
import EosKit

class TransactionCell: UITableViewCell {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?

    func bind(transaction: Transaction, coin: String, irreversibleBlockHeight: Int?) {
        var status = "n/a"

        if let irreversibleBlockHeight = irreversibleBlockHeight {
            if transaction.blockNumber <= irreversibleBlockHeight {
                status = "irreversible"
            } else {
                status = "\(transaction.blockNumber - irreversibleBlockHeight) blocks until irreversibility"
            }
        }

        set(string: """
                    Tx Id:
                    Status:
                    Block number:
                    Sequence:
                    Date:
                    Quantity:
                    From:
                    To:
                    Memo:
                    """, alignment: .left, label: titleLabel)

        set(string: """
                    \(shorten(string: transaction.id))
                    \(status)
                    \(transaction.blockNumber)
                    \(transaction.actionSequence)
                    \(TransactionCell.dateFormatter.string(from: transaction.date))
                    \(transaction.quantity.amount) \(transaction.quantity.symbol)
                    \(transaction.from)
                    \(transaction.to)
                    \(transaction.memo.map { shorten(string: $0) } ?? "nil")
                    """, alignment: .right, label: valueLabel)
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label?.attributedText = attributedString
    }

    private func shorten(string: String) -> String {
        guard string.count > 22 else {
            return string
        }

        return "\(string[..<string.index(string.startIndex, offsetBy: 10)])...\(string[string.index(string.endIndex, offsetBy: -10)...])"
    }

}
