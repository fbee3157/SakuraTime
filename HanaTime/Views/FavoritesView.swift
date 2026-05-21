import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedSpot: CherrySpot?
    @State private var showDetail = false

    private var favorites: [CherrySpot] {
        dataService.spots.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HanaColor.night0.ignoresSafeArea()
                Group {
                    if favorites.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(favorites) { spot in
                                    SpotListCard(spot: spot) {
                                        selectedSpot = spot
                                        showDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showDetail) {
            if let spot = selectedSpot {
                SpotDetailView(spot: spot)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Text("🌸")
                .font(.system(size: 64))
                .opacity(0.4)
            Text("还没有收藏的地点")
                .font(HanaFont.serif(18, weight: .semibold))
                .foregroundColor(HanaColor.textMuted)
            Text("在地图或前线页面点击 ♡\n即可收藏您喜欢的观樱地点")
                .font(HanaFont.body(13))
                .foregroundColor(HanaColor.textDim)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
