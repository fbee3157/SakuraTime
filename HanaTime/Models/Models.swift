import Foundation
import CoreLocation
import SwiftUI

// MARK: - Bloom Status
enum BloomStatus: String, CaseIterable, Codable {
    case notYet    = "not_yet"
    case budding   = "budding"
    case opening   = "opening"
    case blooming  = "blooming"
    case fullBloom = "full_bloom"
    case falling   = "falling"
    case ended     = "ended"

    var label: String {
        switch self {
        case .notYet:    return "未开花"
        case .budding:   return "花芽期"
        case .opening:   return "开花中"
        case .blooming:  return "开花"
        case .fullBloom: return "満　開"
        case .falling:   return "散樱中"
        case .ended:     return "已结束"
        }
    }

    var emoji: String {
        switch self {
        case .notYet:    return "⬜"
        case .budding:   return "🟡"
        case .opening:   return "🟠"
        case .blooming:  return "🌸"
        case .fullBloom: return "🌺"
        case .falling:   return "🍃"
        case .ended:     return "⬛"
        }
    }

    var color: Color {
        switch self {
        case .notYet:    return Color(hex: "#666688")
        case .budding:   return Color(hex: "#d4a853")
        case .opening:   return Color(hex: "#e07830")
        case .blooming:  return Color(hex: "#e87896")
        case .fullBloom: return Color(hex: "#c94e78")
        case .falling:   return Color(hex: "#6ec5e0")
        case .ended:     return Color(hex: "#444444")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fullBloom: return [Color(hex: "#c94e78"), Color(hex: "#e8789a")]
        case .blooming:  return [Color(hex: "#e87896"), Color(hex: "#f4b8c8")]
        case .opening:   return [Color(hex: "#e07830"), Color(hex: "#e8a040")]
        case .budding:   return [Color(hex: "#c8a020"), Color(hex: "#d4a853")]
        case .falling:   return [Color(hex: "#4a9ab0"), Color(hex: "#6ec5e0")]
        case .notYet:    return [Color(hex: "#444466"), Color(hex: "#666688")]
        case .ended:     return [Color(hex: "#333333"), Color(hex: "#555555")]
        }
    }
}

// MARK: - Viewing Advice
enum ViewingAdvice: String, Codable {
    case excellent = "绝佳"
    case good      = "良好"
    case fair      = "一般"
    case poor      = "不宜"

    var color: Color {
        switch self {
        case .excellent: return Color(hex: "#3db87a")
        case .good:      return Color(hex: "#6ec5e0")
        case .fair:      return Color(hex: "#d4a853")
        case .poor:      return Color(hex: "#e87878")
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "sun.max.fill"
        case .good:      return "cloud.sun.fill"
        case .fair:      return "cloud.fill"
        case .poor:      return "cloud.rain.fill"
        }
    }
}

// MARK: - Daily Weather
struct DailyWeather: Identifiable, Codable {
    let id: UUID
    var day: String
    var icon: String
    var tempHigh: Int
    var tempLow: Int
    var precipProb: Int
    var windSpeed: Double
    var advice: ViewingAdvice

    init(day: String, icon: String, tempHigh: Int, tempLow: Int,
         precipProb: Int, windSpeed: Double, advice: ViewingAdvice) {
        self.id = UUID()
        self.day = day
        self.icon = icon
        self.tempHigh = tempHigh
        self.tempLow = tempLow
        self.precipProb = precipProb
        self.windSpeed = windSpeed
        self.advice = advice
    }
}

// MARK: - Cherry Spot
struct CherrySpot: Identifiable, Codable {
    let id: String
    var name: String
    var nameEn: String
    var region: String
    var province: String
    var latitude: Double
    var longitude: Double
    var altitude: Int
    var treeCount: Int
    var variety: String
    var status: BloomStatus
    var bloomPercent: Int
    var temperature: Double
    var humidity: Int
    var weatherIcon: String
    var firstBloomDate: String
    var fullBloomDate: String
    var endBloomDate: String
    var confidence: Double
    var description: String
    var bestPeriod: String
    var bestHours: String
    var access: String
    var tips: String
    var weekly: [DailyWeather]
    var tags: [String]
    var rating: Double
    var imageURL: String?
    var isFavorite: Bool
    var lastUpdatedMinutes: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var bloomDuration: Int {
        guard let start = parseDate(firstBloomDate),
              let end   = parseDate(endBloomDate) else { return 18 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 18
    }

    private func parseDate(_ str: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: str)
    }
}

// MARK: - Region
struct Region: Identifiable {
    let id = UUID()
    var name: String
    var code: String
}

let allRegions: [Region] = [
    Region(name: "全国", code: "all"),
    Region(name: "华北", code: "华北"),
    Region(name: "东北", code: "东北"),
    Region(name: "华东", code: "华东"),
    Region(name: "华中", code: "华中"),
    Region(name: "华南", code: "华南"),
    Region(name: "西南", code: "西南"),
    Region(name: "西北", code: "西北"),
]

// MARK: - Probability Point
struct ProbabilityPoint: Identifiable {
    let id = UUID()
    var dayOffset: Int
    var probability: Double
    var bloomPercent: Double
    var dateLabel: String
}

// MARK: - Offline Cache
struct OfflineCache: Identifiable, Codable {
    let id: UUID
    var name: String
    var regionCode: String
    var sizeMB: Double
    var zoomLevel: Int
    var cachedDate: Date
    var centerLat: Double
    var centerLng: Double

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: cachedDate)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255)
    }
}
