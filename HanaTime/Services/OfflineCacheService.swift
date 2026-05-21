import Foundation
import Combine

final class OfflineCacheService: ObservableObject {

    static let shared = OfflineCacheService()

    @Published var cachedAreas: [OfflineCache] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadStatus: String = ""
    @Published var isExporting = false
    @Published var exportProgress: Double = 0

    private let storageKey = "cn_sakura_offline_cache"

    private init() {
        loadFromStorage()
    }

    // MARK: Download simulation
    func downloadArea(name: String, regionCode: String, center: (lat: Double, lng: Double), zoom: Int) {
        isDownloading = true
        downloadProgress = 0
        let steps: [(Double, String)] = [
            (0.15, "正在计算瓦片范围…"),
            (0.35, "正在建立索引…"),
            (0.60, "正在缓存地图瓦片…"),
            (0.80, "正在下载樱花数据…"),
            (0.95, "正在压缩存储…"),
            (1.00, "下载完成！"),
        ]
        var stepIdx = 0
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] timer in
            guard let self, stepIdx < steps.count else { return }
            let (pct, msg) = steps[stepIdx]
            self.downloadProgress = pct
            self.downloadStatus = msg
            stepIdx += 1
            if stepIdx == steps.count {
                timer.invalidate()
                let sizeMB = self.estimatedSize(zoom: zoom)
                let area = OfflineCache(id: UUID(), name: name, regionCode: regionCode,
                                       sizeMB: sizeMB, zoomLevel: zoom,
                                       cachedDate: Date(), centerLat: center.lat, centerLng: center.lng)
                self.cachedAreas.append(area)
                self.saveToStorage()
                self.isDownloading = false
            }
        }
    }

    func estimatedSize(zoom: Int) -> Double {
        let tileCount = pow(4.0, Double(zoom - 10 + 1)) * 16
        return (tileCount * 15 / 1024).rounded(toPlaces: 1)
    }

    func delete(id: UUID) {
        cachedAreas.removeAll { $0.id == id }
        saveToStorage()
    }

    // MARK: Export
    func exportAll(spots: [CherrySpot], completion: @escaping (URL?) -> Void) {
        isExporting = true
        exportProgress = 0
        let steps: [(Double, String)] = [
            (0.10, "正在读取缓存索引…"),
            (0.30, "正在打包地图瓦片…"),
            (0.50, "正在导出樱花预测数据…"),
            (0.70, "正在整合历史记录…"),
            (0.85, "正在压缩数据包…"),
            (0.95, "正在校验导出文件…"),
            (1.00, "导出完成！"),
        ]
        var stepIdx = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self, stepIdx < steps.count else { return }
            let (pct, _) = steps[stepIdx]
            self.exportProgress = pct
            stepIdx += 1
            if stepIdx == steps.count {
                timer.invalidate()
                let exportData = self.buildExportPayload(spots: spots)
                let url = self.writeExportFile(data: exportData)
                self.isExporting = false
                completion(url)
            }
        }
    }

    func exportSingle(cache: OfflineCache, spots: [CherrySpot], completion: @escaping (URL?) -> Void) {
        let exportData = buildExportPayload(spots: spots, areas: [cache])
        let url = writeExportFile(data: exportData)
        completion(url)
    }

    // MARK: Private helpers
    private func buildExportPayload(spots: [CherrySpot], areas: [OfflineCache]? = nil) -> Data {
        struct ExportSpot: Codable {
            let id, name, region, province: String
            let lat, lng: Double
            let status: String
            let bloomPercent: Int
            let fFirst, fFull, fEnd: String
        }
        struct ExportPayload: Codable {
            let exportTime: String
            let version: String
            let areas: [OfflineCache]
            let spots: [ExportSpot]
        }
        let formatter = ISO8601DateFormatter()
        let payload = ExportPayload(
            exportTime: formatter.string(from: Date()),
            version: "1.0",
            areas: areas ?? cachedAreas,
            spots: spots.map { s in
                ExportSpot(id: s.id, name: s.name, region: s.region, province: s.province,
                           lat: s.latitude, lng: s.longitude,
                           status: s.status.rawValue, bloomPercent: s.bloomPercent,
                           fFirst: s.firstBloomDate, fFull: s.fullBloomDate, fEnd: s.endBloomDate)
            }
        )
        return (try? JSONEncoder().encode(payload)) ?? Data()
    }

    private func writeExportFile(data: Data) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "sakura-offline-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return url
    }

    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(cachedAreas) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let areas = try? JSONDecoder().decode([OfflineCache].self, from: data) else { return }
        cachedAreas = areas
    }

    var totalCacheSizeMB: Double {
        cachedAreas.reduce(0) { $0 + $1.sizeMB }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
