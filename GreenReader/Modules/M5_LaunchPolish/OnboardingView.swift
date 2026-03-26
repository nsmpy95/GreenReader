import SwiftUI

// MARK: - OnboardingView
// Displayed on first launch only. Guides the user through the scanning workflow.
struct OnboardingView: View {

    /// Optional callback invoked after the user taps "Got it".
    /// Defaults to a no-op so the view can be presented via .sheet without extra wiring.
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    // MARK: - Step model

    private struct Step {
        let number: Int
        let text: String
    }

    private let steps: [Step] = [
        Step(number: 1, text: "Stand on the green"),
        Step(number: 2, text: "Tap Start Scan"),
        Step(number: 3, text: "Walk slowly across the green"),
        Step(number: 4, text: "Tap Stop to see the slope map")
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.darkBg
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Title
                Text("GreenReader")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.greenAccent)
                    .padding(.top, 56)
                    .padding(.bottom, 40)

                // Steps list
                VStack(spacing: 24) {
                    ForEach(steps, id: \.number) { step in
                        StepRow(number: step.number, text: step.text)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // "Got it" button
                Button {
                    UserDefaults.standard.set(true, forKey: "onboardingComplete")
                    onComplete()
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.greenAccent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - StepRow
// A single numbered step in the onboarding list.
private struct StepRow: View {

    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            // Numbered circle
            ZStack {
                Circle()
                    .fill(Color.greenAccent)
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Step description
            Text(text)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
