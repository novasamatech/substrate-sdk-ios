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
    private enum Constants {
        static let address = "Fewyw2YrQgjtnuRsYQXfeHoTMoazKJKkfKkT8hc1WLjPsUP"
        static let radius: CGFloat = 128.0
    }

    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20.0
        stackView.contentMode = .center
        stackView.distribution = .equalCentering
        stackView.alignment = .center

        return stackView
    }()

    private var iconView = PolkadotIconView()
    private var novaIconView = PolkadotIconView()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .lightGray

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(novaIconView)

        iconView.backgroundColor = .clear
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.fillColor = UIColor.white.withAlphaComponent(0.5)

        iconView.widthAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true

        novaIconView.backgroundColor = .clear
        novaIconView.translatesAutoresizingMaskIntoConstraints = false
        novaIconView.fillColor = UIColor.white.withAlphaComponent(0.5)

        novaIconView.widthAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true
        novaIconView.heightAnchor.constraint(equalToConstant: 2.0 * Constants.radius).isActive = true

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

            let novaIcon = try NovaIconGenerator().generateFromAddress(Constants.address)
            novaIconView.bind(icon: novaIcon)
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}
