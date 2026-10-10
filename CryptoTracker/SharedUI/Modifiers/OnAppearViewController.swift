//
//  OnAppearViewController.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-29.
//

import Foundation
import SwiftUI

protocol ViewWillAppearDelegate: AnyObject {
    func viewWillAppear()
}

protocol ViewDidAppearDelegate: AnyObject {
    func viewDidAppear()
}

struct UIKitWillAppear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIWillAppearViewController {
        let viewController = UIWillAppearViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ controller: UIWillAppearViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: self.action)
    }
    
    class Coordinator: ViewWillAppearDelegate {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        func viewWillAppear() {
            self.action()
        }
    }
}

struct UIKitDidAppear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIDidAppearViewController {
        let viewController = UIDidAppearViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ controller: UIDidAppearViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: self.action)
    }
    
    class Coordinator: ViewDidAppearDelegate {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        func viewDidAppear() {
            self.action()
        }
    }
}

class UIWillAppearViewController: UIViewController {
    weak var delegate: ViewWillAppearDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewWillAppear()
    }
}

class UIDidAppearViewController: UIViewController {
    weak var delegate: ViewDidAppearDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.viewDidAppear()
    }
}

extension View {
    func onUIKitWillAppear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitWillAppear(action: perform))
    }

    func onUIKitDidAppear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitDidAppear(action: perform))
    }
}
