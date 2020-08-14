import UIKit

public final class KusamaIconView: UIView {
    private(set) var icon: DrawableIcon?

    public func bind(icon: DrawableIcon) {
        self.icon = icon

        setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let context = UIGraphicsGetCurrentContext() {
            icon?.drawInContext(context, size: rect.size)
        }
    }
}
