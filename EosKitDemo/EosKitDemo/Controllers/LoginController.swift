import UIKit

class LoginController: UIViewController {

    @IBOutlet weak var accountTextField: UITextField?
    @IBOutlet weak var activePrivateKeyTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "EosKit Demo"

        accountTextField?.text = Configuration.shared.defaultAccount
        activePrivateKeyTextField?.text = Configuration.shared.defaultActivePrivateKey
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func login() {
        let account = accountTextField?.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let activePrivateKey = activePrivateKeyTextField?.text?.trimmingCharacters(in: .whitespaces) ?? ""

        do {
            try Manager.shared.login(account: account, activePrivateKey: activePrivateKey)

            if let window = UIApplication.shared.keyWindow {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = MainController()
                })
            }
        } catch {
            let alert = UIAlertController(title: "Validation Error", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

}
