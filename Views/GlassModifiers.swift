import SwiftUI

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}

struct GlowText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 0)
            .shadow(color: Color.blue.opacity(0.2), radius: 2, x: 0, y: 0)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }

    func glowText() -> some View {
        modifier(GlowText())
    }
}
