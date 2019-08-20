import EosioSwift
import PromiseKit

class ErrorUtils {

    static func getBackendError(from error: EosioError, logger: Logger) -> BackendError {
        guard let details = (((error.originalError as? PromiseKit.PMKHTTPError)?.jsonDictionary as? [String: Any])?["error"] as? [String: Any])?["details"] as? [[String: Any]] else {
            return .unknown
        }
        var messages = ""
        for detail in details {
             if let message = detail["message"] as? String {
                 messages += "\(message) - "
             }
        }
        if messages.contains(words: "cannot transfer to self") {
            return .selfTransfer
        } else if messages.contains(words: "account does not exist") {
            return .accountNotExist
        } else if messages.contains(words: "overdrawn") || messages.contains(words: "no balance object found") {
            return .overdrawn
        } else if messages.contains(words: "symbol precision mismatch") {
            return .precisionMismatch
        } else if messages.contains(words: "insufficient ram") {
            return .insufficientRam
        } else if messages.contains(words: "unable to find key") {
            return .wrongContract
        }
        logger.error("Can't parse error: \(messages)")

        return .unknown
    }

}
