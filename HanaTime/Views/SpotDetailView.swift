import SwiftUI

struct SpotDetailView: View {
    let spot: CherrySpot
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var imageLoaded = false
    @State private var showingShareSheet = false

    private var probabilities: [ProbabilityPoint] {
        dataService.bloomProbabilities(for: spot)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HanaColor.night0.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero image
                        heroSection
                        // Content
                        VStack(spacing: 16) {
                            statusSection
                            timelineSection
                            bestTimeSection
                            weatherSection
                            forecastSection
                            tagsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(HanaColor.textMuted)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        FavoriteButton(isFavorite: spot.isFavorite) {
                            dataService.toggleFavorite(id: spot.id)
                        }
                        Button {
                            showingShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .foregroundColor(HanaColor.textMuted)
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: Hero
    var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            AsyncImage(url: URL(string: spot.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .transition(.opacity)
                case .failure, .empty:
                    ZStack {
                        LinearGradient(
                            colors: [HanaColor.sakuraInk.opacity(0.6), HanaColor.night2],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        Text("🌸").font(.system(size: 60)).opacity(0.5)
                    }
                @unknown default:
                    HanaColor.night2
                }
            }
            .frame(height: 260)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, HanaColor.night0.opacity(0.6), HanaColor.night0],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 260)

            // Name block
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    StatusPillView(status: spot.status)
                    Spacer()
                    Text("⭐ \(String(format: "%.1f", spot.rating))")
                        .font(HanaFont.mono(11))
                        .foregroundColor(HanaColor.gold)
                }
                Text(spot.name)
                    .font(HanaFont.serif(28, weight: .bold))
                    .foregroundColor(.white)
                Text("\(spot.region) · \(spot.province) · \(spot.nameEn)")
                    .font(HanaFont.mono(11))
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(20)
        }
        .frame(height: 260)
    }

    // MARK: Status
    var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "当前开放状态")
            HStack(spacing: 16) {
                BloomRingView(percent: spot.bloomPercent, status: spot.status, size: 88)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(spot.status.emoji).font(.system(size: 20))
                        Text(spot.status.label)
                            .font(HanaFont.serif(18, weight: .bold))
                            .foregroundColor(HanaColor.sakuraPale)
                    }
                    Text(spot.description)
                        .font(HanaFont.body(12))
                        .foregroundColor(HanaColor.textMuted)
                        .lineSpacing(4)
                    HStack(spacing: 10) {
                        Label("🌳 \(spot.treeCount.formatted()) 棵", systemImage: "").font(HanaFont.mono(9))
                        Label("⛰ \(spot.altitude)m", systemImage: "").font(HanaFont.mono(9))
                    }
                    .foregroundColor(HanaColor.textDim)
                }
            }

            // Confidence bar
            HStack(spacing: 8) {
                Text("预测置信度")
                    .font(HanaFont.mono(9))
                    .foregroundColor(HanaColor.textDim)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: [HanaColor.emerald, HanaColor.sky],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * spot.confidence)
                    }
                }
                .frame(height: 4)
                Text("\(Int(spot.confidence * 100))%")
                    .font(HanaFont.mono(9, weight: .bold))
                    .foregroundColor(HanaColor.emerald)
            }
        }
        .hanaCard()
    }

    // MARK: Timeline
    var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "🗓 完整花期时间线")
            BloomTimelineView(spot: spot)
            Text("花期约 \(spot.bloomDuration) 天 · 満開持续约 7–10 天 · DTS增强模型")
                .font(HanaFont.mono(9))
                .foregroundColor(HanaColor.textDim)
                .frame(maxWidth: .infinity)
        }
        .hanaCard()
    }

    // MARK: Best Time
    var bestTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "⭐ 最佳赏樱时间")
            InfoRowView(icon: "🎯", title: "最佳时期", content: spot.bestPeriod)
            InfoRowView(icon: "🕐", title: "每日最佳时段", content: spot.bestHours)
            InfoRowView(icon: "🚇", title: "交通", content: spot.access)
            InfoRowView(icon: "💡", title: "赏花贴士", content: spot.tips,
                        accentColor: HanaColor.gold)
        }
        .hanaCard()
    }

    // MARK: Weather
    var weatherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "🌤 未来7天 · 赏花指数")
            HStack(spacing: 4) {
                ForEach(spot.weekly) { w in
                    WeatherDayCard(weather: w)
                }
            }
            // Legend
            HStack(spacing: 10) {
                ForEach([ViewingAdvice.excellent, .good, .fair, .poor], id: \.rawValue) { adv in
                    HStack(spacing: 3) {
                        Circle().fill(adv.color).frame(width: 5, height: 5)
                        Text(adv.rawValue)
                            .font(HanaFont.body(9, weight: .semibold))
                            .foregroundColor(adv.color)
                    }
                }
                Spacer()
                // Current weather strip
                HStack(spacing: 8) {
                    Text(spot.weatherIcon).font(.system(size: 14))
                    Text("\(String(format: "%.0f", spot.temperature))°C")
                        .font(HanaFont.body(13, weight: .bold))
                        .foregroundColor(HanaColor.sakuraBlush)
                    Text("湿度 \(spot.humidity)%")
                        .font(HanaFont.mono(9))
                        .foregroundColor(HanaColor.textDim)
                }
            }
        }
        .hanaCard()
    }

    // MARK: Forecast Chart
    var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "📈 开花概率预测（30天）")
            ProbabilityChartView(points: probabilities)
        }
        .hanaCard()
    }

    // MARK: Tags
    var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "标签")
            FlowLayout(spacing: 6) {
                ForEach(spot.tags, id: \.self) { tag in
                    TagChip(text: tag)
                }
            }
        }
        .hanaCard()
    }

    private var shareText: String {
        "【花时】\(spot.name) — \(spot.status.label)，开放度 \(spot.bloomPercent)%，満開预计 \(spot.fullBloomDate)。\(spot.description)"
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 300
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > w && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
        return CGSize(width: w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

#Preview {
    SpotDetailView(spot: DataService.seedData()[0])
        .environmentObject(DataService.shared)
}
