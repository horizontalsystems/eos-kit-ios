import RxSwift
import EosioSwift

class BalanceManager {
    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider

    init(storage: IStorage, rpcProvider: EosioRpcProvider) {
        self.storage = storage
        self.rpcProvider = rpcProvider
    }

    func balance(symbol: String) -> Decimal? {
        return storage.balance(symbol: symbol)?.value
    }

    func sync(account: String) {
        let balanceRequest = EosioRpcCurrencyBalanceRequest(code: "eosio.token", account: account, symbol: nil)

        rpcProvider.getCurrencyBalance(requestParameters: balanceRequest) { [weak self] result in
            switch result {
            case .success(let balanceResponse):
                self?.handle(balanceResponse: balanceResponse)
            case .failure(let error):
                print("BALANCE REFRESH FAILURE")
                print(error)
                print(error.reason)
            }
        }
    }

    private func handle(balanceResponse: EosioRpcCurrencyBalanceResponse) {
        print("Balances: \(balanceResponse.currencyBalance) --- \(Thread.current)")

        let balances = balanceResponse.currencyBalance.compactMap { parse(balanceString: $0) }

        storage.save(balances: balances)
    }

    private func parse(balanceString: String) -> Balance? {
        let parts = balanceString.split(separator: " ")

        guard parts.count == 2 else {
            return nil
        }

        let valueString = String(parts[0])
        let symbol = String(parts[1])

        guard let value = Decimal(string: valueString) else {
            return nil
        }

        return Balance(symbol: symbol, value: value)
    }

}
