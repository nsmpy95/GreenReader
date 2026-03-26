import SwiftUI

// MARK: - LaunchScreenView
// Reference SwiftUI implementation of the launch screen visual.
// The production launch screen is configured via the Xcode project's
// Info.plist / LaunchScreen storyboard. This view can be used during
// development or in SwiftUI previews to verify typography and colours.
struct LaunchScreenView: View {

    var body: some View {
        ZStack {
            Color.darkBg
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("GreenReader")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.greenAccent)

                Text("LiDAR Green Reading")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
