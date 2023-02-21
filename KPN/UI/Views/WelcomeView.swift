//
//  WelcomeView.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI

struct WelcomeView: View {
    let service: KPNService = .shared
    
    @State private var isLoading = false
    @State private var isShowingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                header
                Spacer(minLength: 0)
                installButton
                Spacer().frame(height: 16)
            }
            .padding()
        }
    }
    
    private var header: some View {
        VStack {
            Text("KPN")
                .font(.largeTitle)
                .fontWeight(.heavy)
            HStack(spacing: 20) {
                Image("icon-vpn")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text("KPN Solution")
                        .font(.headline)
                }
            }
        }
    }
    
    private var installButton: some View {
        PrimaryButton(title: "Install VPN Profile", isLoading: $isLoading, action: installProfile)
        .alert(isPresented: $isShowingError) {
            Alert(title: Text("Failed to install the profile"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
    
    private func installProfile() {
        self.isLoading = true
        self.service.installProfile { result in
            self.isLoading = false
            switch result {
            case .success:
                break
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                self.isShowingError = true
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
