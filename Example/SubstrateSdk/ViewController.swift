//
//  ViewController.swift
//  SubstrateSdk
//
//  Created by ERussel on 07/22/2020.
//  Copyright (c) 2020 ERussel. All rights reserved.
//

import UIKit
import SubstrateSdk

class ViewController: UIViewController {
    private struct Constants {
        static let address = "Fewyw2YrQgjtnuRsYQXfeHoTMoazKJKkfKkT8hc1WLjPsUP"
        static let radius: CGFloat = 128.0
    }

    private var iconView: PolkadotIconView = PolkadotIconView()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .lightGray

        iconView.backgroundColor = .clear
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.fillColor = UIColor.white.withAlphaComponent(0.5)

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
            let icon = try PolkadotIconGenerator().generateFromAddress(Constants.address)
            iconView.bind(icon: icon)
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

