//
//  PrimaryButton.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> ()
    @Binding var isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Spinner(isAnimating: $isLoading, color: .white, style: .medium)
                Text(title)
                    .opacity(isLoading ? 0 : 1)
            }
        }
        .disabled(isLoading)
        .padding()
//        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(8)
    }
    
    init(title: String, isLoading: Binding<Bool> = .constant(false), action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self._isLoading = isLoading
    }
}
