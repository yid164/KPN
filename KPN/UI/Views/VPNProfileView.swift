//
//  VPNProfileView.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI

struct VPNProfileView: View {
    @ObservedObject var manager: VPNProfileManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("VPN Profiles")) {
                    TextInputView(title: "Username", text: $manager.username)
                    TextInputView(title: "Password", text: $manager.password)
                    TextInputView(title: "Server", text: $manager.server)
                    Button(action: manager.saveProfile) {
                        Text("Save")
                            .foregroundColor(Color.blue)
                    }
                }
                
                Section(header: Text("Status")) {
                    Toggle(isOn: $manager.isEnabled) {
                        Text("VPN")
                    }
                    
                    if manager.isEnabled {
                        Text("Status: ") + Text(manager.status).bold()
                        if manager.isStarted {
                            Button(action: manager.stopTunnel) {
                                Text("Stop")
                            }.foregroundColor(Color.orange)
                        } else {
                            Button(action: manager.startTunnel) {
                                Text("Start")
                            }.foregroundColor(Color.blue)
                        }
                    }
                }
                
                Section {
                    RemoveProfileButton(manager: manager)
                }
            }
            .disabled(manager.isLoading)
            .alert(isPresented: $manager.isShowingError) {
                Alert(title: Text(self.manager.errorTitle), message: Text(self.manager.errorMessage), dismissButton: .cancel())
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Spinner(isAnimating: $manager.isLoading, color: .label, style: .medium)
                }
            }
            .navigationTitle("VPN")
        }
    }
}

private struct TextInputView: View {
    let title: String
    let text: Binding<String>
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.callout)
            TextField(title, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.gray)
        }
    }
}

private struct RemoveProfileButton: View {
    let manager: VPNProfileManager
    
    @State private var isConfirmationPresented: Bool = false
    
    var body: some View {
        Button(action: { self.isConfirmationPresented = true }) {
            Text("Remove Profile")
        }
        .foregroundColor(.red)
        .alert(isPresented: $isConfirmationPresented) {
            Alert(
                title: Text("Are you sure you want to remove the profile?"),
                primaryButton: .destructive(Text("Remove profile"), action: {
                    self.isConfirmationPresented = false
                    self.manager.removeProfile()
                }),
                secondaryButton: .cancel()
            )
        }
    }
}

struct VPNProfileView_Previews: PreviewProvider {
    static var previews: some View {
        VPNProfileView(manager: .init(tunnel: .init()))
    }
}
