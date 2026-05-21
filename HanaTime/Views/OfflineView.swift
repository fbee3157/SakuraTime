import SwiftUI

struct OfflineView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var cacheService: OfflineCacheService

    @State private var selectedRegions = Set<String>()
    @State private var selectedZoom    = 12
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false

    private let regions = [
        ("华北", "华北", 39.9, 116.4), ("东北", "东北", 43.8, 125.3),
        ("华东", "华东", 31.5, 120.5), ("华中", "华中", 30.6, 112.5),
        ("华南", "华南", 23.1, 113.3), ("西南", "西南", 30.7, 104.1),
        ("西北", "西北", 34.3, 108.9), ("港澳台", "港澳台", 22.3, 114.2),
    ]

    private var selectedTotalMB: Double {
        regions.filter { selectedRegions.contains($0.0) }
            .reduce(0.0) { $0 + Double($1.0 == "华北" ? 42 : $1.0 == "东北" ? 38 : 30) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HanaColor.night0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Storage overview
                        storageCard
                        // Region downloader
                        regionDownloader
                        // Cached areas
                        cachedAreasSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("离线地图管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !cacheService.cachedAreas.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            exportAll()
                        } label: {
                            Label("导出全部", systemImage: "square.and.arrow.up")
                                .font(HanaFont.body(12))
                                .foregroundColor(HanaColor.emerald)
                        }
                    }
                }
            }
        }
        .overlay {
            if cacheService.isDownloading { downloadOverlay }
            if cacheService.isExporting   { exportOverlay   }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: Storage Card
    var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "存储用量")
            HStack(spacing: 12) {
                // Storage bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [HanaColor.emerald, HanaColor.sky],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * min(1, cacheService.totalCacheSizeMB / 500))
                                .animation(.spring(), value: cacheService.totalCacheSizeMB)
                        }
                    }
                    .frame(height: 8)
                    Text("已用 \(String(format: "%.1f", cacheService.totalCacheSizeMB)) MB / 500 MB")
                        .font(HanaFont.mono(10))
                        .foregroundColor(HanaColor.textMuted)
                }
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(cacheService.cachedAreas.count)")
                        .font(HanaFont.serif(22, weight: .bold))
                        .foregroundColor(HanaColor.sakuraBlush)
                    Text("个区域")
                        .font(HanaFont.body(10))
                        .foregroundColor(HanaColor.textDim)
                }
            }
        }
        .hanaCard()
    }

    // MARK: Region Downloader
    var regionDownloader: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "下载新区域")

            // Zoom level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("缩放级别")
                        .font(HanaFont.body(12))
                        .foregroundColor(HanaColor.textMuted)
                    Spacer()
                    Text("预计 \(String(format: "%.1f", cacheService.estimatedSize(zoom: selectedZoom))) MB")
                        .font(HanaFont.mono(10))
                        .foregroundColor(HanaColor.textDim)
                }
                HStack(spacing: 8) {
                    ForEach([10, 12, 14, 16], id: \.self) { z in
                        Button {
                            withAnimation { selectedZoom = z }
                        } label: {
                            Text("z\(z)")
                                .font(HanaFont.mono(11, weight: selectedZoom == z ? .bold : .regular))
                                .foregroundColor(selectedZoom == z ? HanaColor.sakuraPale : HanaColor.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: HanaRadius.sm).fill(
                                        selectedZoom == z
                                        ? HanaColor.sakuraDeep.opacity(0.3)
                                        : Color.white.opacity(0.04)
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: HanaRadius.sm).strokeBorder(
                                        selectedZoom == z ? HanaColor.sakuraMid.opacity(0.5) : HanaColor.border,
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(PetalButtonStyle())
                    }
                }
            }

            // Region grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(regions, id: \.0) { (name, code, lat, lng) in
                    let isSelected = selectedRegions.contains(name)
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            if isSelected { selectedRegions.remove(name) }
                            else { selectedRegions.insert(name) }
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(name)
                                .font(HanaFont.body(12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? HanaColor.sakuraPale : HanaColor.textMuted)
                            Text("≈\(regionSize(name)) MB")
                                .font(HanaFont.mono(8))
                                .foregroundColor(isSelected ? HanaColor.textMuted : HanaColor.textDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: HanaRadius.sm)
                                .fill(
                                    LinearGradient(
                                        colors: isSelected
                                            ? [HanaColor.sakuraInk.opacity(0.6), HanaColor.sakuraDeep.opacity(0.3)]
                                            : [Color.white.opacity(0.03), Color.white.opacity(0.03)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: HanaRadius.sm).strokeBorder(
                                isSelected ? HanaColor.sakuraMid.opacity(0.6) : HanaColor.border,
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(PetalButtonStyle())
                }
            }

            // Download button row
            HStack(spacing: 10) {
                Button(action: downloadSelected) {
                    Label(
                        selectedRegions.isEmpty ? "选择区域后下载" : "下载 \(selectedRegions.count) 个区域",
                        systemImage: "arrow.down.circle.fill"
                    )
                    .font(HanaFont.body(13, weight: .semibold))
                    .foregroundColor(HanaColor.sakuraPale)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: HanaRadius.lg)
                            .fill(HanaColor.sakuraGradient)
                            .opacity(selectedRegions.isEmpty ? 0.15 : 1.0)
                    )
                }
                .disabled(selectedRegions.isEmpty)
                .buttonStyle(PetalButtonStyle())

                if !selectedRegions.isEmpty {
                    Text("≈\(String(format: "%.0f", selectedTotalMB)) MB")
                        .font(HanaFont.mono(11))
                        .foregroundColor(HanaColor.textMuted)
                }
            }
        }
        .hanaCard()
    }

    // MARK: Cached Areas
    var cachedAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "已缓存区域")
                Spacer()
                if !cacheService.cachedAreas.isEmpty {
                    Button(action: exportAll) {
                        Label("全部导出", systemImage: "square.and.arrow.up")
                            .font(HanaFont.body(11))
                            .foregroundColor(HanaColor.emerald)
                    }
                }
            }

            if cacheService.cachedAreas.isEmpty {
                Text("暂无缓存数据。选择区域后点击下载即可离线使用。")
                    .font(HanaFont.body(13))
                    .foregroundColor(HanaColor.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(cacheService.cachedAreas) { cache in
                    CachedAreaRow(cache: cache,
                        onExport: { exportSingle(cache: cache) },
                        onDelete: { cacheService.delete(id: cache.id) }
                    )
                }
            }
        }
        .hanaCard()
    }

    // MARK: Download Overlay
    var downloadOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .blur(radius: 2)
            VStack(spacing: 20) {
                Text("📥").font(.system(size: 44))
                Text("正在下载离线地图…")
                    .font(HanaFont.serif(16, weight: .semibold))
                    .foregroundColor(HanaColor.sakuraPale)
                Text(cacheService.downloadStatus)
                    .font(HanaFont.mono(11))
                    .foregroundColor(HanaColor.textMuted)
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [HanaColor.sakuraInk, HanaColor.sakuraBlush],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * cacheService.downloadProgress)
                            .animation(.spring(), value: cacheService.downloadProgress)
                    }
                }
                .frame(height: 6)
                Text("\(Int(cacheService.downloadProgress * 100))%")
                    .font(HanaFont.mono(12, weight: .bold))
                    .foregroundColor(HanaColor.sakuraMid)
            }
            .padding(32)
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: HanaRadius.xl)
                    .fill(HanaColor.night1)
                    .overlay(RoundedRectangle(cornerRadius: HanaRadius.xl).strokeBorder(HanaColor.border2, lineWidth: 1))
            )
        }
    }

    // MARK: Export Overlay
    var exportOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("📦").font(.system(size: 44))
                Text("正在导出数据包…")
                    .font(HanaFont.serif(16, weight: .semibold))
                    .foregroundColor(HanaColor.sakuraPale)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [HanaColor.emerald, HanaColor.sky],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * cacheService.exportProgress)
                            .animation(.spring(), value: cacheService.exportProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(32)
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: HanaRadius.xl)
                    .fill(HanaColor.night1)
                    .overlay(RoundedRectangle(cornerRadius: HanaRadius.xl).strokeBorder(HanaColor.border2, lineWidth: 1))
            )
        }
    }

    // MARK: Actions
    private func downloadSelected() {
        let regs = Array(selectedRegions)
        var delay = 0.0
        for name in regs {
            if let r = regions.first(where: { $0.0 == name }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.cacheService.downloadArea(
                        name: "\(name)地区",
                        regionCode: r.1,
                        center: (r.2, r.3),
                        zoom: self.selectedZoom
                    )
                }
                delay += 0.1
            }
        }
        selectedRegions.removeAll()
    }

    private func exportAll() {
        cacheService.exportAll(spots: dataService.spots) { url in
            exportURL = url
            showingShareSheet = url != nil
        }
    }

    private func exportSingle(cache: OfflineCache) {
        cacheService.exportSingle(cache: cache, spots: dataService.spots) { url in
            exportURL = url
            showingShareSheet = url != nil
        }
    }

    private func regionSize(_ name: String) -> Int {
        switch name {
        case "华北": return 42
        case "东北": return 38
        case "华东": return 35
        case "华中": return 32
        case "华南": return 28
        case "西南": return 40
        case "西北": return 34
        case "港澳台": return 22
        default: return 30
        }
    }
}

// MARK: - Cached Area Row
struct CachedAreaRow: View {
    let cache: OfflineCache
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("📦 \(cache.name)")
                        .font(HanaFont.body(13, weight: .semibold))
                        .foregroundColor(HanaColor.textPrimary)
                    Text("缩放 z\(cache.zoomLevel) · \(cache.formattedDate) · \(String(format: "%.1f", cache.sizeMB)) MB")
                        .font(HanaFont.mono(9))
                        .foregroundColor(HanaColor.textDim)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: onExport) {
                        Label("导出", systemImage: "square.and.arrow.up")
                            .font(HanaFont.body(11))
                            .foregroundColor(HanaColor.emerald)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(HanaColor.emerald.opacity(0.1))
                            .overlay(Capsule().strokeBorder(HanaColor.emerald.opacity(0.3), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#ff8888"))
                            .padding(7)
                            .background(Color.red.opacity(0.08))
                            .overlay(Circle().strokeBorder(Color.red.opacity(0.25), lineWidth: 1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .overlay(RoundedRectangle(cornerRadius: HanaRadius.sm).strokeBorder(HanaColor.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: HanaRadius.sm))
    }
}

#Preview {
    OfflineView()
        .environmentObject(DataService.shared)
        .environmentObject(OfflineCacheService.shared)
}
