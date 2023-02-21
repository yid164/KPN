//
//  VPNProfileManager.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI
import NetworkExtension
import Combine

final class VPNProfileManager: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    
    @Published var server: String = ""
    
    @Published var isEnabled: Bool = false
    @Published var isStarted: Bool = false
    
    @Published private(set) var status: String = "Unknow"
    
    @Published var isLoading = false
    @Published var isShowingError = false
    
    @Published private(set) var errorTitle = ""
    @Published private(set) var errorMessage = ""
    
    private let service: KPNService
    private let tunnel: NETunnelProviderManager
    
    private var observers = [AnyObject]()
    private var bag = [AnyCancellable]()
    
    init(service: KPNService = .shared, tunnel: NETunnelProviderManager) {
        self.service = service
        self.tunnel = tunnel
        
        self.refresh()
        
        let tunnelStatusObserver = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: tunnel.connection, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.refresh()
        }
        
        let tunnelConfigObserver = NotificationCenter.default.addObserver(forName: .NEVPNConfigurationChange, object: tunnel, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.refresh()
        }
        
        self.observers.append(tunnelStatusObserver)
        self.observers.append(tunnelConfigObserver)
        
        // enable or disable the tunnel anytime it recevies the value
        $isEnabled.sink { [weak self] enabled in
            guard let self = self else { return }
            self.setEnabled(enabled)
        }.store(in: &bag)
    }
    
    // refresh the vpn status
    private func refresh() {
        self.status = tunnel.connection.status.description
        self.username = tunnel.protocolConfiguration?.username ?? ""
        // TODO: Update password by KeyChian?
        self.password = ""
        
        self.server = tunnel.protocolConfiguration?.serverAddress ?? ""
        self.isEnabled = tunnel.isEnabled
        self.isStarted = tunnel.connection.status != .disconnected && tunnel.connection.status != .invalid
    }
    
    // set tunnel connection enabled or not
    private func setEnabled(_ isEnabled: Bool) {
        guard isEnabled != tunnel.isEnabled else { return }
        tunnel.isEnabled = isEnabled
        self.saveToPreference()
    }
    
    // save current settings to the preference
    private func saveToPreference() {
        isLoading = true
        tunnel.saveToPreferences { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            if let err = error {
                self.showError(title: "Finaled to update VPN configuration", message: err.localizedDescription)
                self.errorMessage = err.localizedDescription
                return
            }
        }
    }
    
    // error handling
    private func showError(title: String, message: String) {
        self.errorTitle = title
        self.errorMessage = message
        self.isShowingError = true
    }
    
    // example to ping the tunnel
    private func pingTunnel() {
        guard let session = tunnel.connection as? NETunnelProviderSession, let message = "PING".data(using: .utf8), tunnel.connection.status != .invalid else { return }
        
        do {
            try session.sendProviderMessage(message) { response in
                if let resp = response {
                    let responseString = NSString(data: resp, encoding: String.Encoding.utf8.rawValue)
                    NSLog("Received response from the provider: \(String(describing: responseString))")
                } else {
                    NSLog("Got a nil response from the provider")
                }
            }
        } catch {
            NSLog("Failed to send a message to the provider")
        }
    }
}

// Public Methods
extension VPNProfileManager {
    func startTunnel() {
        do {
            try tunnel.connection.startVPNTunnel(options: [:] as [String: NSObject])
        } catch {
            self.showError(title: "Failed to start VPN tunnel", message: error.localizedDescription)
        }
    }
    
    func stopTunnel() {
        tunnel.connection.stopVPNTunnel()
    }
    
    func saveProfile() {
        guard let proto = tunnel.protocolConfiguration as? NETunnelProviderProtocol else { return }
        proto.username = self.username
        
        proto.passwordReference = {
            let keychain = Keychain(group: "group.com.github.kean.vpn-client")
            let _ = keychain.set(password: self.password, for: username)
            return keychain.passwordReference(for: username)
        }()
        
        proto.serverAddress = server
        
        tunnel.protocolConfiguration = proto
        
        self.saveToPreference()
        
    }
    
    func removeProfile() {
        isLoading = true
        service.removeProfile { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success:
                break
            case let .failure(error):
                self.showError(title: "Failed to remove the profile", message: error.localizedDescription)
            }
        }
    }
}
