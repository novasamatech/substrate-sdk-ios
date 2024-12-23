import UIKit
import IrohaCrypto

private struct Scheme {
    let colors: [UInt]
    let freq: UInt
}

extension Scheme {
    static let target = Scheme(
        colors: [0, 28, 0, 0, 28, 0, 0, 28, 0, 0, 28, 0, 0, 28, 0, 0, 28, 0, 1],
        freq: 1
    )

    static let cube = Scheme(
        colors: [0, 1, 3, 2, 4, 3, 0, 1, 3, 2, 4, 3, 0, 1, 3, 2, 4, 3, 5],
        freq: 20
    )

    static let quazar = Scheme(
        colors: [1, 2, 3, 1, 2, 4, 5, 5, 4, 1, 2, 3, 1, 2, 4, 5, 5, 4, 0],
        freq: 16
    )

    static let flower = Scheme(
        colors: [0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 3],
        freq: 32
    )

    static let cyclic = Scheme(
        colors: [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 6],
        freq: 32
    )

    static let vmirror = Scheme(
        colors: [0, 1, 2, 3, 4, 5, 3, 4, 2, 0, 1, 6, 7, 8, 9, 7, 8, 6, 10],
        freq: 128
    )

    static let hmirror = Scheme(
        colors: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 8, 6, 7, 5, 3, 4, 2, 11],
        freq: 128
    )

    static let all: [Scheme] = [
        .target,
        .cube,
        .quazar,
        .flower,
        .cyclic,
        .vmirror,
        .hmirror
    ]
}

enum PolkadotIconGeneratorError: Error {
    case unrecognizedAddress
    case noSchemeFound
}

public class PolkadotIconGenerator: IconGenerating {
    static let diameter: CGFloat = 64.0
    static let circleRadius: CGFloat = 5.0

    struct Rotation {
        let r: CGFloat
        let ro2: CGFloat
        let r3o4: CGFloat
        let ro4: CGFloat
        let rroot3o2: CGFloat
        let rroot3o4: CGFloat
    }

    public init() {}

    public func generateFromAccountId(_ accountId: Data) throws -> DrawableIcon {
        let internalId = try deriveInternalIdFromAccountId(accountId)

        let colors = try getColorsForData(internalId)
        let centers = generateCircleCenters()

        let circles = (0 ..< centers.count).map { index in
            PolkadotIcon.Circle(
                origin: centers[index],
                color: colors[index],
                radius: Self.circleRadius
            )
        }

        return PolkadotIcon(
            radius: Self.diameter / 2.0,
            circles: circles
        )
    }

    private func deriveInternalIdFromAccountId(_ accountId: Data) throws -> Data {
        let zero: [UInt8] = try (Data(repeating: 0, count: 32) as NSData).blake2b(64).map { $0 }

        var bytes: [UInt8] = try (accountId as NSData).blake2b(64).map { $0 }

        for index in 0 ..< zero.count {
            let value = UInt(bytes[index])
            bytes[index] = UInt8((value + 256 - UInt(zero[index])) % 256)
        }

        return Data(bytes)
    }

    private func getColorsForData(_ data: Data) throws -> [UIColor] {
        let total: UInt = Scheme.all.reduce(UInt(0)) { result, scheme in
            result + scheme.freq
        }

        let accountId: [UInt8] = data.map { $0 }

        let accumFreq = (UInt(accountId[30]) + UInt(accountId[31]) * 256) % total
        let rot = (accountId[28] % 6) * 3
        let sat = floor(CGFloat(accountId[29]) * 70.0 / 256.0 + 26.0).truncatingRemainder(dividingBy: 80) + 30.0
        let scheme = try findScheme(for: accumFreq)

        var palette: [UIColor] = []

        for (index, byte) in accountId.enumerated() {
            let colorParam = (UInt(byte) + UInt(index) % 28 * 58) % 256

            if colorParam == 0 {
                let color = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.27, alpha: 1.0)
                palette.append(color)
            } else if colorParam == 255 {
                let color = UIColor(white: 1.0, alpha: 0.0)
                palette.append(color)
            } else {
                let hue: CGFloat = floor(CGFloat(colorParam % 64) * 360.0 / 64.0)
                let lightness: CGFloat = [53.0, 15.0, 35.0, 75.0][Int(floor(CGFloat(colorParam) / 64.0))]

                let color = UIColor.colorWithHSL(
                    hue: hue,
                    saturation: CGFloat(sat) * 0.01,
                    lightness: CGFloat(lightness) * 0.01
                )

                palette.append(color)
            }
        }

        return (0 ..< scheme.colors.count).map { index in
            palette[Int(scheme.colors[index < 18 ? (index + Int(rot)) % 18 : 18])]
        }
    }

    private func findScheme(for accumFreq: UInt) throws -> Scheme {
        var cum: UInt = 0

        for scheme in Scheme.all {
            cum += scheme.freq

            if accumFreq < cum {
                return scheme
            }
        }

        throw PolkadotIconGeneratorError.noSchemeFound
    }

    private func generateCircleCenters() -> [CGPoint] {
        let rotation = createRotation()

        return [
            CGPoint(x: 0.0, y: -rotation.r),
            CGPoint(x: 0.0, y: -rotation.ro2),
            CGPoint(x: -rotation.rroot3o4, y: -rotation.r3o4),
            CGPoint(x: -rotation.rroot3o2, y: -rotation.ro2),
            CGPoint(x: -rotation.rroot3o4, y: -rotation.ro4),
            CGPoint(x: -rotation.rroot3o2, y: 0.0),
            CGPoint(x: -rotation.rroot3o2, y: rotation.ro2),
            CGPoint(x: -rotation.rroot3o4, y: rotation.ro4),
            CGPoint(x: -rotation.rroot3o4, y: rotation.r3o4),
            CGPoint(x: 0.0, y: rotation.r),
            CGPoint(x: 0.0, y: rotation.ro2),
            CGPoint(x: rotation.rroot3o4, y: rotation.r3o4),
            CGPoint(x: rotation.rroot3o2, y: rotation.ro2),
            CGPoint(x: rotation.rroot3o4, y: rotation.ro4),
            CGPoint(x: rotation.rroot3o2, y: 0.0),
            CGPoint(x: rotation.rroot3o2, y: -rotation.ro2),
            CGPoint(x: rotation.rroot3o4, y: -rotation.ro4),
            CGPoint(x: rotation.rroot3o4, y: -rotation.r3o4),
            CGPoint(x: 0.0, y: 0.0)
        ]
    }

    private func createRotation() -> Rotation {
        let r: CGFloat = Self.diameter / 8.0 * 3.0
        let rroot3o2: CGFloat = r * sqrt(3.0) / 2.0
        let ro2 = r / 2.0
        let rroot3o4 = r * sqrt(3.0) / 4.0
        let ro4 = r / 4.0
        let r3o4 = r * 3.0 / 4.0

        return Rotation(
            r: r,
            ro2: ro2,
            r3o4: r3o4,
            ro4: ro4,
            rroot3o2: rroot3o2,
            rroot3o4: rroot3o4
        )
    }
}
