import Foundation
import UIKit

public final class NovaIconGenerator {
    static let diameter: CGFloat = 64.0

    public init() {}

    private static var allColorPairs: [(UIColor, UIColor)] {
        return [
            (UIColor.colorWithHSL(hue: 260, saturation: 1.0, lightness: 0.95),
             UIColor.colorWithHSL(hue: 260, saturation: 0.61, lightness: 0.62)),

            (UIColor.colorWithHSL(hue: 216, saturation: 1.0, lightness: 0.92),
             UIColor.colorWithHSL(hue: 216, saturation: 0.98, lightness: 0.63)),

            (UIColor.colorWithHSL(hue: 134, saturation: 0.81, lightness: 0.91),
             UIColor.colorWithHSL(hue: 134, saturation: 0.7, lightness: 0.5)),

            (UIColor.colorWithHSL(hue: 317, saturation: 1.0, lightness: 0.93),
             UIColor.colorWithHSL(hue: 317, saturation: 0.97, lightness: 0.61)),

            (UIColor.colorWithHSL(hue: 33, saturation: 1.0, lightness: 0.91),
             UIColor.colorWithHSL(hue: 32, saturation: 0.77, lightness: 0.49)),

            (UIColor.colorWithHSL(hue: 58, saturation: 1.0, lightness: 0.9),
             UIColor.colorWithHSL(hue: 58, saturation: 0.94, lightness: 0.43)),

            (UIColor.colorWithHSL(hue: 184, saturation: 1.0, lightness: 0.94),
             UIColor.colorWithHSL(hue: 184, saturation: 0.81, lightness: 0.47)),

            (UIColor.colorWithHSL(hue: 14, saturation: 1.0, lightness: 0.94),
             UIColor.colorWithHSL(hue: 14, saturation: 0.94, lightness: 0.58)),

            (UIColor.colorWithHSL(hue: 349, saturation: 1.0, lightness: 0.96),
             UIColor.colorWithHSL(hue: 349, saturation: 1.0, lightness: 0.65))
        ]
    }

    private func deriveColors(from data: Data) -> (UIColor, UIColor) {
        let colors = Self.allColorPairs

        let accountId: [UInt8] = data.map { $0 }
        let index = (UInt(accountId[30]) + UInt(accountId[31]) * 256) % UInt(colors.count)
        
        return colors[Int(index)]
    }
}

extension NovaIconGenerator: IconGenerating {
    public func generateFromAccountId(_ accountId: Data) throws -> DrawableIcon {
        /*
         let internalId = try deriveInternalIdFromAccountId(accountId)

         let colors = try getColorsForData(internalId)
         let centers = generateCircleCenters()

         let circles = (0..<centers.count).map { index in
         PolkadotIcon.Circle(origin: centers[index],
         color: colors[index],
         radius: Self.circleRadius)
         }

         return PolkadotIcon(radius: Self.diameter / 2.0,
         circles: circles)
         */
        /*
         Plan:
         1. [DONE] Create cicrcle with defined radius filled with linear gradient of two static colors
         2. [DONE] Add diamond-shaped hole in the middle
         3. [DONE] Adjust hole shape to become a star
         4. [TODO] Add dynamic color definition
         5. [TODO] Adjust star shape to be similar to Figma (add
         5. [TODO, COULD HAVE] Experiment with gradients type and rotation

         */

        let colors = deriveColors(from: accountId)
        return NovaIcon(radius: Self.diameter / 2.0, colors: colors)

        // return NovaIcon(radius: Self.diameter / 2.0, colors: colors)
    }
}
