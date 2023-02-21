//
//  Keychain.swift
//  KPN
//
//  Created by Ken on 2023-02-20.
//

import Foundation

public final class Keychain {
    private let accessGroup: String
    
    public init(group: String) {
        self.accessGroup = group
    }
    
    public func set(password: String, for username: String, label: String? = nil) -> OSStatus {
        let _ = removePassword(for: username)
        var query = [String: Any]()
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecClass as String] = kSecClassGenericPassword
        if let label = label {
            query[kSecAttrLabel as String] = label
        }
        query[kSecAttrAccount as String] = username
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        query[kSecValueData as String] = password.data(using: .utf8)

        return SecItemAdd(query as CFDictionary, nil)
    }
    
    public func removePassword(for username: String) -> Bool {
        var query = [String: Any]()
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccount as String] = username

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    public func password(for username: String) throws -> String? {
        var query = [String: Any]()
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccount as String] = username
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func passwordReference(for username: String) -> Data? {
        var query = [String: Any]()
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccount as String] = username
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnPersistentRef as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }
    
    public func password(for username: String, reference: Data) -> String? {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccount as String] = username
        query[kSecMatchItemList as String] = [reference]
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
