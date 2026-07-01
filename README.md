# Substrate SDK iOS

Utility library that implements client-specific logic to interact with
Substrate-based networks (SCALE codec, runtime metadata, JSON-RPC, storage
queries/subscriptions, extrinsic building/signing, crypto/keystore, QR/identicons).

## Requirements

- iOS 14.0+
- Swift 5 language mode / Xcode with swift-tools 6.0

## Installation

SubstrateSdk is distributed via [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
only. CocoaPods is no longer supported.

Add the package in Xcode (File → Add Package Dependencies…) using
`https://github.com/nova-wallet/substrate-sdk-ios.git`, or add it to your
`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nova-wallet/substrate-sdk-ios.git", from: "4.5.1")
]
```

Then depend on the products you need:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SubstrateSdk", package: "substrate-sdk-ios"),
        // optional additional products:
        // "SubstrateStorageQuery", "SubstrateStorageSubscription",
        // "SubstrateStateCall", "SubstrateMetadataHash"
    ]
)
```

## Author

ERussel, emkil.russel@gmail.com

## License

SubstrateSdk iOS is available under the Apache Version 2.0 license. See the LICENSE file for more info.
© Novasama Technologies GmbH 2023
