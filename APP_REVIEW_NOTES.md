# App Review Information — Notes（直接貼到 App Store Connect 的 App Review Information → Notes）

> 下面「英文區塊」整段複製貼到 Notes 欄位即可（審查員讀英文）。中文是給你看的說明，不要貼進去。

---

## ✅ 貼進 Notes 的英文全文（從這裡開始複製）

```
=== APP OVERVIEW ===
App name: MaoWo (毛窩) — internal project code "StrayPals".
Purpose: MaoWo helps people in Taiwan browse, search, favorite, and contact public animal shelters to adopt stray dogs and cats that are waiting for adoption. The problem it solves: shelter adoption data is scattered and hard to browse on mobile; MaoWo presents it in a clean, searchable, photo-rich interface and makes it one tap to call a shelter or get directions, increasing adoption.
Target audience: General public in Taiwan interested in adopting a pet from a public shelter.

=== HOW TO ACCESS / TEST ===
- No account, login, or registration is required. All features are available immediately on launch.
- No in-app purchases or subscriptions. The app is free with no paid content.
- No sample files or credentials are needed.
- On first launch the app shows a short onboarding (pick preferred species / region) used only to personalize recommendations locally on device; you can skip it.
- Core flow: Launch → "Adopt" tab loads the adoptable-animals list → tap a card to view details → use Call / Maps / Share. Other tabs: Advisor (local Q&A pet advisor), Report (photo a stray and share to a contact unit), and Mine (favorites / recently viewed / settings).

=== EXTERNAL SERVICES / DATA SOURCES ===
- Animal data: Taiwan Ministry of Agriculture (MoA) Open Data Platform — public open government data of nationwide adoptable shelter animals.
  Endpoint: https://data.moa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL&IsTransData=1
- Firebase (Google): Remote Config and Analytics (no-IDFA / no-ad-id measurement). Used for remote feature flags and anonymous usage analytics only.
- Image loading/caching: Kingfisher (open-source library).
- "Find by photo" similarity matching: Apple Vision framework, runs 100% ON DEVICE. No photo is uploaded to any server.
- This build does NOT include advertising, third-party login, payment processing, or any AI/LLM network service. The "Advisor" feature is a fully local, rule-based assistant (no external AI service).

=== PERMISSION PROMPTS (when and why) ===
- Camera (NSCameraUsageDescription): only when the user taps "Report a stray" to take a photo, or uses "Find by photo". Example: take a photo of a stray to share with a contact unit.
- Photo Library (NSPhotoLibraryUsageDescription / Add): only when the user chooses an existing photo to report / find by photo, or saves an animal photo to their album.
- Location When In Use (NSLocationWhenInUseUsageDescription): only when the user chooses "Sort by nearest" or opens the Shelter Map, to order shelters by distance. Location never leaves the device and is not used for tracking.
- Notifications: requested only when the user creates a care reminder in the Adoption Diary (vaccine / check-up reminders). Local notifications only.
- App Tracking Transparency (ATT): NOT used in this build (no ads, no tracking).

=== USER-GENERATED CONTENT ===
- The app does not host a public social feed. "Report a stray" composes a photo + note that the USER sends through the system share sheet to a contact unit of their choice; nothing is posted publicly inside the app, so content reporting/blocking is not applicable.
- Favorites, recently-viewed, and the Adoption Diary (notes/photos/weight) are stored LOCALLY on the device only and are not shared or collected.

=== REGIONAL DIFFERENCES ===
- The app functions consistently across all regions. Content is Taiwan public-shelter data regardless of region.
- UI is localized in Traditional Chinese, Simplified Chinese, and English, following the system language (also switchable in-app). Features are identical in every language/region.

=== REGULATED INDUSTRY / THIRD-PARTY MATERIAL / AUTHORIZATION ===
- The animal data is OPEN GOVERNMENT DATA published by Taiwan's Ministry of Agriculture for public use; the app only displays it for the public-interest purpose of adoption and credits the source. No special license or credential is required to use this open data.
- The app is not in a regulated industry (no health, finance, etc.) and contains no protected/licensed third-party media.

=== DEVICE MODELS & OS TESTED (請填入你實際測試過的，下面是範例，務必改成真的) ===
- iPhone 15 Pro — iOS 18.x
- iPhone 13 — iOS 18.x
- iPad (9th gen) — iPadOS 18.x  (若不支援 iPad 請刪掉這行)
(Replace the above with the actual physical devices and OS versions you tested on before submitting.)

=== DEMO ACCOUNT ===
Not applicable — the app has no login.
```

（複製到這裡結束）

---

## 📌 還要做的事（這幾項 Apple 一定會看）

1. **示範影片（必交）**：用**實體 iPhone**、最新 iOS 錄一段螢幕錄影，從**點開 App 開始**，走完核心流程：
   啟動 → 認養列表 →（出現定位/相機/相簿/通知任一權限提示時要入鏡）→ 點進詳情 → 撥打/地圖/分享 → 顧問 → 拍照通報 → 我的/收藏。
   把影片連同上面 Notes 一起在 Resolution Center 回覆。

2. **App 商店截圖（Guideline 2.3.3）**：要放**實際使用中的畫面**（列表、詳情、地圖…），不要只放啟動畫面 / 標題圖 / 登入頁。

3. **隱私權標籤（App Privacy）**在 App Store Connect 設定：
   - 收藏 / 最近瀏覽 / 認養日記 / 提醒 → 存在本機，**不收集**。
   - 定位 → 僅用於 App 功能、不離開裝置、**不追蹤**。
   - Firebase Analytics → 視為「使用資料」用於分析（已用 no-IDFA 版本、不追蹤）。

4. **「測試裝置與 OS」清單**：把上面範例那段換成你**真的測過**的機型與版本（Apple 這次有特別要這個）。
