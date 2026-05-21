import SwiftUI

struct FrontlineView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedRegion = "all"
    @State private var selectedSpot: CherrySpot?
    @State private var showDetail = false

    private var filtered: [CherrySpot] {
        let base = dataService.spots.sorted { $0.bloomPercent > $1.bloomPercent }
        if selectedRegion == "all" { return base }
        return base.filter { $0.region == selectedRegion }
    }

    private var stats: (full: Int, blooming: Int, soon: Int) {
        let spots = dataService.spots
        return (
            full:     spots.filter { $0.status == .fullBloom }.count,
            blooming: spots.filter { [.blooming, .opening].contains($0.status) }.count,
            soon:     spots.filter { [.budding, .notYet].contains($0.status) }.count
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HanaColor.night0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        frontlineHeader
                        // Stats
                        statsRow
                        // Region filter
                        regionFilter
                        // Grid
                        spotGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDetail) {
            if let spot = selectedSpot {
                SpotDetailView(spot: spot)
            }
        }
    }

    // MARK: Header
    var frontlineHeader: some View {
        VStack(spacing: 4) {
            Text("🌊 全国樱花前线")
                .font(HanaFont.serif(26, weight: .bold))
                .foregroundColor(HanaColor.sakuraBlush)
            Text("CHINA SAKURA FRONT · 2026 · REAL-TIME")
                .font(HanaFont.mono(9))
                .foregroundColor(HanaColor.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Stats Row
    var statsRow: some View {
        HStack(spacing: 10) {
            statBox(value: stats.full, label: "満　開", color: HanaColor.sakuraDeep)
            statBox(value: stats.blooming, label: "开花中", color: HanaColor.sakuraMid)
            statBox(value: stats.soon, label: "即将开放", color: HanaColor.gold)
            statBox(value: dataService.spots.count, label: "监测地点", color: HanaColor.sky)
        }
    }

    @ViewBuilder
    private func statBox(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(HanaFont.serif(26, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(HanaFont.body(10))
                .foregroundColor(HanaColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: HanaRadius.lg)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: HanaRadius.lg)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: Region Filter
    var regionFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("按地区筛选")
                .font(HanaFont.mono(9))
                .foregroundColor(HanaColor.textDim)
                .tracking(1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(allRegions) { region in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedRegion = region.code
                            }
                        } label: {
                            Text(region.name)
                                .font(HanaFont.body(11, weight: selectedRegion == region.code ? .semibold : .regular))
                                .foregroundColor(selectedRegion == region.code ? HanaColor.sakuraPale : HanaColor.textMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(
                                        selectedRegion == region.code
                                        ? HanaColor.sakuraGradient
                                        : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                )
                                .overlay(
                                    Capsule().strokeBorder(
                                        selectedRegion == region.code
                                        ? HanaColor.sakuraMid.opacity(0.6)
                                        : HanaColor.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PetalButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Spot Grid
    var spotGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filtered) { spot in
                FrontlineCard(spot: spot) {
                    selectedSpot = spot
                    showDetail = true
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: selectedRegion)
    }
}

// MARK: - Frontline Card
struct FrontlineCard: View {
    let spot: CherrySpot
    let onTap: () -> Void
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: spot.imageURL ?? "")) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            ZStack {
                                LinearGradient(
                                    colors: spot.status.gradientColors.map { $0.opacity(0.4) },
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                                Text("🌸").font(.system(size: 36)).opacity(0.4)
                            }
                        }
                    }
                    .frame(height: 110)
                    .clipped()

                    // Bloom percent badge
                    Text("\(spot.bloomPercent)%")
                        .font(HanaFont.mono(10, weight: .bold))
                        .foregroundColor(HanaColor.sakuraPale)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(spot.status.color.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(7)
                }
                .frame(height: 110)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, HanaColor.night1.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 40)
                }

                // Body
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(spot.region) · \(spot.province)")
                        .font(HanaFont.mono(8))
                        .foregroundColor(HanaColor.textDim)
                    Text(spot.name)
                        .font(HanaFont.serif(14, weight: .semibold))
                        .foregroundColor(HanaColor.sakuraPale)
                        .lineLimit(1)

                    StatusPillView(status: spot.status, compact: true)

                    // Bloom bar
                    BloomBarView(percent: spot.bloomPercent, status: spot.status, height: 3)

                    HStack {
                        Text("満開 \(spot.fullBloomDate.dropFirst(5))")
                            .font(HanaFont.mono(8))
                            .foregroundColor(HanaColor.textMuted)
                        Spacer()
                        Text("\(spot.weatherIcon) \(String(format: "%.0f", spot.temperature))°")
                            .font(HanaFont.body(10))
                    }
                }
                .padding(10)
                .background(HanaColor.night1.opacity(0.95))
            }
            .clipShape(RoundedRectangle(cornerRadius: HanaRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: HanaRadius.lg)
                    .strokeBorder(HanaColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PetalButtonStyle())
    }
}

#Preview {
    FrontlineView()
        .environmentObject(DataService.shared)
}
