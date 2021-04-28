import Foundation
import Security

enum SecurePersistenceService: String {
    case login
    case client
}

enum SecurePersistenceAccount: String {
    case accessToken
    case refreshToken
    case clientID
}

protocol SecurePersistence {
    var loginToken: String? { get }
    func save(loginToken: Token) -> Bool
    func reset() -> Bool
    func update(service: SecurePersistenceService, account: SecurePersistenceAccount, value: String) -> Bool
    func remove(service: SecurePersistenceService, account: SecurePersistenceAccount) -> Bool
    func save(service: SecurePersistenceService, account: SecurePersistenceAccount, value: String) -> Bool
    func load(service: SecurePersistenceService, account: SecurePersistenceAccount) -> String?
}

extension SecurePersistence {
    var loginToken: String? {
        load(service: .login, account: .accessToken)
    }

    func save(loginToken: Token) -> Bool {
        if self.loginToken != nil {
            return update(service: .login, account: .accessToken, value: loginToken.token)
        } else {
            return save(service: .login, account: .accessToken, value: loginToken.token)
        }
    }

    func reset() -> Bool {
        remove(service: .login, account: .accessToken)
    }
}

class KeychainService: SecurePersistence {

    static var shared = KeychainService()

    func update(service: SecurePersistenceService, account: SecurePersistenceAccount, value: String) -> Bool {
        if let data: Data = value.data(using: .utf8, allowLossyConversion: false) {
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: service.rawValue,
                kSecAttrAccount as String: account.rawValue] as [String: Any]
            let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
            if status != errSecSuccess {
                if let err = SecCopyErrorMessageString(status, nil) {
                    Logger.shared.error("Keychain Read failed: \(err)", category: .keychain)
                }
                return false
            } else {
                return true
            }
        }
        return false
    }

    func remove(service: SecurePersistenceService, account: SecurePersistenceAccount) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: kCFBooleanTrue!] as [String: Any]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            if let err = SecCopyErrorMessageString(status, nil) {
                Logger.shared.error("Keychain Remove failed: \(err)", category: .keychain)
            }
            return false
        } else {
            return true
        }
    }

    func save(service: SecurePersistenceService, account: SecurePersistenceAccount, value: String) -> Bool  {
        if let data = value.data(using: .utf8, allowLossyConversion: false) {
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: service.rawValue,
                kSecAttrAccount as String: account.rawValue,
                kSecValueData as String: data] as [String: Any]
            // Add the new keychain item
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                if let err = SecCopyErrorMessageString(status, nil) {
                    Logger.shared.error("Keychain Write failed: \(err)", category: .keychain)
                }
                return false
            } else {
                return true
            }
        }
        return false
    }

    func load(service: SecurePersistenceService, account: SecurePersistenceAccount) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne] as [String: Any]
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        var contentsOfKeychain: String?

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: String.Encoding.utf8)
            }
        } else {
            Logger.shared.warning("Nothing was retrieved from the keychain. Status code \(status)", category: .keychain)
        }

        return contentsOfKeychain
    }
}
