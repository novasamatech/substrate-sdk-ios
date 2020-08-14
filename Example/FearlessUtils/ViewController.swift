//
//  ViewController.swift
//  FearlessUtils
//
//  Created by ERussel on 07/22/2020.
//  Copyright (c) 2020 ERussel. All rights reserved.
//

import UIKit
import FearlessUtils

class ViewController: UIViewController {
    private struct Constants {
        static let address = "Dm1RyxRu8bKvVUsQpGx5e1miNbUkzSBsThhVCWdHyAjuTGR"
        static let radius: CGFloat = 32.0
    }

    private var iconView: KusamaIconView = KusamaIconView()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .lightGray

        iconView.backgroundColor = .clear
        iconView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iconView)

        iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadIcon()
    }

    private func loadIcon() {
        do {
            let icon = try KusamaIconGenerator().generateFromAddress(Constants.address)
            iconView.bind(icon: icon)
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

