import RxSwift
import EosioSwift
import HsToolKit

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let storage: IStorage
    private let rpcProvider: EosioRpcProvider
    private let logger: Logger

    init(storage: IStorage, rpcProvider: EosioRpcProvider, logger: Logger) {
        self.storage = storage
        self.rpcProvider = rpcProvider
        self.logger = logger
    }

    func balance(token: String, symbol: String) -> Balance? {
        return storage.balance(token: token, symbol: symbol)
    }

    func sync(account: String, token: String) {
        let request = EosioRpcCurrencyBalanceRequest(code: token, account: account, symbol: nil)

        rpcProvider.getCurrencyBalance(requestParameters: request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handle(response: response, token: token)
            case .failure(let error):
                self?.logger.error("BalanceManager sync failure for \(token): \(error.reason)")

                self?.delegate?.didFailToSync(token: token, error: error)
            }
        }
    }

    private func handle(response: EosioRpcCurrencyBalanceResponse, token: String) {
        logger.debug("Balances received for \(token): \(response.currencyBalance)")

        let balances = response.currencyBalance.compactMap { string -> Balance? in
            guard let quantity = Quantity(string: string) else {
                return nil
            }

            return Balance(token: token, quantity: quantity)
        }

        storage.save(balances: balances)

        delegate?.didSync(token: token, balances: balances)
    }

}
