import SwiftUI
import Charts

// MARK: - Bloom Ring
struct BloomRingView: View {
    let percent: Int
    let status: BloomStatus
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(HanaColor.border, lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(
                    AngularGradient(
                        colors: status.gradientColors,
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: percent)

            VStack(spacing: 2) {
                Text("\(percent)%")
                    .font(HanaFont.mono(16, weight: .bold))
                    .foregroundColor(status.color)
                Text(status.emoji)
                    .font(.system(size: 14))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Status Pill
struct StatusPillView: View {
    let status: BloomStatus
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Text(status.emoji)
                .font(.system(size: compact ? 10 : 12))
            Text(status.label)
                .font(HanaFont.body(compact ? 10 : 11, weight: .semibold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 4)
        .background(status.color.opacity(0.12))
        .overlay(
            Capsule().strokeBorder(status.color.opacity(0.35), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Bloom Bar
struct BloomBarView: View {
    let percent: Int
    let status: BloomStatus
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LinearGradient(
                        colors: status.gradientColors,
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
                    .animation(.spring(response: 0.8), value: percent)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Weather Day Card
struct WeatherDayCard: View {
    let weather: DailyWeather
    var compact = false

    var body: some View {
        VStack(spacing: 3) {
            Text(weather.day)
                .font(HanaFont.mono(8))
                .foregroundColor(HanaColor.textDim)
            Text(weather.icon)
                .font(.system(size: compact ? 14 : 16))
            VStack(spacing: 1) {
                Text("\(weather.tempHigh)°")
                    .font(HanaFont.body(9, weight: .bold))
                    .foregroundColor(HanaColor.sakuraBlush)
                Text("\(weather.tempLow)°")
                    .font(HanaFont.body(8))
                    .foregroundColor(HanaColor.textDim)
            }
            Text("💧\(weather.precipProb)%")
                .font(HanaFont.mono(7))
                .foregroundColor(HanaColor.sky)
            Text(weather.advice.rawValue)
                .font(HanaFont.body(7, weight: .bold))
                .foregroundColor(weather.advice.color)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(weather.advice.color.opacity(0.12))
                .overlay(Capsule().strokeBorder(weather.advice.color.opacity(0.35), lineWidth: 0.5))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: HanaRadius.sm)
                .strokeBorder(HanaColor.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: HanaRadius.sm))
    }
}

// MARK: - Bloom Timeline Row
struct BloomTimelineView: View {
    let spot: CherrySpot

    var body: some View {
        HStack(spacing: 6) {
            phaseBox(icon: "🌸", label: "开花", date: spot.firstBloomDate,
                     bg: Color(hex: "#d4a853").opacity(0.12),
                     border: Color(hex: "#d4a853").opacity(0.3))
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(HanaColor.textDim)
            phaseBox(icon: "🌺", label: "満開", date: spot.fullBloomDate,
                     bg: HanaColor.sakuraDeep.opacity(0.15),
                     border: HanaColor.sakuraDeep.opacity(0.4))
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(HanaColor.textDim)
            phaseBox(icon: "🍃", label: "散花", date: spot.endBloomDate,
                     bg: HanaColor.sky.opacity(0.08),
                     border: HanaColor.sky.opacity(0.25))
        }
    }

    @ViewBuilder
    private func phaseBox(icon: String, label: String, date: String, bg: Color, border: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(icon) \(label)")
                .font(HanaFont.body(10))
                .foregroundColor(HanaColor.textMuted)
            Text(date.dropFirst(5).replacingOccurrences(of: "-", with: "/"))
                .font(HanaFont.mono(11, weight: .bold))
                .foregroundColor(HanaColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(bg)
        .overlay(RoundedRectangle(cornerRadius: HanaRadius.sm).strokeBorder(border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: HanaRadius.sm))
    }
}

// MARK: - Info Row
struct InfoRowView: View {
    let icon: String
    let title: String
    let content: String
    var accentColor: Color = HanaColor.sakuraBlush

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon)
                .font(.system(size: 16))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HanaFont.body(11, weight: .semibold))
                    .foregroundColor(accentColor)
                Text(content)
                    .font(HanaFont.body(12))
                    .foregroundColor(HanaColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: HanaRadius.sm)
                .strokeBorder(HanaColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HanaRadius.sm))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(HanaFont.mono(9, weight: .regular))
            .foregroundColor(HanaColor.textDim)
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(HanaFont.body(11))
            .foregroundColor(HanaColor.textMuted)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .overlay(Capsule().strokeBorder(HanaColor.border, lineWidth: 1))
            .clipShape(Capsule())
    }
}

// MARK: - Probability Chart
struct ProbabilityChartView: View {
    let points: [ProbabilityPoint]

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(points) { p in
                    AreaMark(
                        x: .value("日期", p.dateLabel),
                        y: .value("开花率", p.bloomPercent)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [HanaColor.sakuraMid.opacity(0.4), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("日期", p.dateLabel),
                        y: .value("开花率", p.bloomPercent)
                    )
                    .foregroundStyle(HanaColor.sakuraMid)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel()
                        .foregroundStyle(HanaColor.textDim)
                        .font(HanaFont.mono(8))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel()
                        .foregroundStyle(HanaColor.textDim)
                        .font(HanaFont.mono(8))
                }
            }
            .frame(height: 140)
        }
    }
}

// MARK: - Favorite Heart Button
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { bouncing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bouncing = false }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16))
                .foregroundColor(isFavorite ? HanaColor.sakuraDeep : HanaColor.textDim)
                .scaleEffect(bouncing ? 1.35 : 1.0)
        }
    }
}

// MARK: - Loading Skeleton
struct SkeletonCard: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 6).fill(shimmerGradient).frame(height: 14)
            RoundedRectangle(cornerRadius: 6).fill(shimmerGradient).frame(width: 150, height: 11)
            RoundedRectangle(cornerRadius: 6).fill(shimmerGradient).frame(height: 4)
        }
        .hanaCard()
        .onAppear {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }

    var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.06), Color.white.opacity(0.15), Color.white.opacity(0.06)],
            startPoint: .init(x: phase - 0.5, y: 0),
            endPoint: .init(x: phase + 0.5, y: 0)
        )
    }
}

// MARK: - Petal Particle View (SwiftUI canvas)
struct PetalCanvasView: View {
    @State private var petals: [Petal] = []
    @State private var timer: Timer?

    struct Petal: Identifiable {
        let id = UUID()
        var x, y, size, speedX, speedY, rotation, rotSpeed, opacity: Double
        var hue: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                for p in petals {
                    var transform = CGAffineTransform(translationX: p.x, y: p.y)
                        .rotated(by: p.rotation)
                    let path = Ellipse().path(in: CGRect(x: -p.size/2, y: -p.size*0.3,
                                                          width: p.size, height: p.size * 0.6))
                    ctx.opacity = p.opacity
                    ctx.fill(path.applying(transform),
                             with: .color(Color(hue: p.hue/360, saturation: 0.6, brightness: 0.9)))
                }
            }
        }
        .onAppear { startPetals() }
        .onDisappear { timer?.invalidate() }
    }

    private func startPetals() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            if petals.count < 40 && Double.random(in: 0...1) < 0.3 {
                petals.append(Petal(
                    x: Double.random(in: 0...UIScreen.main.bounds.width),
                    y: -20,
                    size: Double.random(in: 4...12),
                    speedX: Double.random(in: -0.8...0.8),
                    speedY: Double.random(in: 0.5...1.5),
                    rotation: Double.random(in: 0...(.pi * 2)),
                    rotSpeed: Double.random(in: -0.05...0.05),
                    opacity: Double.random(in: 0.25...0.55),
                    hue: Double.random(in: 340...370)
                ))
            }
            petals = petals.compactMap { p in
                var updated = p
                updated.x += p.speedX
                updated.y += p.speedY
                updated.rotation += p.rotSpeed
                if updated.y > UIScreen.main.bounds.height + 30 { return nil }
                return updated
            }
        }
    }
}
