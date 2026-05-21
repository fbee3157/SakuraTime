import SwiftUI

@main
struct HanaTimeApp: App {
    @StateObject private var dataService    = DataService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var cacheService   = OfflineCacheService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environmentObject(locationService)
                .environmentObject(cacheService)
                .preferredColorScheme(.dark)
        }
    }
}
