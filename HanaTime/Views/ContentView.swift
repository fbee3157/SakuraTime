import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            HanaColor.night0.ignoresSafeArea()

            // Petal particles (subtle background layer)
            PetalCanvasView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .opacity(0.35)

            // Tab Content
            TabView(selection: $selectedTab) {
                MapView()
                    .tag(0)
                FrontlineView()
                    .tag(1)
                FavoritesView()
                    .tag(2)
                OfflineView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            HanaTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar
struct HanaTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("map.fill",          "地图"),
        ("wind",              "前线"),
        ("heart.fill",        "收藏"),
        ("square.and.arrow.down.fill", "离线"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = idx }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == idx {
                                Capsule()
                                    .fill(HanaColor.sakuraInk.opacity(0.6))
                                    .frame(width: 44, height: 28)
                                    .matchedGeometryEffect(id: "tab-bg", in: tabNamespace)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTab == idx ? HanaColor.sakuraBlush : HanaColor.textDim)
                        }
                        Text(tab.label)
                            .font(HanaFont.body(10, weight: selectedTab == idx ? .semibold : .regular))
                            .foregroundColor(selectedTab == idx ? HanaColor.sakuraBlush : HanaColor.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                .buttonStyle(PetalButtonStyle())
            }
        }
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(HanaColor.night0.opacity(0.7))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(HanaColor.border2)
                        .frame(height: 0.5)
                }
        )
    }

    @Namespace private var tabNamespace
}

#Preview {
    ContentView()
        .environmentObject(DataService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(OfflineCacheService.shared)
}
