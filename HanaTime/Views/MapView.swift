import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedRegion = "all"
    @State private var searchText     = ""
    @State private var selectedSpot: CherrySpot?
    @State private var showingDetail  = false
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.86, longitude: 104.19),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    )
    @State private var isHybridMap = false
    @State private var showMap = true

    private var filtered: [CherrySpot] {
        dataService.filteredSpots(region: selectedRegion, query: searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HanaColor.night0.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Top bar
                    topBar
                    // Region filter chips
                    regionChips
                    // Toggle Map/List
                    viewToggle
                    // Content
                    if showMap {
                        mapContent
                    } else {
                        spotListContent
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDetail) {
            if let spot = selectedSpot {
                SpotDetailView(spot: spot)
            }
        }
    }

    // MARK: Top Bar
    var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Logo
                HStack(spacing: 6) {
                    Text("🌸").font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("花时")
                            .font(HanaFont.serif(18, weight: .bold))
                            .foregroundColor(HanaColor.sakuraBlush)
                        Text("China Sakura · 实时预测")
                            .font(HanaFont.mono(9))
                            .foregroundColor(HanaColor.textDim)
                    }
                }

                Spacer()

                // Location badge
                Button(action: { locationService.requestLocation() }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(locationService.isLocating ? HanaColor.gold : HanaColor.sky)
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .stroke(locationService.isLocating ? HanaColor.gold.opacity(0.4) : HanaColor.sky.opacity(0.3), lineWidth: 3)
                                    .scaleEffect(locationService.isLocating ? 1.5 : 1)
                                    .opacity(locationService.isLocating ? 0 : 1)
                                    .animation(.easeOut(duration: 1).repeatForever(), value: locationService.isLocating)
                            )
                        Text(locationService.locationName)
                            .font(HanaFont.mono(10))
                            .foregroundColor(locationService.userLocation != nil ? HanaColor.emerald : HanaColor.sky)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            locationService.userLocation != nil
                            ? HanaColor.emerald.opacity(0.1)
                            : HanaColor.sky.opacity(0.1)
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            locationService.userLocation != nil
                            ? HanaColor.emerald.opacity(0.3)
                            : HanaColor.sky.opacity(0.3), lineWidth: 1
                        )
                    )
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(HanaColor.textDim)
                TextField("搜索观樱地点…", text: $searchText)
                    .font(HanaFont.body(13))
                    .foregroundColor(HanaColor.textPrimary)
                    .tint(HanaColor.sakuraMid)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(HanaColor.textDim)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: HanaRadius.sm)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: HanaRadius.sm)
                            .strokeBorder(HanaColor.border, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial.opacity(0.6))
        .background(HanaColor.night0.opacity(0.8))
        .overlay(alignment: .bottom) {
            Rectangle().fill(HanaColor.border).frame(height: 0.5)
        }
    }

    // MARK: Region Chips
    var regionChips: some View {
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
                                    ? LinearGradient(colors: [HanaColor.sakuraInk, Color(hex: "#4a1028")], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(HanaColor.night1.opacity(0.6))
    }

    // MARK: View Toggle
    var viewToggle: some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(filtered.count) 个地点")
                    .font(HanaFont.mono(10))
                    .foregroundColor(HanaColor.textMuted)
                if dataService.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(HanaColor.sakuraMid)
                }
            }
            Spacer()
            // Map/List toggle
            HStack(spacing: 2) {
                Button {
                    withAnimation { showMap = true }
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 12))
                        .padding(7)
                        .foregroundColor(showMap ? HanaColor.sakuraBlush : HanaColor.textDim)
                        .background(showMap ? HanaColor.sakuraInk.opacity(0.5) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Button {
                    withAnimation { showMap = false }
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .padding(7)
                        .foregroundColor(!showMap ? HanaColor.sakuraBlush : HanaColor.textDim)
                        .background(!showMap ? HanaColor.sakuraInk.opacity(0.5) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .background(Color.black.opacity(0.3))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(HanaColor.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: Map Content
    var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                if let loc = locationService.userLocation {
                    UserAnnotation()
                }
                ForEach(filtered) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        SpotMapMarker(spot: spot) {
                            selectedSpot = spot
                            showingDetail = true
                        }
                    }
                }
            }
            .mapStyle(isHybridMap
                ? .hybrid(elevation: .realistic)
                : .standard(elevation: .realistic, showsTraffic: false)
            )
            .mapControls {
                MapCompass()
                MapScaleView()
            }

            // Map bottom controls
            HStack(spacing: 10) {
                mapControlBtn(icon: "location.fill") { locationService.requestLocation() }
                mapControlBtn(icon: "globe") {
                    withAnimation {
                        isHybridMap.toggle()
                    }
                }
                mapControlBtn(icon: "arrow.counterclockwise") {
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 35.86, longitude: 104.19),
                            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
                        ))
                    }
                }
                Spacer()
                Button {
                    withAnimation { showMap = false }
                } label: {
                    Text("查看列表 →")
                        .font(HanaFont.body(12, weight: .semibold))
                        .foregroundColor(HanaColor.sakuraBlush)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .hanaGlass(cornerRadius: HanaRadius.pill)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    @ViewBuilder
    private func mapControlBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(HanaColor.textPrimary)
                .frame(width: 40, height: 40)
                .hanaGlass(cornerRadius: HanaRadius.sm)
        }
        .buttonStyle(PetalButtonStyle())
    }

    // MARK: List Content
    var spotListContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if dataService.isLoading {
                    ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
                } else {
                    ForEach(filtered) { spot in
                        SpotListCard(spot: spot) {
                            selectedSpot = spot
                            showingDetail = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable { dataService.refresh() }
    }
}

// MARK: - Map Marker
struct SpotMapMarker: View {
    let spot: CherrySpot
    let onTap: () -> Void
    @State private var pulsing = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Pulse ring for full bloom
                if spot.status == .fullBloom {
                    Circle()
                        .stroke(spot.status.color.opacity(0.3), lineWidth: 2)
                        .frame(width: pulsing ? 52 : 40, height: pulsing ? 52 : 40)
                        .opacity(pulsing ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.5).repeatForever(), value: pulsing)
                }
                // Marker body
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: spot.status.gradientColors,
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                        .shadow(color: spot.status.color.opacity(0.5), radius: 6, x: 0, y: 2)
                    Text(spot.status.emoji)
                        .font(.system(size: 16))
                }
            }
        }
        .buttonStyle(PetalButtonStyle())
        .onAppear { pulsing = true }
    }
}

// MARK: - Spot List Card
struct SpotListCard: View {
    let spot: CherrySpot
    let onTap: () -> Void
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spot.name)
                            .font(HanaFont.serif(15, weight: .semibold))
                            .foregroundColor(HanaColor.sakuraPale)
                        Text("\(spot.region) · \(spot.province)")
                            .font(HanaFont.mono(9))
                            .foregroundColor(HanaColor.textDim)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        StatusPillView(status: spot.status, compact: true)
                        FavoriteButton(isFavorite: spot.isFavorite) {
                            dataService.toggleFavorite(id: spot.id)
                        }
                    }
                }

                // Bloom bar
                HStack(spacing: 8) {
                    BloomBarView(percent: spot.bloomPercent, status: spot.status)
                    Text("\(spot.bloomPercent)%")
                        .font(HanaFont.mono(10))
                        .foregroundColor(HanaColor.textDim)
                        .frame(width: 30, alignment: .trailing)
                }

                // Meta row
                HStack(spacing: 12) {
                    Label("开花 \(spot.firstBloomDate.dropFirst(5))", systemImage: "")
                    Label("满开 \(spot.fullBloomDate.dropFirst(5))", systemImage: "")
                    Spacer()
                    Text("\(spot.weatherIcon) \(String(format: "%.0f", spot.temperature))°C")
                }
                .font(HanaFont.mono(9))
                .foregroundColor(HanaColor.textMuted)

                // Update time
                HStack {
                    Circle().fill(HanaColor.emerald).frame(width: 5, height: 5)
                    Text("\(spot.lastUpdatedMinutes) 分钟前更新")
                        .font(HanaFont.mono(9))
                        .foregroundColor(HanaColor.textDim)
                    Spacer()
                    if let dist = LocationService.shared.distance(to: spot) {
                        Text(String(format: "📍 %.0f km", dist))
                            .font(HanaFont.mono(9))
                            .foregroundColor(HanaColor.textDim)
                    }
                }
            }
        }
        .buttonStyle(PetalButtonStyle())
        .hanaCard()
    }
}

#Preview {
    MapView()
        .environmentObject(DataService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(OfflineCacheService.shared)
}
