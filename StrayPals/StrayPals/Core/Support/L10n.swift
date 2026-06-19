//
//  L10n.swift
//  StrayPals (MaoWo)
//
//  集中管理所有在地化字串（多國語言：繁中 / 簡中 / 英文）。
//  字串查表透過 `LanguageManager`，因此支援「App 內手動切換語言、即時生效」；
//  `defaultValue` 為開發語言（繁體中文）的後備值，翻譯放在 `*.lproj/Localizable.strings`。
//

import Foundation

// MARK: - L10n

enum L10n {

    /// 統一查表入口（經由 LanguageManager，支援 App 內切語言）。
    private static func t(_ key: String, _ def: String) -> String {
        LanguageManager.shared.string(key, def)
    }

    // MARK: App
    static var appName: String { t("app.name", "毛窩") }
    static var launchSubtitle: String { t("launch.subtitle", "一起幫浪浪找個家") }

    // MARK: Language
    static var settingsTitle: String { t("settings.title", "設定") }
    static var settingsLanguage: String { t("settings.language", "語言") }
    static var languageSystem: String { t("language.system", "跟隨系統") }

    // MARK: Onboarding
    static var onboardingWelcomeTitle: String { t("onboarding.welcome.title", "歡迎來到毛窩") }
    static var onboardingWelcomeSubtitle: String { t("onboarding.welcome.subtitle", "簡單設定，幫你更快找到想照顧的浪浪") }
    static var onboardingKindQuestion: String { t("onboarding.kind.question", "你想認養？") }
    static var onboardingCityQuestion: String { t("onboarding.city.question", "想關注哪些地區？（可多選 / 可跳過）") }
    static var onboardingStart: String { t("onboarding.start", "開始探索") }
    static var onboardingSkip: String { t("onboarding.skip", "略過") }

    // MARK: Home Sections
    static var homeSectionEmergency: String { t("home.section.emergency", "緊急救援") }
    static var homeSectionRecommended: String { t("home.section.recommended", "為你推薦") }
    static var homeSectionAll: String { t("home.section.all", "全部浪浪") }
    static var badgeUrgent: String { t("badge.urgent", "緊急") }
    static func daysLeft(_ days: Int) -> String {
        String(format: t("urgent.daysLeft", "剩 %d 天"), days)
    }
    static var lastDay: String { t("urgent.lastDay", "今日截止") }

    // MARK: Tabs
    static var tabAdopt: String { t("tab.adopt", "認養") }
    static var tabReport: String { t("tab.report", "通報") }
    static var tabMine: String { t("tab.mine", "我的") }
    static var tabAssistant: String { t("tab.assistant", "顧問") }

    // MARK: Adoption Advisor (local assistant)
    static var assistantTitle: String { t("assistant.title", "領養顧問") }
    static var assistantPlaceholder: String { t("assistant.placeholder", "輸入訊息…") }
    static var advisorGreeting: String { t("advisor.greeting", "嗨！我是領養顧問 🐾 回答幾個問題，我幫你找到最適合的浪浪。先問：你想養貓還是狗？") }
    static var advisorAskSpace: String { t("advisor.q.space", "了解！你的居住空間是？") }
    static var advisorAskExperience: String { t("advisor.q.experience", "你有養寵物的經驗嗎？") }
    static var advisorAskCity: String { t("advisor.q.city", "最後，想在哪個地區認養呢？可直接打字或從下方選。") }
    static var advisorResultIntro: String { t("advisor.result", "根據你的條件，我推薦這幾隻浪浪：") }
    static var advisorResultFallback: String { t("advisor.result.fallback", "目前沒有完全符合的，但這幾隻也很值得認識：") }
    static var advisorResultEmpty: String { t("advisor.result.empty", "目前查無可推薦的資料，請稍後再試或下拉重整列表。") }
    static var advisorLoading: String { t("advisor.loading", "正在載入浪浪資料，請稍候…") }
    static var advisorRestart: String { t("advisor.restart", "想重新找？輸入「重新開始」即可。") }

    // Options
    static var advOptDog: String { t("advisor.opt.dog", "狗") }
    static var advOptCat: String { t("advisor.opt.cat", "貓") }
    static var advOptEither: String { t("advisor.opt.either", "都可以") }
    static var advOptStudio: String { t("advisor.opt.studio", "套房") }
    static var advOptApartment: String { t("advisor.opt.apartment", "公寓") }
    static var advOptHouse: String { t("advisor.opt.house", "透天/有院子") }
    static var advOptBeginner: String { t("advisor.opt.beginner", "新手") }
    static var advOptExperienced: String { t("advisor.opt.experienced", "有經驗") }
    static var advOptAnyCity: String { t("advisor.opt.anyCity", "不限地區") }

    // FAQ
    static var advFaqFee: String { t("advisor.faq.fee", "各收容所規費不同，通常包含晶片植入與寵物登記費用，金額不高。建議直接撥打該收容所電話確認最新資訊。") }
    static var advFaqFallback: String { t("advisor.faq.fallback", "我可以幫你找適合的浪浪，也能回答認養流程、飼養須知或費用問題。要不要先告訴我你想養貓還是狗？") }

    // MARK: Common Actions
    static var actionRetry: String { t("action.retry", "重新載入") }
    static var actionCancel: String { t("action.cancel", "取消") }
    static var actionOK: String { t("action.ok", "了解") }
    static var actionGoSettings: String { t("action.goSettings", "前往設定") }

    // MARK: List
    static var listSearchPlaceholder: String { t("list.search.placeholder", "搜尋收容所、品種、毛色…") }
    static var listEmptyTitle: String { t("list.empty.title", "找不到符合的浪浪") }
    static var listEmptyMessage: String { t("list.empty.message", "試試其他關鍵字或篩選條件。") }
    static var listErrorTitle: String { t("list.error.title", "載入失敗") }

    // MARK: Kind Filter
    static var kindAll: String { t("kind.all", "全部") }
    static var kindDog: String { t("kind.dog", "狗") }
    static var kindCat: String { t("kind.cat", "貓") }
    static var kindOther: String { t("kind.other", "其他") }

    // MARK: Sort
    static var sortTitle: String { t("sort.title", "排序方式") }
    static var sortLatest: String { t("sort.latest", "最新開放") }
    static var sortUpdated: String { t("sort.updated", "最近更新") }
    static var sortShelter: String { t("sort.shelter", "依收容所") }
    static var sortKind: String { t("sort.kind", "依種類") }
    static var sortDistance: String { t("sort.distance", "離你最近") }
    static var sortDistancePicker: String { t("sort.distancePicker", "離你最近（依定位）") }

    // MARK: Location
    static var locationDeniedTitle: String { t("location.denied.title", "需要定位權限") }
    static var locationDeniedMessage: String { t("location.denied.message", "請到「設定」開啟定位，才能依距離排序最近的浪浪。") }

    // MARK: Filter
    static var filterTitle: String { t("filter.title", "進階篩選") }
    static var filterReset: String { t("filter.reset", "重置") }
    static var filterApply: String { t("filter.apply", "套用") }
    static var filterSex: String { t("filter.sex", "性別") }
    static var filterAge: String { t("filter.age", "年齡") }
    static var filterBodyType: String { t("filter.bodyType", "體型") }
    static var filterCondition: String { t("filter.condition", "條件") }
    static var filterCity: String { t("filter.city", "縣市") }
    static var filterSterilized: String { t("filter.sterilized", "已絕育") }
    static var filterVaccinated: String { t("filter.vaccinated", "已打疫苗") }
    static var filterOpen: String { t("filter.open", "開放認養中") }

    // MARK: Values — Sex / Age / Body / Status
    static var sexMale: String { t("value.sex.male", "公") }
    static var sexFemale: String { t("value.sex.female", "母") }
    static var ageAdult: String { t("value.age.adult", "成年") }
    static var ageChild: String { t("value.age.child", "幼年") }
    static var bodySmall: String { t("value.body.small", "小型") }
    static var bodyMedium: String { t("value.body.medium", "中型") }
    static var bodyBig: String { t("value.body.big", "大型") }
    static var unknown: String { t("value.unknown", "未知") }
    static var notProvided: String { t("value.notProvided", "未提供") }
    static var sterilizedYes: String { t("value.sterilized.yes", "已絕育") }
    static var sterilizedNo: String { t("value.sterilized.no", "未絕育") }
    static var vaccineYes: String { t("value.vaccine.yes", "已施打") }
    static var vaccineNo: String { t("value.vaccine.no", "未施打") }
    static var noRemark: String { t("value.noRemark", "目前沒有更多說明。") }
    static var cityOther: String { t("value.city.other", "其他") }

    // MARK: Detail
    static var detailSectionBasic: String { t("detail.section.basic", "基本資料") }
    static var detailSectionShelter: String { t("detail.section.shelter", "收容所資訊") }
    static var detailSectionNote: String { t("detail.section.note", "認養說明") }
    static var detailStatusOpen: String { t("detail.status.open", "開放認養中") }
    static var detailStatusInfo: String { t("detail.status.info", "認養資訊") }
    static var detailRowKind: String { t("detail.row.kind", "種類") }
    static var detailRowVariety: String { t("detail.row.variety", "品種") }
    static var detailRowSex: String { t("detail.row.sex", "性別") }
    static var detailRowAge: String { t("detail.row.age", "年齡") }
    static var detailRowBody: String { t("detail.row.body", "體型") }
    static var detailRowColor: String { t("detail.row.color", "毛色") }
    static var detailRowSterilized: String { t("detail.row.sterilized", "絕育") }
    static var detailRowVaccine: String { t("detail.row.vaccine", "狂犬病疫苗") }
    static var detailRowFoundPlace: String { t("detail.row.foundPlace", "尋獲地") }
    static var detailRowOpenDate: String { t("detail.row.openDate", "開放日期") }
    static var detailRowShelter: String { t("detail.row.shelter", "收容所") }
    static var detailRowAddress: String { t("detail.row.address", "地址") }
    static var detailRowPhone: String { t("detail.row.phone", "電話") }
    static var detailRowNote: String { t("detail.row.note", "備註") }
    static var detailActionCall: String { t("detail.action.call", "撥打電話") }
    static var detailActionMap: String { t("detail.action.map", "開啟地圖") }
    static var detailActionRoute: String { t("detail.action.route", "規劃路線") }
    static var detailActionCompare: String { t("detail.action.compare", "加入比較") }
    static var detailActionComparing: String { t("detail.action.comparing", "已加入比較") }

    // MARK: Adoption Flow / Care Tips
    static var adoptFlowTitle: String { t("adopt.flow.title", "認養流程") }
    static var careTitle: String { t("care.title", "飼養須知") }
    static var adoptionSteps: [String] {
        [
            t("adopt.flow.1", "確認家人同意，評估飼養空間、時間與經濟能力。"),
            t("adopt.flow.2", "聯繫收容所確認動物狀態與開放/抽籤時間。"),
            t("adopt.flow.3", "攜帶身分證件前往，現場互動了解性格。"),
            t("adopt.flow.4", "完成認養手續、晶片植入與寵物登記。")
        ]
    }
    static var careTips: [String] {
        [
            t("care.tip.1", "備妥食盆、睡窩、牽繩或外出籠等基本用品。"),
            t("care.tip.2", "安排健康檢查、必要疫苗並定期驅蟲。"),
            t("care.tip.3", "給予適應期，耐心陪伴建立信任。"),
            t("care.tip.4", "依法完成寵物登記，並絕育以減少流浪問題。")
        ]
    }

    // MARK: Compare
    static var compareTitle: String { t("compare.title", "比較") }
    static var compareEmptyTitle: String { t("compare.empty.title", "尚未加入比較") }
    static var compareEmptyMessage: String { t("compare.empty.message", "在動物詳情頁點「加入比較」，最多可比較三隻浪浪。") }
    static var compareClear: String { t("compare.clear", "清空") }
    static var compareFull: String { t("compare.full", "最多比較三隻，請先移除一隻。") }

    // MARK: Photo Viewer
    static var photoSaved: String { t("photo.saved", "已儲存到相簿") }

    // MARK: Share Card Styles
    static var shareStyleClassic: String { t("share.style.classic", "經典") }
    static var shareStylePolaroid: String { t("share.style.polaroid", "拍立得") }
    static var shareStyleMinimal: String { t("share.style.minimal", "簡約") }
    static var shareComposerTitle: String { t("share.composer.title", "分享圖卡") }
    static var shareComposerMessagePlaceholder: String { t("share.composer.message", "加一句話（選填）…") }
    static var shareComposerShare: String { t("share.composer.share", "分享") }
    static var detailNoPhone: String { t("detail.noPhone", "此收容所未提供電話。") }
    static var detailNoAddress: String { t("detail.noAddress", "此收容所未提供地址。") }

    // MARK: Mine
    static var mineModeFavorites: String { t("mine.mode.favorites", "收藏") }
    static var mineModeRecent: String { t("mine.mode.recent", "最近瀏覽") }
    static var mineEmptyFavTitle: String { t("mine.empty.fav.title", "還沒有收藏") }
    static var mineEmptyFavMessage: String { t("mine.empty.fav.message", "在動物卡片上點擊愛心，就能把喜歡的浪浪加入這裡。") }
    static var mineEmptyRecentTitle: String { t("mine.empty.recent.title", "還沒有瀏覽紀錄") }
    static var mineEmptyRecentMessage: String { t("mine.empty.recent.message", "看過的浪浪會出現在這裡，方便你回頭再看看。") }

    // MARK: Report
    static var reportPhotoHint: String { t("report.photo.hint", "點擊拍照或選擇照片") }
    static var reportSectionUnit: String { t("report.section.unit", "聯絡單位") }
    static var reportSectionNote: String { t("report.section.note", "描述（選填）") }
    static var reportUnitPlaceholder: String { t("report.unit.placeholder", "請選擇聯絡單位") }
    static var reportNotePlaceholder: String { t("report.note.placeholder", "描述發現的地點、動物狀況…") }
    static var reportSubmit: String { t("report.submit", "送出通報") }
    static var reportPhotoAdd: String { t("report.photo.add", "新增照片") }
    static var reportPhotoCamera: String { t("report.photo.camera", "拍照") }
    static var reportPhotoLibrary: String { t("report.photo.library", "從相簿選擇") }
    static var reportMenuTitle: String { t("report.menu.title", "選擇聯絡單位") }
    static var reportNeedUnitTitle: String { t("report.needUnit.title", "請先選擇聯絡單位") }
    static var reportNeedUnitMessage: String { t("report.needUnit.message", "選好要通報的收容所/動保機關後再送出。") }
    static var reportTextTitle: String { t("report.text.title", "【浪浪通報】") }
    static var reportTextUnit: String { t("report.text.unit", "通報單位：") }
    static var reportTextAddress: String { t("report.text.address", "單位地址：") }
    static var reportTextDescPrefix: String { t("report.text.descPrefix", "描述：") }
    static var reportTextDescDefault: String { t("report.text.descDefault", "（發現疑似流浪動物，請協助處理）") }
    static var reportTextFooter: String { t("report.text.footer", "（由 毛窩 MaoWo App 通報）") }

    // MARK: Share / Branding
    static var shareBrand: String { t("share.brand", "🐾 毛窩 MaoWo ｜ 一起幫浪浪找個家") }

    // MARK: Shelter Map（收容所地圖）
    static var mapTitle: String { t("map.title", "收容所地圖") }
    static var mapLoading: String { t("map.loading", "定位收容所中…") }
    static func mapShelterCount(_ count: Int) -> String {
        String(format: t("map.shelterCount", "%d 隻浪浪"), count)
    }

    // MARK: Photo Search（以圖找毛孩）
    static var photoSearchTitle: String { t("photo.search.title", "以圖找毛孩") }
    static var photoSearchChoose: String { t("photo.search.choose", "選擇照片") }
    static var photoSearchAnalyzing: String { t("photo.search.analyzing", "分析中…") }
    static var photoSearchResult: String { t("photo.search.result", "最相似的浪浪在這裡：") }
    static var photoSearchEmpty: String { t("photo.search.empty", "找不到相似的浪浪，換一張照片試試。") }
    static var photoSearchEmptyTitle: String { t("photo.search.emptyTitle", "以圖找毛孩") }
    static var photoSearchEmptyMessage: String { t("photo.search.emptyMessage", "上傳走失寵物或喜歡的照片，於裝置端比對長相最相似的待認養浪浪（離線、保護隱私）。") }
    static func photoSearchProgress(_ done: Int, _ total: Int) -> String {
        String(format: t("photo.search.progress", "分析中… %1$d / %2$d"), done, total)
    }
    static func photoSearchSimilarity(_ percent: Int) -> String {
        String(format: t("photo.search.similarity", "相似 %d%%"), percent)
    }

    // MARK: Adoption Journal（認養日記 / 照護提醒）
    static var journalTitle: String { t("journal.title", "認養日記") }
    static var journalEmptyTitle: String { t("journal.empty.title", "還沒有認養紀錄") }
    static var journalEmptyMessage: String { t("journal.empty.message", "把帶回家的毛孩加進來，記錄日記、體重，並設定疫苗與回診提醒。") }
    static var journalDefaultName: String { t("journal.defaultName", "毛孩") }
    static var journalAddRecord: String { t("journal.addRecord", "新增認養紀錄") }
    static var journalAddEntry: String { t("journal.addEntry", "新增日記") }
    static var journalAddReminder: String { t("journal.addReminder", "新增提醒") }
    static var journalDeleteTitle: String { t("journal.delete.title", "刪除這筆認養紀錄？") }
    static var journalSectionReminders: String { t("journal.section.reminders", "照護提醒") }
    static var journalSectionEntries: String { t("journal.section.entries", "日記") }
    static var journalNoReminders: String { t("journal.noReminders", "尚無提醒，點右上「＋」新增疫苗、回診等提醒。") }
    static var journalNoEntries: String { t("journal.noEntries", "尚無日記，點右上「＋」記錄今天的點滴。") }
    static var journalEntryNoText: String { t("journal.entryNoText", "（無文字）") }
    static func journalDaysTogether(_ days: Int) -> String {
        String(format: t("journal.daysTogether", "已陪伴 %d 天"), days)
    }
    static func journalWeightValue(_ weight: Double) -> String {
        String(format: t("journal.weightValue", "%.1f kg"), weight)
    }
    // 表單欄位
    static var journalFieldName: String { t("journal.field.name", "名字") }
    static var journalFieldKind: String { t("journal.field.kind", "種類") }
    static var journalFieldShelter: String { t("journal.field.shelter", "來自收容所（選填）") }
    static var journalFieldAdoptedDate: String { t("journal.field.adoptedDate", "認養日期") }
    static var journalFieldNote: String { t("journal.field.note", "備註（選填）") }
    static var journalFieldDate: String { t("journal.field.date", "日期") }
    static var journalFieldDiary: String { t("journal.field.diary", "今天的點滴") }
    static var journalFieldWeight: String { t("journal.field.weight", "體重（選填）") }
    static var journalFieldWeightHint: String { t("journal.field.weightHint", "例如 5.2（公斤）") }
    static var journalPhotoAdded: String { t("journal.photoAdded", "已選擇照片") }
    static var journalFieldReminderKind: String { t("journal.field.reminderKind", "提醒類型") }
    static var journalFieldReminderTitle: String { t("journal.field.reminderTitle", "提醒內容") }
    static var journalFieldDueDate: String { t("journal.field.dueDate", "提醒時間") }
    static var journalReminderHint: String { t("journal.reminderHint", "時間到時會以本地通知提醒你。") }
    static var journalNotifyDeniedTitle: String { t("journal.notify.denied.title", "未開啟通知") }
    static var journalNotifyDeniedMessage: String { t("journal.notify.denied.message", "提醒已儲存，但需開啟通知權限才會在到期時提醒你。要前往設定開啟嗎？") }
    // 照護提醒類型
    static var careKindVaccine: String { t("care.kind.vaccine", "疫苗") }
    static var careKindDeworm: String { t("care.kind.deworm", "驅蟲") }
    static var careKindCheckup: String { t("care.kind.checkup", "回診") }
    static var careKindMedicine: String { t("care.kind.medicine", "餵藥") }
    static var careKindGrooming: String { t("care.kind.grooming", "美容") }
    static var careKindOther: String { t("care.kind.other", "其他") }

    // MARK: Detail — Live Activity / 已認養
    static var detailLiveStart: String { t("detail.live.start", "開啟認養倒數（鎖定畫面/動態島）") }
    static var detailLiveStop: String { t("detail.live.stop", "結束認養倒數") }
    static var detailLiveUnavailable: String { t("detail.live.unavailable", "無法開啟即時動態，請確認系統已允許「即時動態」。") }
    static var detailMarkAdopted: String { t("detail.markAdopted", "我已認養，建立日記") }

    // MARK: Common — Delete
    static var actionDelete: String { t("action.delete", "刪除") }

    // MARK: Formatted

    /// 分享文字。
    static func shareText(kind: String, shelter: String) -> String {
        String(format: t("share.text", "我在「毛窩 MaoWo」看到一隻待認養的%1$@（%2$@），一起來關心牠吧！"), kind, shelter)
    }

    /// 距離（公尺）。
    static func distanceMeters(_ value: Double) -> String {
        String(format: t("distance.meters", "%.0f 公尺"), value)
    }

    /// 距離（公里）。
    static func distanceKilometers(_ value: Double) -> String {
        String(format: t("distance.kilometers", "%.1f 公里"), value)
    }
}
