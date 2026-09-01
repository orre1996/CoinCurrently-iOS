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

protocol ViewWillDisappearDelegate: AnyObject {
    func viewWillDisappear()
}

protocol ViewDidDisappearDelegate: AnyObject {
    func viewDidDisappear()
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

struct UIKitWillDisappear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIWillDisappearViewController {
        let viewController = UIWillDisappearViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ controller: UIWillDisappearViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: self.action)
    }
    
    class Coordinator: ViewWillDisappearDelegate {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        func viewWillDisappear() {
            self.action()
        }
    }
}

struct UIKitDidDisappear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIDidDisappearViewController {
        let viewController = UIDidDisappearViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ controller: UIDidDisappearViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: self.action)
    }
    
    class Coordinator: ViewDidDisappearDelegate {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        func viewDidDisappear() {
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

class UIWillDisappearViewController: UIViewController {
    weak var delegate: ViewWillDisappearDelegate?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewWillDisappear()
    }
}

class UIDidDisappearViewController: UIViewController {
    weak var delegate: ViewDidDisappearDelegate?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.viewDidDisappear()
    }
}

extension View {
    func onUIKitWillAppear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitWillAppear(action: perform))
    }

    func onUIKitDidAppear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitDidAppear(action: perform))
    }

    func onUIKitWillDisappear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitWillDisappear(action: perform))
    }

    func onUIKitDidDisappear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitDidDisappear(action: perform))
    }
}
