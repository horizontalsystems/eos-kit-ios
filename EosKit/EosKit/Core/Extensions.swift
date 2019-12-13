import EosioSwift
import PromiseKit

public extension Data {

    init?(hex: String) {
        let hex = hex.stripHexPrefix()

        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }

        self = data
    }

    func toHexString() -> String {
        return "0x" + self.toRawHexString()
    }

    func toRawHexString() -> String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }

    var bytes: Array<UInt8> {
        return Array(self)
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }

}

extension String {

    func stripHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        }

        return self
    }

    func addHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return self
        }

        return prefix.appending(self)
    }

}

extension EosioError {

    var backendError: BackendError {
        guard let httpError = originalError as? PromiseKit.PMKHTTPError,
              let errorDictionary = (httpError.jsonDictionary as? [String: Any])?["error"] as? [String: Any],
              let detailsArray = errorDictionary["details"] as? [[String: Any]] else {
            return .unknown(message: "Can't parse details")
        }
        var messages = ""
        for detail in detailsArray {
            if let message = detail["message"] as? String {
                messages += "\(message) - "
            }
        }
        if messages.contains(words: "cannot transfer to self") {
            return .selfTransfer
        } else if messages.contains(words: "greater than the maximum billable CPU") {
            return .insufficientCpu
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

        return .unknown(message: messages)
    }

}
