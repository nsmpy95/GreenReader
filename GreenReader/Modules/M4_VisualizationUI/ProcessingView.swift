import SwiftUI
import UIKit

// MARK: - ProcessingView
// Full-screen overlay shown while scanState == .processing.
// Presents a custom CAShapeLayer spinner and an "Analysing slopes…" label.
struct ProcessingView: View {

    var body: some View {
        ZStack {
            // Semi-transparent dark scrim — disables interaction with layers below.
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(true)  // blocks taps on underlying views

            VStack(spacing: 20) {
                // Custom green circular spinner
                CircularSpinnerView()
                    .frame(width: 68, height: 68)

                Text("Analysing slopes…")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - CircularSpinnerView
// UIViewRepresentable wrapping a CAShapeLayer that animates strokeEnd
// to produce a smooth, repeating arc-sweep loading indicator.
private struct CircularSpinnerView: UIViewRepresentable {

    func makeUIView(context: Context) -> SpinnerHostView {
        SpinnerHostView()
    }

    func updateUIView(_ uiView: SpinnerHostView, context: Context) { }
}

// MARK: - SpinnerHostView
final class SpinnerHostView: UIView {

    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureLayerIfNeeded()
    }

    // Configure once the bounds are known.
    private var layerConfigured = false
    private func configureLayerIfNeeded() {
        guard !layerConfigured, bounds.width > 0 else { return }
        layerConfigured = true

        let radius: CGFloat = 30
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)

        let circlePath = UIBezierPath(
            arcCenter: centre,
            radius: radius,
            startAngle: -.pi / 2,   // start at top
            endAngle:    .pi * 1.5, // full circle
            clockwise: true
        )

        shapeLayer.path            = circlePath.cgPath
        shapeLayer.strokeColor     = UIColor(Color.greenAccent).cgColor
        shapeLayer.fillColor       = UIColor.clear.cgColor
        shapeLayer.lineWidth       = 4
        shapeLayer.lineCap         = .round
        shapeLayer.strokeStart     = 0
        shapeLayer.strokeEnd       = 0.25  // arc length visible at any frame

        layer.addSublayer(shapeLayer)

        // Animate strokeEnd from 0.25 to 1 (sweep) while rotating the whole layer.
        // Using a rotation on the view's layer creates the "chasing" effect cleanly.
        let strokeAnim                    = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnim.fromValue              = 0.05
        strokeAnim.toValue                = 0.95
        strokeAnim.duration               = 1.2
        strokeAnim.timingFunction         = CAMediaTimingFunction(name: .easeInEaseOut)
        strokeAnim.autoreverses           = true
        strokeAnim.repeatCount            = .infinity
        shapeLayer.add(strokeAnim, forKey: "strokeEnd")

        let rotateAnim                    = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnim.fromValue              = 0
        rotateAnim.toValue                = 2 * Double.pi
        rotateAnim.duration               = 1.2
        rotateAnim.repeatCount            = .infinity
        layer.add(rotateAnim, forKey: "rotation")
    }
}
