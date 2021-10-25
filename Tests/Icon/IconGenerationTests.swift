import XCTest
import SubstrateSdk

class IconGenerationTests: XCTestCase {
    func testIconGeneration() throws {
        // given

        let address = "5Dqvi1p4C7EhPPFKCixpF3QiaJEaDwWrR9gfWR5eUsfC39TX"
        let iconGenerator = PolkadotIconGenerator()

        let expectedCircles: [PolkadotIcon.Circle] = [
                                        PolkadotIcon.Circle(origin: CGPoint(x: 32.0, y: 8.0),
                                                          color: UIColor.colorWithHSL(hue: 196, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 32.0, y: 20.0),
                                                          color: UIColor.colorWithHSL(hue: 320, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 21.607695154586736, y: 14.0),
                                                          color: UIColor(white: 1.0, alpha: 0.0),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 11.215390309173472, y: 20.0),
                                                          color: UIColor.colorWithHSL(hue: 112, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 21.607695154586736, y: 26.0),
                                                          color: UIColor.colorWithHSL(hue: 22, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 11.215390309173472, y: 32.0),
                                                          color: UIColor.colorWithHSL(hue: 213, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 11.215390309173472, y: 44.0),
                                                          color: UIColor.colorWithHSL(hue: 163, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 21.607695154586736, y: 38.0),
                                                          color: UIColor.colorWithHSL(hue: 213, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 21.607695154586736, y: 50.0),
                                                          color: UIColor.colorWithHSL(hue: 185, saturation: 0.65, lightness: 0.75),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 32.0, y: 56.0),
                                                          color: UIColor.colorWithHSL(hue: 163, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 32.0, y: 44.0),
                                                          color: UIColor.colorWithHSL(hue: 213, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 42.392304845413264, y: 50.0),
                                                          color: UIColor.colorWithHSL(hue: 213, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 52.78460969082653, y: 44.0),
                                                          color: UIColor.colorWithHSL(hue: 112, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 42.392304845413264, y: 38.0),
                                                          color: UIColor.colorWithHSL(hue: 22, saturation: 0.65, lightness: 0.15),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 52.78460969082653, y: 32.0),
                                                          color: UIColor(white: 1.0, alpha: 0.0),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 52.78460969082653, y: 20.0),
                                                          color: UIColor.colorWithHSL(hue: 196.0, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 42.392304845413264, y: 26.0),
                                                          color: UIColor.colorWithHSL(hue: 320.0, saturation: 0.65, lightness: 0.53),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 42.392304845413264, y: 14.0),
                                                          color: UIColor.colorWithHSL(hue: 11.0, saturation: 0.65, lightness: 0.35),
                                                          radius: 5),
                                        PolkadotIcon.Circle(origin: CGPoint(x: 32, y: 32),
                                                          color: UIColor.colorWithHSL(hue: 309.0, saturation: 0.65, lightness: 0.53),
                                                          radius: 5.0)
            ].map { circle in
                let center = CGPoint(x: circle.origin.x - 32.0, y: circle.origin.y - 32.0)
                return PolkadotIcon.Circle(origin: center,
                                           color: circle.color,
                                           radius: circle.radius)
        }

        let expectedIcon = PolkadotIcon(radius: 32.0,
                                        circles: expectedCircles)

        // when

        let icon = try iconGenerator.generateFromAddress(address) as! PolkadotIcon

        // then

        let centers = icon.circles.map { $0.origin }
        let colors = icon.circles.map { $0.color }

        let expectedCenters = expectedIcon.circles.map { $0.origin }
        let expectedColors = expectedIcon.circles.map { $0.color }

        XCTAssertEqual(icon.circles.count, expectedIcon.circles.count)
        XCTAssertEqual(centers, expectedCenters)

        (0..<colors.count).forEach { index in
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0

            colors[index].getRed(&red, green: &green, blue: &blue, alpha: nil)

            var expectedRed: CGFloat = 0.0
            var expectedGreen: CGFloat = 0.0
            var expectedBlue: CGFloat = 0.0

            expectedColors[index].getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: nil)

            XCTAssertTrue(abs(red - expectedRed) < 1e-9)
            XCTAssertTrue(abs(green - expectedGreen) < 1e-9)
            XCTAssertTrue(abs(blue - expectedBlue) < 1e-9)
        }
    }

    func testOutOfBoundsColorParameters() {
        let address = "Fewyw2YrQgjtnuRsYQXfeHoTMoazKJKkfKkT8hc1WLjPsUP"

        XCTAssertNoThrow(try PolkadotIconGenerator().generateFromAddress(address))
    }
}
