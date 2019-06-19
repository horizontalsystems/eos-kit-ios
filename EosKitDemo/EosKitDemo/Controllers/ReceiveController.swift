import UIKit

class ReceiveController: UIViewController {

    @IBOutlet weak var addressLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Receive"

        addressLabel?.layer.cornerRadius = 8
        addressLabel?.clipsToBounds = true

        addressLabel?.text = "  \(Manager.shared.eosAdapters[0].receiveAddress)  "
    }

    @IBAction func copyToClipboard() {
        UIPasteboard.general.setValue(Manager.shared.eosAdapters[0].receiveAddress, forPasteboardType: "public.plain-text")

        let alert = UIAlertController(title: "Success", message: "Address copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}
