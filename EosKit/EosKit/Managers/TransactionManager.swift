import RxSwift
import EosioSwift
import HsToolKit

class TransactionManager {
    private let storage: IStorage
    private let transactionFactory: EosioTransactionFactory
    private let logger: Logger

    init(storage: IStorage, transactionFactory: EosioTransactionFactory, logger: Logger) {
        self.storage = storage
        self.transactionFactory = transactionFactory
        self.logger = logger
    }

    func sendSingle(account: String, token: String, to: String, quantityString: String, memo: String) -> Single<String?> {
        return Single.create { [unowned self] observer in
            self.logger.verbose("Sending transaction: \(token); \(to); \(quantityString); \(memo)")

            do {
                let transaction = try self.transaction(account: account, token: token, to: to, quantityString: quantityString, memo: memo)

                transaction.signAndBroadcast { result in
//                    let transactionJson = try? transaction.toJson(prettyPrinted: true)
//                    print("Outgoing Transaction: \(transactionJson ?? "nil")")

                    switch result {
                    case .success:
                        self.logger.debug("TransactionManager send success: \(transaction.transactionId ?? "no transaction id")")

                        observer(.success(transaction.transactionId))
                    case .failure (let error):
                        self.logger.error("TransactionManager send failure: \(error) \(error.reason)")

                        let backendError = error.backendError
                        if case .unknown(let message) = backendError {
                            self.logger.error("TransactionManager failure parse error: \(message)")
                        }
                        observer(.error(backendError))
                    }
                }
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    private func transaction(account: String, token: String, to: String, quantityString: String, memo: String) throws -> EosioTransaction {
        let transaction = transactionFactory.newTransaction()

        let action = try EosioTransaction.Action(
                account: EosioName(token),
                name: EosioName("transfer"),
                authorization: [
                    EosioTransaction.Action.Authorization(
                            actor: EosioName(account),
                            permission: EosioName("active")
                    )
                ],
                data: TransferActionData(
                        from: EosioName(account),
                        to: EosioName(to),
                        quantity: quantityString,
                        memo: memo
                )
        )

        transaction.add(action: action)

        return transaction
    }

}

extension TransactionManager {

    struct TransferActionData: Codable {
        let from: EosioName
        let to: EosioName
        let quantity: String
        let memo: String
    }

}
