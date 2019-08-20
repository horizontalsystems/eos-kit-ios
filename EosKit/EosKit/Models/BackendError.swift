public enum BackendError: Error {
    case selfTransfer
    case accountNotExist
    case overdrawn
    case precisionMismatch
    case insufficientRam
    case wrongContract
    case unknown(message: String)
}
