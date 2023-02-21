//
//  Spinner.swift
//  KPN
//
//  Created by Ken on 2023-02-19.
//

import SwiftUI
import UIKit

struct Spinner: UIViewRepresentable {
    @Binding var isAnimating: Bool
    
    let color: UIColor
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: self.style)
        indicator.hidesWhenStopped = true
        indicator.color = color
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
