//
//  KPNService.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import Foundation
import NetworkExtension
import UIKit

final class KPNService: ObservableObject {
    @Published private var isStarted = false
    
    @Published private var tunnel: NETunnelProviderManager? = nil
    
    static var shared = KPNService()
    
    private var observer: AnyObject?
    
    private func makeManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        manager.localizedDescription = "KPN"

        let proto = NETunnelProviderProtocol()

        // WARNING: This must match the bundle identifier of the app extension
        // containing packet tunnel provider.
        proto.providerBundleIdentifier = "com.ken.vpn.kpn.app.PacketTunnel"

        // WARNING: This must send the actual VPN server address, for the demo
        // purposes, I'm passing the address of the server in my local network.
        // The address is going to be different in your network.
        proto.serverAddress = "192.168.0.13:9999"

        proto.username = "kean"
        proto.passwordReference = {
            let keychain = Keychain(group: "group.com.github.kean.vpn-client")
            let _ = keychain.set(password: "123456", for: "kean")
            return keychain.passwordReference(for: "kean")
        }()

        manager.protocolConfiguration = proto

        // Uncomment this to configure on-demand rules to make sure the tunnel
        // starts automatically when needed.
//        let onDemandRule = NEOnDemandRuleConnect()
//        onDemandRule.interfaceTypeMatch = .any
//        manager.isOnDemandEnabled = true
//        manager.onDemandRules = [onDemandRule]
        // Enable the manager bu default.
        manager.isEnabled = true

        return manager
    }
    
    private init() {
        self.observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let self = self else { return }
            self.refresh{ _ in }
        })
    }
}

// public methods
extension KPNService {
    func refresh(_ completion: @escaping (Result<Void, Error>) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            self.tunnel = managers?.first
            if let error = error {
                completion(.failure(error))
            } else {
                self.isStarted = true
                completion(.success(()))
            }
        }
    }
    
    func installProfile(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let tunnelManager = self.makeManager()
        tunnelManager.saveToPreferences { [weak self] error in
            if let error = error {
                return completion(.failure(error))
            }
            tunnelManager.loadFromPreferences { [weak self] error in
                guard let self = self else { return }
                self.tunnel = tunnelManager
                completion(.success(()))
            }
        }
        
    }
    
    func removeProfile(_ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let tunnel = self.tunnel else { return }
        tunnel.removeFromPreferences{ [weak self] error in
            guard let self = self else { return }
            if let error = error {
                return completion(.failure(error))
            }
            self.tunnel = nil
            completion(.success(()))
        }
    }
}

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .reasserting: return "Reasserting"
        @unknown default: return "Unknown"
        }
    }
}
