# 🌸 花时 HanaTime — iOS 樱花开放预测 App

> 中国版实时樱花开放预测系统 iOS 应用，使用 SwiftUI + MapKit 构建，面向 App Store 上线。

---

## 📱 应用功能

### 🗾 地图 Tab
- **原生 Apple MapKit 地图**（iOS 17 新 API）
- **自定义花型标记**：颜色随开放状态实时变化，满开时有脉冲动画
- **地图/列表双视图**切换
- **实时定位**：自动逆地理编码显示城市名 + 经纬度
- **地图样式切换**：标准地图 ↔ 卫星混合图

### 🌊 前线 Tab
- **全国樱花前线**追踪，4 项统计数字实时更新
- **省份筛选**，动画切换
- **照片卡片网格**：异步加载真实景点图片
- **点击卡片**直接进入详情

### ❤️ 收藏 Tab
- 跨 Tab 收藏同步，心形按钮弹跳动画
- 空状态引导页

### 📦 离线 Tab
- **区域下载选择器**（8 大区域，4 个缩放级别）
- **下载进度 Overlay**
- **导出功能**：生成 JSON 数据包，通过系统分享导出至文件/AirDrop/邮件等
- **缓存管理**：查看大小、删除、单独导出

### 详情页
- **开花圆环进度条**（SwiftUI Charts 动画）
- **完整花期时间线**（开花 → 満開 → 散花）
- **最佳赏樱时间**（最佳时期、每日时段、交通、贴士）
- **7天逐日天气**（赏花指数：绝佳/良好/一般/不宜）
- **30天概率预测图**（SwiftUI Charts 面积图）
- **系统分享**（文字摘要）

---

## 🏗 项目结构

```
HanaTime/
├── HanaTime.xcodeproj/
│   └── project.pbxproj          ← Xcode 项目文件
└── HanaTime/
    ├── HanaTimeApp.swift         ← @main 入口
    ├── Info.plist                ← 权限声明（位置权限）
    ├── Assets.xcassets/
    ├── Models/
    │   └── Models.swift          ← CherrySpot, BloomStatus, DailyWeather 等
    ├── Services/
    │   ├── DataService.swift     ← 数据 + DTS 预测算法
    │   ├── LocationService.swift ← 定位 + 逆地理编码
    │   └── OfflineCacheService.swift ← 缓存管理 + 导出
    ├── Components/
    │   ├── DesignTokens.swift    ← 颜色、字体、间距、组件修饰符
    │   └── Components.swift     ← BloomRing, StatusPill, WeatherCard 等
    └── Views/
        ├── ContentView.swift     ← TabView + 自定义底部导航
        ├── MapView.swift         ← 地图 + 列表
        ├── SpotDetailView.swift  ← 景点详情 Sheet
        ├── FrontlineView.swift   ← 全国前线网格
        ├── FavoritesView.swift   ← 收藏列表
        └── OfflineView.swift     ← 离线管理
```

---

## 🚀 本地开发

### 环境要求
| 工具 | 版本 |
|------|------|
| macOS | 14.0 (Sonoma) 或更高 |
| Xcode | 15.0 或更高 |
| iOS 部署目标 | iOS 17.0+ |
| Swift | 5.9+ |

### 启动步骤

```bash
# 1. 克隆 / 解压项目
cd HanaTime

# 2. 用 Xcode 打开
open HanaTime.xcodeproj

# 3. 选择模拟器或真机（需配置 Bundle ID 和开发者账号）
# 4. ⌘+R 运行
```

### Bundle ID 配置
打开项目 → HanaTime Target → Signing & Capabilities
- Bundle Identifier: `com.yourname.HanaTime`
- Team: 选择您的 Apple 开发者账号

---

## 📐 架构

```
App Layer      HanaTimeApp (@main, environmentObjects)
       ↓
View Layer     ContentView → MapView / FrontlineView / FavoritesView / OfflineView
       ↓
Sheet Layer    SpotDetailView (NavigationStack)
       ↓
Service Layer  DataService / LocationService / OfflineCacheService
       ↓
Model Layer    CherrySpot / BloomStatus / DailyWeather / OfflineCache
```

### 状态管理
- `DataService.shared` — `@EnvironmentObject`，全局数据源
- `LocationService.shared` — `@EnvironmentObject`，定位状态
- `OfflineCacheService.shared` — `@EnvironmentObject`，缓存管理

---

## 🎨 设计系统

### 颜色
| Token | 颜色 | 用途 |
|-------|------|------|
| `sakuraMid` | #e8789a | 主强调色 |
| `sakuraDeep` | #c94e78 | 满开状态 |
| `night0` | #0d0509 | 背景底色 |
| `emerald` | #3db87a | 成功/绝佳 |
| `sky` | #6ec5e0 | 良好/散花 |
| `gold` | #d4a853 | 花芽期 |

### 字体
- **衬线体**（标题、名称）: `.system(design: .serif)`
- **等宽体**（数据、日期）: `.system(design: .monospaced)`
- **正文**（说明、标签）: `.system()`

---

## 📊 数据

当前内置 12 个中国主要观樱地点（可扩展至数据库）：

| 地点 | 省份 | 品种 | 状态 |
|------|------|------|------|
| 颐和园 | 北京 | 早樱/山樱 | 満開 |
| 杭州西湖苏堤 | 浙江 | 染井吉野 | 开花中 |
| 武汉东湖樱园 | 湖北 | 河津樱 | 开花中 |
| 上海顾村公园 | 上海 | 枝垂樱 | 花芽期 |
| 南京玄武湖 | 江苏 | 染井吉野 | 散樱中 |
| 广州越秀公园 | 广东 | 寒绯樱 | 开花中 |
| 成都人民公园 | 四川 | 八重樱 | 开花中 |
| 西安兴庆宫 | 陕西 | 大山樱 | 开花中 |
| 长春农博园 | 吉林 | 吉野樱 | 未开花 |
| 深圳仙湖植物园 | 广东 | 寒绯樱 | 开花中 |
| 苏州木渎古镇 | 江苏 | 垂枝樱 | 満開 |
| 重庆南山植物园 | 重庆 | 染井吉野 | 开花中 |

---

## 🔌 接入真实 API（上线前）

### 后端 API（Node.js）
```swift
// DataService.swift 中替换 seedData() 为网络请求：
func loadFromAPI() async {
    guard let url = URL(string: "https://api.hanatime.app/spots") else { return }
    let (data, _) = try await URLSession.shared.data(from: url)
    spots = try JSONDecoder().decode([CherrySpot].self, from: data)
}
```

### 天气 API（和风天气 / OpenWeatherMap）
在 `DataService.swift` 的 `refresh()` 中接入真实气象数据。

---

## 📦 App Store 上线准备

- [x] 定位权限 `NSLocationWhenInUseUsageDescription` 已在 Info.plist 配置
- [x] Dark Mode 专属设计（`preferredColorScheme(.dark)`）
- [x] 支持 iPhone + iPad（`UISupportedInterfaceOrientations` 已配置）
- [x] iOS 17+ 最低版本
- [ ] App Icon 1024×1024（在 Assets.xcassets 中添加）
- [ ] App Store 截图（6.7" / 6.1" / iPad）
- [ ] 隐私政策 URL
- [ ] TestFlight 内测

---

## 📜 许可证

MIT License © 2026 花时 HanaTime

---

*「花开堪折直须折，莫待无花空折枝」— 愿每个爱花的人都能赶上最美的那一刻 🌸*
