# 🐾 毛窩 MaoWo

> 一款介紹全國公立收容所「待認養流浪動物」的 iOS App。資料來自**農業部開放資料平台**，協助使用者瀏覽、搜尋、收藏並進一步聯繫收容所認養。
>
> App 名稱：**毛窩**（繁中）／ **毛窝**（簡中）／ **MaoWo**（英文）。內部專案代號仍為 `StrayPals`。

以 **Swift + UIKit（純程式碼 UI）** 開發，採 **MVVM** 架構並實作 **單例 / 工廠 / 策略** 三種設計模式，內建二級快取與圖片快取（Kingfisher）、支援離線瀏覽、**多國語言（繁中／簡中／英文）**，並整合 **Firebase Remote Config + AdMob** 廣告（可遠端開關），已為上架（App Store）做好基礎設定。

---

## 📱 功能特色

| 功能 | 說明 |
| --- | --- |
| 認養列表 | 兩欄卡片式瀏覽，照片自動快取、淡入顯示 |
| 種類篩選 | 全部 / 狗 / 貓 分段切換 |
| 關鍵字搜尋 | 可搜尋收容所、品種、毛色、尋獲地、地址 |
| 排序策略 | 最新開放 / 最近更新 / 依收容所 / 依種類（策略模式） |
| 動物詳情 | 大圖、完整資料、備註、一鍵**撥打收容所電話**、**開啟地圖**、**分享** |
| 我的收藏 | 點擊愛心即收藏，離線保存，跨頁即時同步 |
| 下拉重整 | 強制向 API 取得最新資料 |
| 離線瀏覽 | 無網路時自動沿用快取資料 |
| 深色模式 | 全面支援 Light / Dark Mode |
| **進階篩選** | 性別／年齡／體型／縣市／已絕育／已打疫苗／開放中（bottom sheet） |
| **離你最近排序** | 定位 + 地理編碼，依收容所距離排序，卡片顯示「📍 X 公里」 |
| **拍照通報** | 拍照／選圖 → 選聯絡單位 → 透過系統分享送出，並可一鍵撥打 |
| **骨架載入** | 初次載入顯示掃光骨架卡片，降低等待焦慮 |
| **觸覺回饋** | 收藏／篩選／送出皆有 Haptic 與彈跳動畫 |
| **最近瀏覽** | 「我的」分頁可切換收藏／最近瀏覽，自動記錄看過的浪浪 |
| **分享圖卡** | 詳情頁一鍵產生精美品牌圖卡分享到社群 |
| **啟動動畫** | App 啟動時播放品牌爪印動畫再揭開主畫面 |
| **品牌主視覺** | 日落珊瑚→蜜桃漸層 + 薄荷藍綠對比，全畫面進場動畫 |
| **認養須知** | 詳情頁附「認養流程」「飼養須知」卡，提升認養成功率 |
| **規劃路線** | 詳情頁一鍵喚起 Apple Maps 導航至收容所 |
| **照片全螢幕** | 點大圖可雙指縮放、雙擊放大、儲存到相簿 |
| **多隻比較** | 加入最多三隻並排比較條件（種類/性別/年齡/體型…） |
| **分享圖卡版型** | 經典／拍立得／簡約三種版型，可加自訂留言、即時預覽 |
| **首次導覽** | Onboarding 選想養種類／關注縣市，作為個人化種子 |
| **緊急救援區** | 依 `animal_closeddate` 算截止倒數，首頁紅色卡標示急需認養 |
| **為你推薦** | 依偏好（種類／縣市）評分排序，首頁橫向輪播 |
| **領養顧問** | 一問一答的本地對話顧問，依空間/經驗/地區評分推薦浪浪，並答認養 FAQ |
| **收容所地圖** | MapKit 標註各收容所（含聚合 clustering），點選查看該所浪浪、一鍵導航/撥打 |
| **以圖找毛孩** | Vision 影像特徵向量「裝置端」比對，上傳走失/喜歡的照片找出長相最相似的浪浪（離線、零成本、保護隱私） |
| **認養日記** | 認養後關懷：每隻毛孩的日記、體重紀錄、照片，及疫苗/回診/驅蟲**本地通知**提醒 |
| **認養倒數 Live Activity** | 緊急浪浪可開啟鎖定畫面 + **動態島**的認養截止倒數（ActivityKit / WidgetKit） |

---

## 🏗 架構：MVVM

```
┌──────────────┐      綁定 (Observable)      ┌──────────────┐
│ ViewController│ ◀───────────────────────── │  ViewModel    │
│   (View)      │ ─────────────────────────▶ │  (狀態/邏輯)   │
└──────────────┘        使用者輸入            └──────┬───────┘
                                                      │ 依賴注入
                                              ┌───────▼────────┐
                                              │  Repository     │  整合資料來源
                                              └───┬─────────┬──┘
                                          ┌───────▼──┐   ┌──▼────────┐
                                          │ APIClient │   │CacheService│
                                          │ (網路)    │   │  (快取)    │
                                          └──────────┘   └───────────┘
```

- **Model**：`Animal` — 對應 API 欄位，容錯解碼，並提供大量「顯示用」衍生屬性（性別、年齡、體型文字等），讓 View 不碰原始代碼。
- **View**：`UIViewController` 系列，只負責畫面與使用者互動，不含商業邏輯。
- **ViewModel**：純 Swift（不 import UIKit），透過自製輕量 `Observable<T>` 將狀態單向綁定給 View。
- **Repository**：對 ViewModel 隱藏資料來自「網路」或「快取」的細節（Cache-Then-Network 策略）。

### 資料夾結構

```
StrayPals/
├─ App/                      App 進入點
│  ├─ AppDelegate.swift
│  └─ SceneDelegate.swift
├─ Core/
│  ├─ Support/Observable.swift        輕量資料綁定 (Box)
│  ├─ Networking/                     APIClient(單例) / APIEndpoint(工廠) / NetworkError
│  ├─ Cache/                          CacheService / ImageCacheService（皆單例）
│  ├─ Models/Animal.swift             資料模型
│  ├─ Repository/AnimalRepository.swift
│  ├─ Sorting/AnimalSortStrategy.swift   排序策略（策略模式）
│  ├─ Factory/ViewControllerFactory.swift 畫面工廠（工廠模式）
│  ├─ Services/                       FavoritesManager / AnalyticsManager（單例）
│  └─ Extensions/                     UIColor / UIImageView+Cache / UIView 工具
├─ Common/Views/EmptyStateView.swift  共用空/錯誤狀態
├─ Features/
│  ├─ AnimalList/                     列表頁 (VC + VM + Cell)
│  ├─ AnimalDetail/                   詳情頁 (VC + VM)
│  └─ Favorites/                      收藏頁 (VC + VM)
└─ Resources/                         Info.plist / Assets.xcassets
```

---

## 🎯 設計模式（Design Patterns）

### 1. 單例 Singleton
全 App 共用、需要單一狀態或共用資源的服務：

| 類別 | 職責 |
| --- | --- |
| `APIClient.shared` | 共用 `URLSession` 的網路客戶端 |
| `CacheService.shared` | 通用資料快取（記憶體 + 磁碟） |
| `ImageCacheService.shared` | 圖片快取與下載 |
| `FavoritesManager.shared` | 收藏狀態與持久化 |
| `AnalyticsManager.shared` | 事件追蹤 |
| `HapticsManager.shared` | 觸覺回饋產生器 |
| `LocationService.shared` | 定位權限與取得位置 |
| `ShelterGeocoder.shared` | 收容所地址→座標，含磁碟快取 |
| `RecentlyViewedManager.shared` | 最近瀏覽紀錄與持久化 |

> 皆以 `private init()` 確保唯一實例，同時用 protocol（如 `APIClientProtocol`）保留依賴注入彈性，方便單元測試。

### 2. 工廠 Factory
- `ViewControllerFactory`：集中建立各畫面並組裝 ViewModel 與相依服務，VC 之間不直接 new 彼此，降低耦合。
- `APIEndpoint.makeRequest()`：以工廠方法統一產生 `URLRequest`，新增端點只需擴充列舉。

### 3. 策略 Strategy
- `AnimalSortStrategy` 協定 + 多個具體策略（`LatestOpenDateSort`、`RecentlyUpdatedSort`、`ByShelterSort`、`ByKindSort`、`ByDistanceSort`）。
- `ByDistanceSort` 展示「帶狀態的策略」：以建構參數注入使用者位置與座標查詢來源，與其他無狀態策略並存。
- ViewModel 持有目前策略，使用者切換排序時僅替換策略實例，**不需修改 ViewModel 邏輯**，符合開放封閉原則。

---

## 💾 快取機制（二級快取）

| 類型 | 記憶體層 | 磁碟層 | 失效策略 |
| --- | --- | --- | --- |
| 資料（動物清單） | `NSCache` | `Caches/DataCache/*.json` | TTL 6 小時，附時間戳 |
| 圖片 | Kingfisher 記憶體快取 | Kingfisher 磁碟快取 | 系統低記憶體 / Kingfisher 過期策略自動回收 |
| 收容所座標 | 記憶體字典 | `Caches/DataCache`（永久） | 地址→經緯度，避免重複地理編碼 |

**讀取流程（Cache-Then-Network）**

1. 有有效快取 → 先用快取回呼，畫面**秒開**。
2. 接著打 API，成功則更新快取並再回呼一次最新資料。
3. API 失敗但有快取（即使過期）→ 沿用快取，**支援離線瀏覽**。

> 圖片載入封裝於 `UIImageView.setImage(from:)`，並以關聯物件記錄請求 token，避免 cell 重用時貼錯圖。

---

## 📦 第三方套件（增進使用者體驗）

本專案已透過 **Swift Package Manager** 整合 [**Kingfisher**](https://github.com/onevcat/Kingfisher)（`8.x`）負責圖片的非同步下載與記憶體＋磁碟二級快取。`git clone` 後 Xcode 會自動解析套件（`Package.resolved` 已鎖定版本）。

> 圖片載入統一封裝於 [`UIImageView+Cache.swift`](StrayPals/StrayPals/Core/Extensions/UIImageView+Cache.swift) 的 `setImage(from:placeholder:)`，因此呼叫端完全不需直接接觸 Kingfisher API；未來要換回原生或其他套件只需改這一支。

其餘可再加入的套件（選用）：

| 套件 | 用途 | 替換點 |
| --- | --- | --- |
| [SnapKit](https://github.com/SnapKit/SnapKit) | 更精簡的 Auto Layout DSL | 各 `setupUI()` |
| [Lottie](https://github.com/airbnb/lottie-ios) | 更豐富的載入 / 啟動動畫 | `LaunchAnimationView` / `EmptyStateView` |
| [Firebase Analytics](https://firebase.google.com/) | 正式的事件分析 | `AnalyticsManager.track(_:)` |

---

## 🔌 API

- 來源：農業部開放資料平台 — 全國認養動物
- Endpoint：
  ```
  GET https://data.moa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL&IsTransData=1
  ```
- 回傳：JSON 陣列。主要欄位：`animal_kind`(狗/貓)、`animal_sex`、`animal_age`、`album_file`(照片)、`shelter_name`、`shelter_tel`、`shelter_address`、`animal_remark` 等。

---

## 🚀 建置與執行

```bash
open StrayPals.xcodeproj      # 以 Xcode 16+ 開啟
# 選擇模擬器（iOS 16.0+）後按 ⌘R
```

需求：
- Xcode 16 以上（專案 `objectVersion = 77`，使用檔案系統同步群組）
- 部署目標：iOS 16.0+
- Swift 5

---

## 📈 可加入的功能分析（Roadmap）

依「使用者價值 × 開發成本」評估，建議優先順序如下：

> ✅ **v1.1 已完成**：地理定位排序、進階篩選、拍照通報、骨架載入、觸覺回饋與收藏動畫。

### 高價值 / 低成本
1. ✅ ~~**地理定位排序**~~：已實作（`LocationService` + `ShelterGeocoder` + `ByDistanceSort`）。
2. ✅ ~~**多條件進階篩選**~~：已實作（`FilterCriteria` + 篩選面板）。
3. **下拉重整 + 分頁/無限捲動**：資料量大時改善效能（目前 API 一次回傳全部）。
4. **收藏分享 / 認養前檢查清單**：提升轉換率與實用性。

### 中價值
5. **推播通知**：訂閱特定收容所或條件，有新動物上架即通知（需後端排程比對）。
6. **地圖總覽**：以 MapKit 顯示各收容所位置與動物數量聚合標記。
7. **比較功能**：同時比較多隻動物的條件。
8. **無障礙強化**：VoiceOver 標籤、動態字級、減少動態效果。

### 進階 / 長期
9. **AI 推薦**：依使用者收藏與瀏覽行為，推薦合適的浪浪（可串接 Core ML 或後端模型）。
10. **認養流程整合**：串接收容所線上預約/表單。
11. **社群與認養成功故事**：增加情感連結與回訪率。
12. **Widget / App Clip**：桌面小工具顯示「今日推薦浪浪」。

### 數據面（Analytics 可追蹤的指標）
目前 `AnalyticsManager` 已預埋下列事件，可用於後續產品決策：
- 開啟 App、清單載入量、是否命中快取
- 查看詳情、收藏/取消收藏
- 切換排序、種類篩選、搜尋關鍵字
- 撥打收容所電話、開啟地圖（**衡量「實際認養意願」的關鍵轉換事件**）

可進一步分析：最受歡迎的動物特徵（種類/體型/年齡）、各收容所曝光與互動、搜尋熱詞、收藏→撥打的轉換漏斗。

---

## 🌏 多國語言

支援 **繁體中文（zh-Hant）／簡體中文（zh-Hans）／英文（en）**，跟隨系統語言，亦可在 App 內手動切換。

- **App 內語言切換**：「我的」分頁右上角齒輪 → 選擇語言，**即時生效不需重啟**。
  - [`LanguageManager`](StrayPals/StrayPals/Core/Support/LanguageManager.swift)（單例）以選定語系的 `.lproj` Bundle 查表，切換後由 `SceneDelegate` 以淡入轉場重建畫面。
- 所有 UI 字串集中於 [`L10n.swift`](StrayPals/StrayPals/Core/Support/L10n.swift)，經 `LanguageManager` 查表，`defaultValue` 為繁中後備值。
- 翻譯檔：`Resources/{en,zh-Hant,zh-Hans}.lproj/Localizable.strings`。
- App 顯示名稱與權限說明在各語系的 `InfoPlist.strings`。
- 連動物的性別／年齡／體型等 API 代碼也都在地化（公/Male、成年/Adult…）。

> 新增字串：在 `L10n` 加一個 key，並補上三個 `.strings` 的翻譯即可。

---

## 📣 廣告與遠端開關（Firebase Remote Config + AdMob）

廣告以「**SDK 是否存在** × **遠端是否開啟**」雙重條件控制，並用 `#if canImport(...)` 閘控：

- **未加入 SDK** → 廣告區自動收合（高度 0），App 照常運作、**不會崩潰**，方便開發與審查。
- **加入 SDK 後** → 程式碼零修改自動生效。

| 元件 | 角色 |
| --- | --- |
| [`AppConfig`](StrayPals/StrayPals/Core/Services/AppConfig.swift) | 包裝 Firebase Remote Config，提供 `adsEnabled`、`adBannerUnitID`，可遠端關閉廣告 |
| [`AdsService`](StrayPals/StrayPals/Core/Services/AdsService.swift) | 啟動 AdMob、綜合判斷 `shouldShowAds` |
| [`BannerAdView`](StrayPals/StrayPals/Common/Views/BannerAdView.swift) | 列表底部橫幅廣告容器，未啟用時收合 |

### 啟用步驟（正式上線）
1. **加入套件**（Xcode → File → Add Package Dependencies）：
   - Firebase：`https://github.com/firebase/firebase-ios-sdk` → 勾選 `FirebaseRemoteConfig`、`FirebaseAnalytics`
   - AdMob：`https://github.com/googleads/swift-package-manager-google-mobile-ads`
2. 從 Firebase 主控台下載 **`GoogleService-Info.plist`** 放入專案（`AppDelegate` 偵測到才會 `FirebaseApp.configure()`）。
3. 在 `Info.plist` 的 `GADApplicationIdentifier` 換成你的 **AdMob App ID**（目前為 Google 官方測試 ID）。
4. 在 `AppConfig` 把 `adBannerUnitID` 換成你的**正式廣告單元 ID**，或在 Remote Config 後台設 `ad_banner_unit_id`。
5. 在 Remote Config 後台用 `ads_enabled`（Boolean）即可**遠端一鍵開關**全 App 廣告。

> 目前使用的是 Google 官方**測試**廣告 ID（橫幅 `…/2934735716`、App `…~1458002511`），可直接看到測試廣告，不會產生無效點擊。

---

## 🎨 App 命名與圖示

- **命名**：選用合成／中文品牌名 **毛窩 MaoWo**，降低 App Store 撞名機率（顯示名稱由各語系 `InfoPlist.strings` 的 `CFBundleDisplayName` 提供）。
- **圖示**：以品牌色「日落珊瑚→蜜桃」漸層 + 白色貓掌托於「窩」中，1024×1024，已放入 `Assets.xcassets/AppIcon`。
  > 產生方式：`/tmp/makeicon.swift`（CoreGraphics 繪製），可調整後重跑覆蓋。
- **溫馨配色**：各畫面鋪上 [`WarmBackdropView`](StrayPals/StrayPals/Common/Views/WarmBackdropView.swift) 暖色漸層（上緣柔和蜜桃光暈 → 暖象牙底），卡片用近白暖色、CTA 用珊瑚漸層、狀態徽章用薄荷藍綠對比，整體走「溫暖療癒」質感，並完整支援深色模式。

---

## 🔧 程式優化與 Code Review 記錄

本輪已套用的優化：
- **圖片快取改用 Kingfisher**，移除自製 `ImageCacheService`（減少維護面、獲得業界級快取/重用）。
- **Swift Concurrency**：`APIClient` / `AnimalRepository` 改為 `async/await`，移除巢狀 completion；倉儲拆成 `cachedAnimals()`（秒開）+ `fetchAnimals() async`（最新，失敗退回快取）。
- **搜尋去抖動**（debounce 0.3s），避免每個字元都重算整份清單。
- **全域外觀** [`AppAppearance`](StrayPals/StrayPals/Core/Support/AppAppearance.swift)：統一 iOS 15+ 導覽列／分頁列樣式。
- **在地化字串集中化**（`L10n`）+ App 內語言切換。
- **排序判斷改用型別檢查**（`isDistanceSortActive`），避免多語系下比較在地化字串失準。

仍可再進一步：
1. **分頁/虛擬化**：API 一次回傳全部；資料量大時可加分頁與 Kingfisher prefetch。
2. **無障礙**：補 `accessibilityLabel`、動態字級、VoiceOver 流程。
3. **可測試性擴充**：`FavoritesManager` / `RecentlyViewedManager` 抽出協定、注入 `UserDefaults(suite:)`。
4. **錯誤可觀測性**：`AnalyticsManager` 串接後加上網路錯誤、廣告填充率事件。

---

## ✅ 單元測試

已建立 **StrayPalsTests** 測試 target（17 個測試全數通過），涵蓋：

| 測試檔 | 範圍 |
| --- | --- |
| `FilterCriteriaTests` | 種類/性別/年齡/絕育/開放/縣市篩選與 `isActive`、`advancedCount` |
| `SortStrategyTests` | 各排序策略結果與 provider 數量 |
| `AnimalDecodingTests` | 容錯解碼、缺漏欄位、衍生屬性、陣列解碼 |
| `AnimalRepositoryTests` | 網路成功、寫入快取、**失敗退回快取（離線 fallback）**、無快取拋錯 |

- 以 `MockAPIClient`（符合 `APIClientProtocol`）注入假資料／錯誤，不依賴真實網路。
- `AnimalFactory` 以 JSON 解碼建立測試資料。
- 執行：Xcode 按 **⌘U**，或 `xcodebuild test -scheme StrayPals -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`。

---

## 🤖 領養顧問（AI 助理）

「顧問」分頁是一個**一問一答的領養顧問**，目前為**本地規則式實作**——零金鑰、可離線、零成本。

- 流程：種類 → 居住空間 → 飼養經驗 → 地區，蒐集偏好後依評分從目前資料推薦最合適的浪浪（聊天泡泡內直接顯示可點選的動物卡）。
- 也能回答「認養流程／飼養須知／費用」等常見問題（複用既有的須知內容）。
- 抽象於 [`AIAssistantService`](StrayPals/StrayPals/Core/Services/AIAssistantService.swift) 協定，本地實作為 [`PetAdvisorService`](StrayPals/StrayPals/Features/Assistant/PetAdvisorService.swift)。

### 升級成真正的 Claude（之後）
協定設計成可直接替換：新增一個符合 `AIAssistantService` 的實作即可，UI / ViewModel **不需更動**。建議：

- **模型**：輕量對話用 **Claude Haiku 4.5**（$1/$5 每 1M tokens，又快又省）即足夠；想更強的多輪理解再升 Sonnet 4.6。
- **架構**：`App → 你的後端 Proxy → Claude Messages API`。**切勿把 API Key 放進 App**（會被反編譯取出），務必經自己的後端代理。
- **工具呼叫**：定義 `search_pets` 工具讓 Claude 從自然語言抽出條件，後端查 MoA 資料回填——正好接上現有的 `FilterCriteria`。
- **串流**：逐字顯示回覆，體驗更順。

---

## 📤 上架前檢查清單

### A. 帳號 / 簽章 / Bundle

- [ ] 設定 `DEVELOPMENT_TEAM` 與簽章憑證（主 App 與 **MaoWoWidgetsExtension** 兩個 target 都要）
- [ ] 主 App Bundle ID `com.straypals.StrayPals`、Widget Bundle ID `com.straypals.StrayPals.MaoWoWidgets`（**必須是 App ID 的子字串**，否則無法上架）
- [ ] 兩個 target 的 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` 一致
- [ ] 確認 App Store 顯示名稱 **毛窩 / MaoWo** 未與他人重複

### B. 權限用途字串（缺一會被退件，務必寫清楚「為什麼」）

- [x] `NSCameraUsageDescription`（通報拍照 / 以圖找毛孩）
- [x] `NSPhotoLibraryUsageDescription`（選圖通報 / 以圖找毛孩 / 日記照片）
- [x] `NSPhotoLibraryAddUsageDescription`（儲存浪浪照片到相簿）
- [x] `NSLocationWhenInUseUsageDescription`（離你最近排序 / 收容所地圖）
- [x] `NSUserTrackingUsageDescription`（ATT，個人化廣告）
- [x] 通知（認養日記提醒）— iOS 本地通知**無需**在 Info.plist 加 key，採執行期 `requestAuthorization`；首次新增提醒時才請求（符合審查「有情境才要權限」原則）

### C. 新功能相關的審查重點

- [x] **Live Activity**：`NSSupportsLiveActivities = YES` 已加在主 App Info.plist；活動由使用者於詳情頁**主動開啟**（符合「進行中、有時效事件」用途），到截止時間自動 stale/結束 → 降低被視為濫用的風險
- [x] **以圖找毛孩**完全在裝置端（Vision）運算，**不上傳**照片到任何伺服器 → 隱私權標籤可勾「資料不離開裝置」
- [ ] 隱私權標籤（App Privacy）：
  - 收藏 / 最近瀏覽 / 認養日記 / 提醒 → 皆存於**本機**（不收集）
  - 定位 → 僅用於 App 功能、不離開裝置、不追蹤
  - 若開 AdMob → 宣告「識別碼 / 使用資料」用於廣告，並啟用 ATT
- [ ] 4. **資料來源標註**：在 App 描述或「關於」標明資料來自**農業部開放資料**，避免被質疑資料來源

### D. 廣告（若啟用）

- [ ] 放入 `GoogleService-Info.plist` 並把 `GADApplicationIdentifier` 換成**正式** AdMob ID（目前為 Google 測試 ID）
- [ ] 送審前避免顯示測試廣告版位給審查員（測試 ID 的橫幅會標 "Test Ad"）

### E. 其他

- [x] `ITSAppUsesNonExemptEncryption = false`（免出口加密合規）
- [x] App Icon 1024×1024 已內建（可再美化）
- [ ] 準備三語螢幕截圖與 App 描述（含一張 Live Activity / 動態島 截圖更吸睛）
- [ ] 真機實測：動態島（需 iPhone 14 Pro 以上）、通知到期推送、定位、相機/相簿、以圖搜尋耗時

> **送審風險提醒**：四個新功能中，**Live Activity** 與**廣告**是最常見的退件來源。Live Activity 已設計為使用者主動觸發且具明確時效，相對安全；廣告務必換正式 ID 並完成 ATT + 隱私標籤。其餘（地圖 / 以圖搜尋 / 日記）皆為裝置端、低風險。

---

## 📝 程式碼註解

全專案採用 `// MARK:` 分段，並對型別、重要方法附上繁體中文文件註解，方便維護與交接。

---

## ⚖️ 授權與資料聲明

動物資料著作權屬農業部所有，本 App 僅作資訊呈現與公益認養推廣用途。
