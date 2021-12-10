import UIKit

public struct NovaIcon {
    public let colors: (UIColor, UIColor)
    public let radius: CGFloat

    public init(radius: CGFloat, colors: (UIColor, UIColor)) {
        self.radius = radius
        self.colors = colors
    }
}

extension NovaIcon: DrawableIcon {
    public func drawInContext(_ context: CGContext, fillColor: UIColor, size: CGSize) {
        let targetRadius = min(size.width, size.height) / 2.0
        let centerX = size.width / 2.0
        let centerY = size.height / 2.0
        let targetInnerRadius = targetRadius * 0.75

        let path = UIBezierPath(
            arcCenter: CGPoint(x: size.width / 2.0, y: size.height / 2.0),
            radius: targetRadius,
            startAngle: 0.0,
            endAngle: 2.0 * CGFloat.pi,
            clockwise: false
        )

        let innerPath = NovaPathGenerator.generatePath()
        var innerSize = innerPath.bounds.size

        let scale = targetInnerRadius * 2.0 / max(innerSize.width, innerSize.height)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        innerPath.apply(scaleTransform)

        innerSize = innerPath.bounds.size
        let moveTransform = CGAffineTransform(
            translationX: centerX - innerSize.width / 2.0,
            y: centerY - innerSize.height / 2.0
        )
        innerPath.apply(moveTransform)

        path.append(innerPath)
        path.addClip()

        let startColor = colors.0.cgColor
        let endColor = colors.1.cgColor

        let startPoint = CGPoint(x: 0.0, y: 0.0)
        let endPoint = CGPoint(x: 0.0, y: size.height)

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [startColor, endColor] as CFArray,
            locations: nil
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: []
        )
    }
}
