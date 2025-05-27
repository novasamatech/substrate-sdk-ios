// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SubstrateSdk",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "SubstrateSdk",
            targets: ["SubstrateSdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/novasamatech/Crypto-iOS", exact: "0.1.1"),
        .package(url: "https://github.com/novasamatech/Operation-iOS", exact: "2.1.1"),
        .package(url: "https://github.com/ashleymills/Reachability.swift", exact: "5.2.4"),
        .package(url: "https://github.com/novasamatech/Starscream.git", exact: "4.0.13"),
        .package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap", exact: "1.1.0"),
        .package(url: "https://github.com/attaswift/BigInt", exact: "5.5.1"),
        .package(url: "https://github.com/daisuke-t-jp/xxHash-Swift", exact: "1.1.1"),
        .package(url: "https://github.com/novasamatech/keccak.c", branch: "master"),
    ],
    targets: [
        .target(
            name: "SubstrateSdk",
            dependencies: [
                .product(name: "NovaCrypto", package: "crypto-ios"),
                .product(name: "Operation-iOS", package: "operation-ios"),
                .product(name: "Reachability", package: "Reachability.swift"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "xxHash-Swift", package: "xxHash-Swift"),
                .product(name: "keccak", package: "keccak.c")
            ],
            path: "SubstrateSdk/Classes"
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                "SubstrateSdk"
            ],
            path: "Tests/Helpers",
            resources: Resources.runtimes()
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: [
                "SubstrateSdk",
                .product(name: "keccak", package: "keccak.c"),
                "TestHelpers",
                .product(name: "NovaCrypto", package: "Crypto-iOS")
            ],
            path: "Tests/Common"
        ),
        .testTarget(
            name: "CryptoTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
                .product(name: "NovaCrypto", package: "Crypto-iOS")
            ],
            path: "Tests/Crypto",
            resources: Resources.hdkd()
        ),
        .testTarget(
            name: "ExtrinsicBuilderTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
                .product(name: "NovaCrypto", package: "Crypto-iOS"),
            ],
            path: "Tests/ExtrinsicBuilder"
        ),
        .testTarget(
            name: "IconTests",
            dependencies: [
                "SubstrateSdk",
            ],
            path: "Tests/Icon"
        ),
        .testTarget(
            name: "JsonTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
            ],
            path: "Tests/JSON"
        ),
        .testTarget(
            name: "KeystoreTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
            ],
            path: "Tests/Keystore",
            resources: Resources.keystore()
        ),
        .testTarget(
            name: "NetworkTests",
            dependencies: [
                "SubstrateSdk",
            ],
            path: "Tests/Network"
        ),
        .testTarget(
            name: "QRTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
            ],
            path: "Tests/QR"
        ),
        .testTarget(
            name: "RuntimeTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
            ],
            path: "Tests/Runtime",
            resources: Resources.runtimes()
        ),
        .testTarget(
            name: "ScaleTests",
            dependencies: [
                "SubstrateSdk",
                "TestHelpers",
            ],
            path: "Tests/Scale"
        )
    ],
    swiftLanguageModes: [.v5]
)


enum Resources {
    case runtimes
    case keystore
    case hdkd
    
    func callAsFunction() -> [Resource] {
        let paths: [String]
        switch self {
        case .runtimes:
            paths = [
                "../Resources/Runtime/common-v14.json",
                "../Resources/Runtime/default.json",
                "../Resources/Runtime/kusama-metadata",
                "../Resources/Runtime/kusama-v14-metadata",
                "../Resources/Runtime/kusama-v14-metadata-latest",
                "../Resources/Runtime/kusama.json",
                "../Resources/Runtime/polkadot-metadata",
                "../Resources/Runtime/polkadot-v14-metadata",
                "../Resources/Runtime/polkadot-v15",
                "../Resources/Runtime/polkadot.json",
                "../Resources/Runtime/statemine-metadata",
                "../Resources/Runtime/statemine-v14-metadata",
                "../Resources/Runtime/statemine.json",
                "../Resources/Runtime/test-metadata",
                "../Resources/Runtime/westend-metadata",
                "../Resources/Runtime/westend-v14-metadata",
                "../Resources/Runtime/westend-v15-metadata",
                "../Resources/Runtime/westend.json"
            ]
        case .keystore:
            paths = [
                "../Resources/Keystore/keystore-ecdsa.json",
                "../Resources/Keystore/keystore-ed25519.json",
                "../Resources/Keystore/keystore-ethereum-int-version.json",
                "../Resources/Keystore/keystore-ethereum.json",
                "../Resources/Keystore/keystore-sr25519.json"
            ]
        case .hdkd:
            paths = [
                "../Resources/BIP32HDKD.json",
                "../Resources/BIP32HDKDEtalon.json",
                "../Resources/ecdsaHDKD.json",
                "../Resources/ed25519HDKD.json",
                "../Resources/sr25519HDKD.json"
            ]
        }
        
        return paths.map { .process($0) }
    }
}
