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
        let starInset = targetRadius / 5.0
        let controlPointOffset = targetRadius / 10
        let centerX = size.width / 2.0
        let centerY = size.height / 2.0

        let path = UIBezierPath(
            arcCenter: CGPoint(x: size.width / 2.0, y: size.height / 2.0),
            radius: targetRadius,
            startAngle: 0.0,
            endAngle: 2.0 * CGFloat.pi,
            clockwise: false
        )

        /*
         TODO: There are eight star components, not four.
         However, it is possible to put everything into one formula
         I'll do it after I finish with coloring
         */
        let topStarPoint = CGPoint(x: centerX, y: centerY + starInset * 4.0)
        let leftStarPoint = CGPoint(x: centerX - starInset * 4.0, y: centerY)
        let bottomStarPoint = CGPoint(x: centerX, y: centerY - starInset * 4.0)
        let rightStarPoint = CGPoint(x: centerX + starInset * 4.0, y: centerY)

        let topControlPoint = CGPoint(x: centerX, y: centerY + controlPointOffset)
        let leftControlPoint = CGPoint(x: centerX - controlPointOffset, y: centerY)
        let bottomControlPoint = CGPoint(x: centerX, y: centerY - controlPointOffset)
        let rightControlPoint = CGPoint(x: centerX + controlPointOffset, y: centerY)

        path.move(to: topStarPoint)
        path.addCurve(to: leftStarPoint, controlPoint1: topControlPoint, controlPoint2: leftControlPoint)
        path.addCurve(to: bottomStarPoint, controlPoint1: leftControlPoint, controlPoint2: bottomControlPoint)
        path.addCurve(to: rightStarPoint, controlPoint1: bottomControlPoint, controlPoint2: rightControlPoint)
        path.addCurve(to: topStarPoint, controlPoint1: rightControlPoint, controlPoint2: topControlPoint)

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

