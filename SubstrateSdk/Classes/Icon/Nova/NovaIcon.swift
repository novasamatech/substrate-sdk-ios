import UIKit

public struct NovaIcon {
    public let colors: (UIColor, UIColor)
    public let radius: CGFloat

    public init(radius: CGFloat, colors: (UIColor, UIColor)) {
        self.radius = radius
        self.colors = colors
    }

    private func generateOuterStarPoints(with center: CGPoint, radius: CGFloat) -> [CGPoint] {
        let topPoint = CGPoint(x: center.x, y: center.y + radius)
        let leftPoint = CGPoint(x: center.x - radius, y: center.y)
        let bottomPoint = CGPoint(x: center.x, y: center.y - radius)
        let rightPoint = CGPoint(x: center.x + radius, y: center.y)

        return [topPoint, leftPoint, bottomPoint, rightPoint]
    }

    private func generateInnerStarPoints(with center: CGPoint, radius: CGFloat) -> [CGPoint] {
        let topLeftPoint = CGPoint(x: center.x - radius, y: center.y + radius)
        let leftBottomPoint = CGPoint(x: center.x - radius, y: center.y - radius)
        let bottomRightPoint = CGPoint(x: center.x + radius, y: center.y - radius)
        let rightTopPoint = CGPoint(x: center.x + radius, y: center.y + radius)

        return [topLeftPoint, leftBottomPoint, bottomRightPoint, rightTopPoint]
    }

    private func generateControlPoints(
        with center: CGPoint,
        outerRadius: CGFloat,
        innerRadius: CGFloat
    ) -> [(CGPoint, CGPoint)] {
        let outerShift = outerRadius / 53.0
        let innerShift = innerRadius * 2.0

        return [
            (CGPoint(x: center.x - outerShift, y: center.y + outerRadius),
             CGPoint(x: center.x, y: center.y + innerShift)),

            (CGPoint(x: center.x - innerShift, y: center.y),
             CGPoint(x: center.x - outerRadius, y: center.y + outerShift)),

            (CGPoint(x: center.x - outerRadius, y: center.y - outerShift),
             CGPoint(x: center.x - innerShift, y: center.y)),

            (CGPoint(x: center.x, y: center.y - innerShift),
             CGPoint(x: center.x - outerShift, y: center.y - outerRadius)),

            (CGPoint(x: center.x + outerShift, y: center.y - outerRadius),
             CGPoint(x: center.x, y: center.y - innerShift)),

            (CGPoint(x: center.x + innerShift, y: center.y),
             CGPoint(x: center.x + outerRadius, y: center.y - outerShift)),

            (CGPoint(x: center.x + outerRadius, y: center.y + outerShift),
             CGPoint(x: center.x + innerShift, y: center.y)),

            (CGPoint(x: center.x, y: center.y + innerShift),
             CGPoint(x: center.x + outerShift, y: center.y + outerRadius))
        ]
    }
}

extension NovaIcon: DrawableIcon {
    public func drawInContext(_ context: CGContext, fillColor: UIColor, size: CGSize) {
        let targetRadius = min(size.width, size.height) / 2.0
        let centerX = size.width / 2.0
        let centerY = size.height / 2.0
        let center = CGPoint(x: centerX, y: centerY)
        let outerStarRadius = targetRadius * 0.8
        let innerStarRadius = outerStarRadius / 6.0

        let path = UIBezierPath(
            arcCenter: CGPoint(x: size.width / 2.0, y: size.height / 2.0),
            radius: targetRadius,
            startAngle: 0.0,
            endAngle: 2.0 * CGFloat.pi,
            clockwise: false
        )

        let outerPoints = generateOuterStarPoints(with: center, radius: outerStarRadius)
        let innerPoints = generateInnerStarPoints(with: center, radius: innerStarRadius)
        let controlPoints = generateControlPoints(
            with: center,
            outerRadius: outerStarRadius,
            innerRadius: innerStarRadius
        )

        path.move(to: outerPoints[0])
        for index in 0..<outerPoints.count {
            path.addCurve(
                to: innerPoints[index],
                controlPoint1: controlPoints[index * 2].0,
                controlPoint2: controlPoints[index * 2].1
            )
            path.addCurve(
                to: outerPoints[(index + 1) % outerPoints.count],
                controlPoint1: controlPoints[index * 2 + 1].0,
                controlPoint2: controlPoints[index * 2 + 1].1
            )
        }

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

