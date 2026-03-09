import SwiftUI

struct ScoreRingView: View {
    let score: Int
    let rank: HealthRank
    var size: CGFloat = 160

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        CGFloat(score) / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.quaternarySystemFill), lineWidth: 12)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(rank.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                Text(rank.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(rank.color)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) {
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }
}
