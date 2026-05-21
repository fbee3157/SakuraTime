import Foundation
import Combine

// MARK: - Data Service
final class DataService: ObservableObject {

    static let shared = DataService()

    @Published var spots: [CherrySpot] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date = Date()

    private var refreshTimer: AnyCancellable?

    private init() {
        spots = Self.seedData()
        scheduleRefresh()
    }

    func refresh() {
        isLoading = true
        // Simulate network refresh with minor data mutation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.lastUpdated = Date()
            // Slightly vary bloom percentages to simulate live data
            self.spots = self.spots.map { spot in
                var s = spot
                let delta = Int.random(in: -2...3)
                s.bloomPercent = min(100, max(0, s.bloomPercent + delta))
                s.lastUpdatedMinutes = Int.random(in: 1...8)
                return s
            }
            self.isLoading = false
        }
    }

    func spot(id: String) -> CherrySpot? {
        spots.first { $0.id == id }
    }

    func filteredSpots(region: String, query: String) -> [CherrySpot] {
        spots.filter { s in
            let regionMatch = region == "all" || s.region == region
            let queryMatch  = query.isEmpty
                || s.name.contains(query)
                || s.province.contains(query)
                || s.nameEn.lowercased().contains(query.lowercased())
            return regionMatch && queryMatch
        }
    }

    func toggleFavorite(id: String) {
        if let i = spots.firstIndex(where: { $0.id == id }) {
            spots[i].isFavorite.toggle()
        }
    }

    // MARK: Probability generation (DTS model approximation)
    func bloomProbabilities(for spot: CherrySpot) -> [ProbabilityPoint] {
        let now = Date()
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return (-3..<20).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: now) ?? now
            let peak = 4.0
            let sigma = 3.5
            let prob = exp(-0.5 * pow((Double(offset) - peak) / sigma, 2)) * 0.9
            let clamped = max(0, min(1, prob))
            return ProbabilityPoint(
                dayOffset: offset,
                probability: clamped,
                bloomPercent: min(100, clamped * 110),
                dateLabel: formatter.string(from: d)
            )
        }
    }

    private func scheduleRefresh() {
        refreshTimer = Timer.publish(every: 45, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    // MARK: - Seed Data
    static func seedData() -> [CherrySpot] {
        let w1: [DailyWeather] = [
            DailyWeather(day:"今天", icon:"☀️", tempHigh:19, tempLow:8,  precipProb:5,  windSpeed:2.2, advice:.excellent),
            DailyWeather(day:"明天", icon:"⛅", tempHigh:17, tempLow:7,  precipProb:15, windSpeed:2.8, advice:.good),
            DailyWeather(day:"后天", icon:"🌧️", tempHigh:12, tempLow:5, precipProb:70, windSpeed:4.5, advice:.poor),
            DailyWeather(day:"周四", icon:"⛅", tempHigh:15, tempLow:6,  precipProb:25, windSpeed:3.0, advice:.fair),
            DailyWeather(day:"周五", icon:"☀️", tempHigh:20, tempLow:9,  precipProb:5,  windSpeed:1.8, advice:.excellent),
            DailyWeather(day:"周六", icon:"☀️", tempHigh:21, tempLow:10, precipProb:5,  windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"周日", icon:"⛅", tempHigh:17, tempLow:8,  precipProb:20, windSpeed:2.5, advice:.good),
        ]
        let w2: [DailyWeather] = [
            DailyWeather(day:"今天", icon:"⛅", tempHigh:17, tempLow:9,  precipProb:20, windSpeed:2.5, advice:.good),
            DailyWeather(day:"明天", icon:"☀️", tempHigh:19, tempLow:10, precipProb:5,  windSpeed:1.8, advice:.excellent),
            DailyWeather(day:"后天", icon:"☀️", tempHigh:20, tempLow:11, precipProb:5,  windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"周四", icon:"🌧️", tempHigh:14, tempLow:8, precipProb:75, windSpeed:5.0, advice:.poor),
            DailyWeather(day:"周五", icon:"⛅", tempHigh:17, tempLow:9,  precipProb:25, windSpeed:2.2, advice:.fair),
            DailyWeather(day:"周六", icon:"☀️", tempHigh:20, tempLow:10, precipProb:5,  windSpeed:1.8, advice:.excellent),
            DailyWeather(day:"周日", icon:"☀️", tempHigh:21, tempLow:11, precipProb:5,  windSpeed:1.5, advice:.excellent),
        ]
        let w3: [DailyWeather] = [
            DailyWeather(day:"今天", icon:"🌤️", tempHigh:20, tempLow:12, precipProb:10, windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"明天", icon:"☀️", tempHigh:22, tempLow:13, precipProb:5,  windSpeed:1.2, advice:.excellent),
            DailyWeather(day:"后天", icon:"⛅", tempHigh:19, tempLow:11, precipProb:20, windSpeed:2.0, advice:.good),
            DailyWeather(day:"周四", icon:"🌧️", tempHigh:16, tempLow:10, precipProb:65, windSpeed:3.5, advice:.poor),
            DailyWeather(day:"周五", icon:"⛅", tempHigh:18, tempLow:11, precipProb:25, windSpeed:2.0, advice:.fair),
            DailyWeather(day:"周六", icon:"☀️", tempHigh:22, tempLow:12, precipProb:5,  windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"周日", icon:"☀️", tempHigh:23, tempLow:13, precipProb:5,  windSpeed:1.8, advice:.excellent),
        ]
        let wSouth: [DailyWeather] = [
            DailyWeather(day:"今天", icon:"☀️", tempHigh:25, tempLow:18, precipProb:5,  windSpeed:2.0, advice:.excellent),
            DailyWeather(day:"明天", icon:"⛅", tempHigh:23, tempLow:17, precipProb:20, windSpeed:2.8, advice:.good),
            DailyWeather(day:"后天", icon:"🌧️", tempHigh:20, tempLow:16, precipProb:70, windSpeed:4.5, advice:.poor),
            DailyWeather(day:"周四", icon:"⛅", tempHigh:22, tempLow:16, precipProb:30, windSpeed:3.0, advice:.fair),
            DailyWeather(day:"周五", icon:"☀️", tempHigh:26, tempLow:18, precipProb:5,  windSpeed:1.8, advice:.excellent),
            DailyWeather(day:"周六", icon:"☀️", tempHigh:27, tempLow:19, precipProb:5,  windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"周日", icon:"⛅", tempHigh:24, tempLow:17, precipProb:20, windSpeed:2.2, advice:.good),
        ]
        let wNE: [DailyWeather] = [
            DailyWeather(day:"今天", icon:"🌨️", tempHigh:5,  tempLow:-3, precipProb:55, windSpeed:5.0, advice:.poor),
            DailyWeather(day:"明天", icon:"⛅", tempHigh:8,  tempLow:0,  precipProb:20, windSpeed:3.0, advice:.fair),
            DailyWeather(day:"后天", icon:"☀️", tempHigh:12, tempLow:2,  precipProb:5,  windSpeed:2.0, advice:.excellent),
            DailyWeather(day:"周四", icon:"☀️", tempHigh:13, tempLow:3,  precipProb:5,  windSpeed:1.8, advice:.excellent),
            DailyWeather(day:"周五", icon:"⛅", tempHigh:10, tempLow:1,  precipProb:20, windSpeed:2.5, advice:.good),
            DailyWeather(day:"周六", icon:"☀️", tempHigh:14, tempLow:4,  precipProb:5,  windSpeed:1.5, advice:.excellent),
            DailyWeather(day:"周日", icon:"🌧️", tempHigh:8,  tempLow:0,  precipProb:65, windSpeed:4.5, advice:.poor),
        ]

        return [
            CherrySpot(id:"s01", name:"颐和园", nameEn:"Summer Palace", region:"华北", province:"北京市",
                       latitude:39.9980, longitude:116.2755, altitude:40, treeCount:3200, variety:"早樱/山樱",
                       status:.fullBloom, bloomPercent:92, temperature:18, humidity:55, weatherIcon:"☀️",
                       firstBloomDate:"2026-03-26", fullBloomDate:"2026-03-30", endBloomDate:"2026-04-10",
                       confidence:0.89,
                       description:"北京最经典赏樱地，昆明湖畔樱花与皇家古建筑相映，春日如画，昆明湖东岸长廊是最佳摄影机位。",
                       bestPeriod:"满开后2–4天（3月31日–4月3日）",
                       bestHours:"早晨7–9时或下午16–18时",
                       access:"地铁4号线「北宫门」步行5分钟",
                       tips:"周末极拥挤，建议工作日前往。昆明湖东岸的长廊是拍摄最佳机位。",
                       weekly:w1, tags:["皇家园林","夜樱","湖景"], rating:4.8,
                       imageURL:"https://images.unsplash.com/photo-1603285483048-7c4f7a76e4a5?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:3),

            CherrySpot(id:"s02", name:"杭州西湖苏堤", nameEn:"West Lake Sudi", region:"华东", province:"浙江省",
                       latitude:30.2440, longitude:120.1455, altitude:15, treeCount:2100, variety:"染井吉野",
                       status:.blooming, bloomPercent:74, temperature:16, humidity:60, weatherIcon:"⛅",
                       firstBloomDate:"2026-03-28", fullBloomDate:"2026-04-03", endBloomDate:"2026-04-14",
                       confidence:0.86,
                       description:"西湖苏堤春晓，烟雨江南，两岸染井吉野夹道盛开，船行其中如穿越花廊，是江南最浪漫的赏樱体验。",
                       bestPeriod:"满开后3–5天（4月3日–4月7日）",
                       bestHours:"清晨6–8时或傍晚17–19时",
                       access:"公交至「岳庙」站或骑共享单车",
                       tips:"清明前后是花期高峰，苏堤和白堤均宜。游船体验更佳。",
                       weekly:w2, tags:["湖景","苏堤","江南"], rating:4.9,
                       imageURL:"https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=800&q=80",
                       isFavorite:true, lastUpdatedMinutes:5),

            CherrySpot(id:"s03", name:"武汉东湖樱园", nameEn:"East Lake Cherry Garden", region:"华中", province:"湖北省",
                       latitude:30.5600, longitude:114.4035, altitude:21, treeCount:2800, variety:"河津樱",
                       status:.opening, bloomPercent:38, temperature:14, humidity:68, weatherIcon:"🌦️",
                       firstBloomDate:"2026-03-31", fullBloomDate:"2026-04-06", endBloomDate:"2026-04-16",
                       confidence:0.82,
                       description:"中国最大赏樱基地之一，日本援植的河津樱与湖面交相辉映，东湖绿道骑行赏花别具一格。",
                       bestPeriod:"满开期4月6日–4月10日",
                       bestHours:"上午9–11时光线充足，花色最艳",
                       access:"地铁8号线「磨山」步行10分钟",
                       tips:"磨山樱花园建议提前预约，东湖绿道骑行可串联多处花景。",
                       weekly:w2, tags:["湖畔","河津樱","踏青"], rating:4.7,
                       imageURL:"https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:7),

            CherrySpot(id:"s04", name:"上海顾村公园", nameEn:"Gucun Park", region:"华东", province:"上海市",
                       latitude:31.3415, longitude:121.4438, altitude:8, treeCount:3600, variety:"枝垂樱",
                       status:.budding, bloomPercent:18, temperature:17, humidity:63, weatherIcon:"☀️",
                       firstBloomDate:"2026-04-02", fullBloomDate:"2026-04-08", endBloomDate:"2026-04-18",
                       confidence:0.80,
                       description:"上海规模最大的樱花主题公园，3600棵多品种樱树分区盛放，每年举办上海樱花节，游客如织。",
                       bestPeriod:"满开后2–4天（4月8日–4月12日）",
                       bestHours:"工作日上午9–12时",
                       access:"地铁7号线「顾村公园」步行3分钟",
                       tips:"建议工作日避峰出行，可在园内野餐。",
                       weekly:w1, tags:["花海","樱花节","家庭游"], rating:4.6,
                       imageURL:"https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:2),

            CherrySpot(id:"s05", name:"南京玄武湖", nameEn:"Xuanwu Lake", region:"华东", province:"江苏省",
                       latitude:32.0505, longitude:118.8038, altitude:23, treeCount:1700, variety:"染井吉野",
                       status:.falling, bloomPercent:42, temperature:15, humidity:65, weatherIcon:"⛅",
                       firstBloomDate:"2026-03-29", fullBloomDate:"2026-04-04", endBloomDate:"2026-04-14",
                       confidence:0.85,
                       description:"玄武湖进入落花期，湖畔步道落英缤纷，近处明城墙与远处紫金山构成南京独有的壮阔背景。",
                       bestPeriod:"现已散花期，花瓣漂浮水面如花毯",
                       bestHours:"早晨7–9时与朝雾相映",
                       access:"地铁3号线「玄武门」步行5分钟",
                       tips:"散花期与明城墙同框拍摄是南京独特风景。",
                       weekly:w2, tags:["散花","明城墙","湖景"], rating:4.7,
                       imageURL:"https://images.unsplash.com/photo-1516912481808-3406841bd33c?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:10),

            CherrySpot(id:"s06", name:"广州越秀公园", nameEn:"Yuexiu Park", region:"华南", province:"广东省",
                       latitude:23.1288, longitude:113.2708, altitude:45, treeCount:1400, variety:"寒绯樱",
                       status:.blooming, bloomPercent:60, temperature:24, humidity:72, weatherIcon:"☀️",
                       firstBloomDate:"2026-03-24", fullBloomDate:"2026-03-30", endBloomDate:"2026-04-10",
                       confidence:0.88,
                       description:"广州花期最早，越秀公园早樱率先盛开，五羊雕像旁的花景是广州春天的城市名片。",
                       bestPeriod:"满开期3月30日–4月3日",
                       bestHours:"早晨7–9时或傍晚17–19时",
                       access:"地铁2号线「越秀公园」A出口步行即达",
                       tips:"广州花期短约8–10天，需抓紧时机。公园免费开放。",
                       weekly:wSouth, tags:["城市公园","早花","五羊"], rating:4.6,
                       imageURL:"https://images.unsplash.com/photo-1555217851-6141535bd771?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:4),

            CherrySpot(id:"s07", name:"成都人民公园", nameEn:"People's Park Chengdu", region:"西南", province:"四川省",
                       latitude:30.6660, longitude:104.0650, altitude:500, treeCount:1200, variety:"八重樱",
                       status:.blooming, bloomPercent:68, temperature:19, humidity:70, weatherIcon:"🌤️",
                       firstBloomDate:"2026-03-25", fullBloomDate:"2026-03-31", endBloomDate:"2026-04-11",
                       confidence:0.84,
                       description:"成都市中心赏樱与茶文化圣地，人民公园樱花配上成都特有的盖碗茶馆氛围，格外悠闲惬意。",
                       bestPeriod:"满开期3月31日–4月4日",
                       bestHours:"下午14–17时品盖碗茶赏樱，最具成都风情",
                       access:"地铁4号线「人民公园」步行即达",
                       tips:"鹤鸣茶社是坐在花树下喝盖碗茶的绝佳地点，无需预约。",
                       weekly:w3, tags:["都市公园","茶文化","休闲"], rating:4.5,
                       imageURL:"https://images.unsplash.com/photo-1598127968497-28e84649b6e3?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:6),

            CherrySpot(id:"s08", name:"西安兴庆宫公园", nameEn:"Xingqinggong Park", region:"西北", province:"陕西省",
                       latitude:34.2602, longitude:108.9779, altitude:395, treeCount:850, variety:"大山樱",
                       status:.opening, bloomPercent:28, temperature:15, humidity:50, weatherIcon:"🌤️",
                       firstBloomDate:"2026-04-01", fullBloomDate:"2026-04-07", endBloomDate:"2026-04-17",
                       confidence:0.81,
                       description:"唐代皇家园林遗址上的赏樱胜地，大山樱花开于千年古城之中，历史与春色交融，大唐遗韵犹存。",
                       bestPeriod:"满开期4月7日–4月11日",
                       bestHours:"下午14–17时斜阳照射，古城砖与樱花对比强烈",
                       access:"地铁1号线「兴庆宫公园」步行3分钟",
                       tips:"可联合游览古城墙，骑自行车环城赏春是西安特色体验。",
                       weekly:w1, tags:["历史古迹","大山樱","唐风"], rating:4.5,
                       imageURL:"https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:8),

            CherrySpot(id:"s09", name:"长春农博园", nameEn:"Agri Expo Garden", region:"东北", province:"吉林省",
                       latitude:43.8214, longitude:125.3540, altitude:220, treeCount:950, variety:"吉野樱",
                       status:.notYet, bloomPercent:8, temperature:7, humidity:58, weatherIcon:"🌨️",
                       firstBloomDate:"2026-04-18", fullBloomDate:"2026-04-25", endBloomDate:"2026-05-05",
                       confidence:0.76,
                       description:"东北春季赏樱代表地，花期较晚，冰雪初融与樱花盛开形成独特对比，别有东北豪情。",
                       bestPeriod:"满开期4月25日–4月30日",
                       bestHours:"上午10时–下午15时",
                       access:"乘公交至「农博园」",
                       tips:"4月下旬东北约10–15°C，建议携带外套。",
                       weekly:wNE, tags:["东北风情","晚花","冰雪"], rating:4.3,
                       imageURL:"https://images.unsplash.com/photo-1531746790731-6c087fecd65a?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:12),

            CherrySpot(id:"s10", name:"深圳仙湖植物园", nameEn:"Xianhu Botanical Garden", region:"华南", province:"广东省",
                       latitude:22.5630, longitude:114.2220, altitude:80, treeCount:800, variety:"寒绯樱",
                       status:.blooming, bloomPercent:55, temperature:22, humidity:75, weatherIcon:"🌤️",
                       firstBloomDate:"2026-03-22", fullBloomDate:"2026-03-28", endBloomDate:"2026-04-07",
                       confidence:0.85,
                       description:"深圳仙湖植物园的寒绯樱花期较早，热带气候下的樱花别具特色，可与多种热带植物同赏。",
                       bestPeriod:"满开期3月28日–4月1日",
                       bestHours:"上午9–11时光线最佳",
                       access:"乘公交至仙湖植物园正门",
                       tips:"可联合游览弘法寺，寒绯樱花色偏深红，与其他品种有明显差异。",
                       weekly:wSouth, tags:["热带","寒绯樱","植物园"], rating:4.5,
                       imageURL:"https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:9),

            CherrySpot(id:"s11", name:"苏州木渎古镇", nameEn:"Mudu Ancient Town", region:"华东", province:"江苏省",
                       latitude:31.1116, longitude:120.8789, altitude:8, treeCount:620, variety:"垂枝樱",
                       status:.fullBloom, bloomPercent:88, temperature:16, humidity:62, weatherIcon:"☀️",
                       firstBloomDate:"2026-03-27", fullBloomDate:"2026-04-02", endBloomDate:"2026-04-12",
                       confidence:0.90,
                       description:"江南水乡古镇，垂枝樱花掩映古桥流水，白墙黛瓦间落樱纷纷，最具诗意的江南赏樱地。",
                       bestPeriod:"满开期4月2日–4月5日清晨",
                       bestHours:"早晨6:30–8:30时游客极少，晨光最美",
                       access:"乘公交或自驾至木渎古镇景区",
                       tips:"垂枝樱花期仅7–9天，需把握时机。",
                       weekly:w2, tags:["古镇","垂枝樱","江南水乡"], rating:4.9,
                       imageURL:"https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800&q=80",
                       isFavorite:true, lastUpdatedMinutes:1),

            CherrySpot(id:"s12", name:"重庆南山植物园", nameEn:"Nanshan Botanical Garden", region:"西南", province:"重庆市",
                       latitude:29.5132, longitude:106.5891, altitude:680, treeCount:780, variety:"染井吉野",
                       status:.blooming, bloomPercent:55, temperature:18, humidity:74, weatherIcon:"⛅",
                       firstBloomDate:"2026-03-28", fullBloomDate:"2026-04-03", endBloomDate:"2026-04-14",
                       confidence:0.83,
                       description:"重庆南山植物园海拔680米，登顶俯瞰山城全景，樱花与江景城市融为一体，独具山城魅力。",
                       bestPeriod:"满开期4月3日–4月7日晴天登顶最美",
                       bestHours:"下午15–18时斜阳照射，山城与花海金光璀璨",
                       access:"乘公交或网约车至南山植物园",
                       tips:"重庆多云，提前查天气，选晴天前往。",
                       weekly:w3, tags:["山城","俯瞰江景","植物园"], rating:4.7,
                       imageURL:"https://images.unsplash.com/photo-1624396580440-5bddcef35578?w=800&q=80",
                       isFavorite:false, lastUpdatedMinutes:5),
        ]
    }
}
