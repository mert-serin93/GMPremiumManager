//
//  File.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-15.
//

import UIKit
import SwiftUI

struct GMSwiftUIView<T: UIViewController>: UIViewControllerRepresentable {
    let viewController: T

    func makeUIViewController(context: Context) -> T {
        return viewController
    }

    func updateUIViewController(_ uiViewController: T, context: Context) {}
}

extension UIViewController {
    func toSwiftUI() -> some View {
        GMSwiftUIView(viewController: self)
    }
}
