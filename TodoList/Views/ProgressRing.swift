import SwiftUI

/// A white ring that fills up as tasks get done, with the percentage in the middle.
/// Meant to sit on top of the gradient header.
struct ProgressRing: View {
    /// From 0 (nothing done) to 1 (everything done).
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)

            Text("\(Int((progress * 100).rounded()))%")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.25)
        .frame(width: 100, height: 100)
        .padding()
        .background(Theme.headerGradient)
}
