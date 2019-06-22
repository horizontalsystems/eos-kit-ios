import RxSwift
import EosioSwift

class TransactionManager {
    private let account: String
    private let storage: IStorage
    private let transactionFactory: EosioTransactionFactory

    init(account: String, storage: IStorage, transactionFactory: EosioTransactionFactory) {
        self.account = account
        self.storage = storage
        self.transactionFactory = transactionFactory
    }

    func sendSingle(token: String, to: String, quantity: Quantity, memo: String) -> Single<String?> {
        return Single.create { [unowned self] observer in
            do {
                let transaction = try self.transaction(token: token, to: to, quantity: quantity, memo: memo)

                transaction.signAndBroadcast { result in
                    let transactionJson = try? transaction.toJson(prettyPrinted: true)
                    print("Outgoing Transaction: \(transactionJson ?? "nil")")

                    switch result {
                    case .success:
                        observer(.success(transaction.transactionId))
                    case .failure (let error):
                        print("TransactionManager send failure: \(error) \(error.reason)")

                        observer(.error(error))
                    }
                }
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    private func transaction(token: String, to: String, quantity: Quantity, memo: String) throws -> EosioTransaction {
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
                        quantity: quantity.description,
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
