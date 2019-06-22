import RxSwift
import EosioSwift

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let account: String
    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider

    init(account: String, storage: IStorage, rpcProvider: EosioRpcProvider) {
        self.account = account
        self.storage = storage
        self.rpcProvider = rpcProvider
    }

    func balance(token: String, symbol: String) -> Balance? {
        return storage.balance(token: token, symbol: symbol)
    }

    func sync(token: String) {
        let request = EosioRpcCurrencyBalanceRequest(code: token, account: account, symbol: nil)

        rpcProvider.getCurrencyBalance(requestParameters: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handle(response: response, token: token)
            case .failure(let error):
                print("BalanceManager sync failure: \(error.reason)")

                self?.delegate?.didFailToSync(token: token)
            }
        }
    }

    private func handle(response: EosioRpcCurrencyBalanceResponse, token: String) {
        print("Balances: \(response.currencyBalance)")

        let balances = response.currencyBalance.compactMap { string -> Balance? in
            guard let quantity = Quantity(string: string) else {
                return nil
            }

            return Balance(token: token, quantity: quantity)
        }

        storage.save(balances: balances)

        for balance in balances {
            delegate?.didSync(balance: balance)
        }
    }

}
