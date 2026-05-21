import SwiftUI

// MARK: - Design Tokens
enum HanaColor {
    // Sakura palette
    static let sakuraPale  = Color(hex: "#fce8ef")
    static let sakuraBlush = Color(hex: "#f4b8c8")
    static let sakuraMid   = Color(hex: "#e8789a")
    static let sakuraDeep  = Color(hex: "#c94e78")
    static let sakuraInk   = Color(hex: "#7a1a3a")

    // Night palette
    static let night0  = Color(hex: "#0d0509")
    static let night1  = Color(hex: "#180b10")
    static let night2  = Color(hex: "#261120")
    static let night3  = Color(hex: "#341522")

    // Semantic
    static let emerald = Color(hex: "#3db87a")
    static let sky     = Color(hex: "#6ec5e0")
    static let gold    = Color(hex: "#d4a853")
    static let amber   = Color(hex: "#e8a040")

    // Borders
    static let border  = Color(hex: "#e8789a").opacity(0.18)
    static let border2 = Color(hex: "#e8789a").opacity(0.32)

    // Text
    static let textPrimary = Color(hex: "#f8e8ef")
    static let textMuted   = Color(hex: "#f8e8ef").opacity(0.55)
    static let textDim     = Color(hex: "#f8e8ef").opacity(0.30)

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [night0, night1, night2],
        startPoint: .top, endPoint: .bottom
    )
    static let cardGradient = LinearGradient(
        colors: [night1.opacity(0.9), night2.opacity(0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sakuraGradient = LinearGradient(
        colors: [sakuraInk, sakuraDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum HanaFont {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - Spacing
enum HanaSpacing {
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 16
    static let lg: CGFloat   = 24
    static let xl: CGFloat   = 32
    static let xxl: CGFloat  = 48
}

// MARK: - Corner Radius
enum HanaRadius {
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let lg: CGFloat   = 16
    static let xl: CGFloat   = 24
    static let pill: CGFloat = 999
}

// MARK: - Card Style
struct HanaCard: ViewModifier {
    var padding: CGFloat = HanaSpacing.md
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: HanaRadius.lg)
                    .fill(HanaColor.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: HanaRadius.lg)
                            .strokeBorder(HanaColor.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Glass Style (frosted)
struct HanaGlass: ViewModifier {
    var cornerRadius: CGFloat = HanaRadius.lg
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(HanaColor.night0.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(HanaColor.border2, lineWidth: 1)
            )
    }
}

extension View {
    func hanaCard(padding: CGFloat = HanaSpacing.md) -> some View {
        modifier(HanaCard(padding: padding))
    }
    func hanaGlass(cornerRadius: CGFloat = HanaRadius.lg) -> some View {
        modifier(HanaGlass(cornerRadius: cornerRadius))
    }
}

// MARK: - Animated Petal Button
struct PetalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let isActive: Bool
    func body(content: Content) -> some View {
        if isActive {
            content.overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.2), .clear],
                    startPoint: .init(x: phase - 0.5, y: 0),
                    endPoint: .init(x: phase + 0.5, y: 1)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
        } else {
            content
        }
    }
}
extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
