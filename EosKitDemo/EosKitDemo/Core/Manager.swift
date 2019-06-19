import RxSwift
import EosKit
import HSHDWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var eosKit: EosKit!

    var eosAdapter: EosAdapter!

    init() {
        if let words = savedWords {
            initEosKit(words: words)
        }
    }

    func login(words: [String]) {
        try! EosKit.clear()

        save(words: words)
        initEosKit(words: words)
    }

    func logout() {
        clearWords()

        eosKit = nil
        eosAdapter = nil
    }

    private func initEosKit(words: [String]) {
        let configuration = Configuration.shared

        let eosKit = try! EosKit.instance(
                words: words,
                networkType: configuration.networkType,
                minLogLevel: configuration.minLogLevel
        )

        eosAdapter = EosAdapter(eosKit: eosKit)

        self.eosKit = eosKit

        eosKit.start()
    }

    private var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}
