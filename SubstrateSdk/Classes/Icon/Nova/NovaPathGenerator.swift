//
//  NovaPathGenerator.swift
//  SubstrateSdk
//
//  Created by Stanislav Litvinov on 09.12.2021.
//

import Foundation

/// To change the shape take your SVG file, take content of <shape d="..."> attribute
/// convert it to paths using any online converter (for example, https://swiftvg.mike-engel.com)
/// and paste it here.
struct NovaPathGenerator {
    static func generatePath() -> UIBezierPath {
        let shape = UIBezierPath()

        shape.move(to: CGPoint(x: 88.77, y: 0.98))
        shape.addCurve(
            to: CGPoint(x: 91.23, y: 0.98),
            controlPoint1: CGPoint(x: 89.07, y: -0.33),
            controlPoint2: CGPoint(x: 90.93, y: -0.33)
        )
        shape.addLine(to: CGPoint(x: 103.87, y: 57.09))
        shape.addCurve(
            to: CGPoint(x: 122.91, y: 76.13),
            controlPoint1: CGPoint(x: 106.01, y: 66.58),
            controlPoint2: CGPoint(x: 113.42, y: 73.99)
        )
        shape.addLine(to: CGPoint(x: 179.02, y: 88.77))
        shape.addCurve(
            to: CGPoint(x: 179.02, y: 91.23),
            controlPoint1: CGPoint(x: 180.33, y: 89.07),
            controlPoint2: CGPoint(x: 180.33, y: 90.93)
        )
        shape.addLine(to: CGPoint(x: 122.91, y: 103.87))
        shape.addCurve(
            to: CGPoint(x: 103.87, y: 122.91),
            controlPoint1: CGPoint(x: 113.42, y: 106.01),
            controlPoint2: CGPoint(x: 106.01, y: 113.42)
        )
        shape.addLine(to: CGPoint(x: 91.23, y: 179.02))
        shape.addCurve(
            to: CGPoint(x: 88.77, y: 179.02),
            controlPoint1: CGPoint(x: 90.93, y: 180.33),
            controlPoint2: CGPoint(x: 89.07, y: 180.33)
        )
        shape.addLine(to: CGPoint(x: 76.13, y: 122.91))
        shape.addCurve(
            to: CGPoint(x: 57.09, y: 103.87),
            controlPoint1: CGPoint(x: 73.99, y: 113.42),
            controlPoint2: CGPoint(x: 66.58, y: 106.01)
        )
        shape.addLine(to: CGPoint(x: 0.98, y: 91.23))
        shape.addCurve(
            to: CGPoint(x: 0.98, y: 88.77),
            controlPoint1: CGPoint(x: -0.33, y: 90.93),
            controlPoint2: CGPoint(x: -0.33, y: 89.07)
        )
        shape.addLine(to: CGPoint(x: 57.09, y: 76.13))
        shape.addCurve(
            to: CGPoint(x: 76.13, y: 57.09),
            controlPoint1: CGPoint(x: 66.58, y: 73.99),
            controlPoint2: CGPoint(x: 73.99, y: 66.58)
        )
        shape.addLine(to: CGPoint(x: 88.77, y: 0.98))
        shape.close()

        return shape
    }
}
