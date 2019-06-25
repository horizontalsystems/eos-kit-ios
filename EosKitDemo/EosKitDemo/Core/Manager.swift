import RxSwift
import EosKit

class Manager {
    static let shared = Manager()

    private let keyAuth = "eos_auth"

    var eosKit: EosKit!
    var account: String!

    var eosAdapters = [EosAdapter]()

    init() {
        if let auth = savedAuth {
            try? initEosKit(account: auth.account, activePrivateKey: auth.activePrivateKey)
        }
    }

    func login(account: String, activePrivateKey: String) throws {
        try EosKit.clear()
        try initEosKit(account: account, activePrivateKey: activePrivateKey)
        save(account: account, activePrivateKey: activePrivateKey)
    }

    func logout() {
        clearAuth()

        eosKit = nil
        account = nil
        eosAdapters = []
    }

    private func initEosKit(account: String, activePrivateKey: String) throws {
        let configuration = Configuration.shared

        let eosKit = try EosKit.instance(
                account: account,
                activePrivateKey: activePrivateKey,
                networkType: configuration.networkType,
                minLogLevel: configuration.minLogLevel
        )

        eosKit.refresh()

        eosAdapters = [
            EosAdapter(eosKit: eosKit, token: "eosio.token", symbol: "EOS"),
            EosAdapter(eosKit: eosKit, token: "eosio.token", symbol: "ERM"),
            EosAdapter(eosKit: eosKit, token: "betdicetoken", symbol: "DICE"),
        ]

        self.eosKit = eosKit
        self.account = account
    }

    private var savedAuth: (account: String, activePrivateKey: String)? {
        if let authString = UserDefaults.standard.value(forKey: keyAuth) as? String {
            let parts = authString.split(separator: " ")
            return (account: String(parts[0]), activePrivateKey: String(parts[1]))
        }
        return nil
    }

    private func save(account: String, activePrivateKey: String) {
        UserDefaults.standard.set("\(account) \(activePrivateKey)", forKey: keyAuth)
        UserDefaults.standard.synchronize()
    }

    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: keyAuth)
        UserDefaults.standard.synchronize()
    }

}
