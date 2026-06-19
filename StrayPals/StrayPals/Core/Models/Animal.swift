//
//  Animal.swift
//  StrayPals
//
//  流浪／待認養動物的資料模型，對應農業部開放資料 API 欄位。
//  以自訂解碼器容忍缺漏欄位，並提供大量「顯示用」的衍生屬性，
//  讓 View 層不需要處理原始代碼（如 M/F、ADULT/CHILD）。
//

import Foundation

// MARK: - AnimalKind

/// 動物種類。
enum AnimalKind: String {
    case dog = "狗"
    case cat = "貓"
    case other = "其他"

    /// 由 API 原始字串建立。
    init(raw: String) {
        switch raw {
        case "狗", "犬": self = .dog
        case "貓": self = .cat
        default: self = .other
        }
    }

    /// 對應的 SF Symbol 圖示名稱。
    var symbolName: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .other: return "pawprint.fill"
        }
    }

    /// 在地化顯示名稱。
    var localizedName: String {
        switch self {
        case .dog: return L10n.kindDog
        case .cat: return L10n.kindCat
        case .other: return L10n.kindOther
        }
    }
}

// MARK: - Animal

/// 一筆待認養動物資料。
struct Animal: Codable, Hashable, Identifiable {

    // MARK: Stored Properties

    let id: Int                 // animal_id
    let subId: String           // animal_subid
    let areaId: Int             // animal_area_pkid
    let shelterId: Int          // animal_shelter_pkid
    let kindRaw: String         // animal_kind
    let varietyRaw: String      // animal_Variety（注意大寫 V）
    let sexRaw: String          // animal_sex  M/F/N
    let bodyTypeRaw: String     // animal_bodytype SMALL/MEDIUM/BIG
    let colour: String          // animal_colour
    let ageRaw: String          // animal_age  ADULT/CHILD
    let sterilizationRaw: String // animal_sterilization T/F/N
    let bacterinRaw: String     // animal_bacterin T/F
    let foundPlace: String      // animal_foundplace
    let statusRaw: String       // animal_status
    let remark: String          // animal_remark
    let openDate: String        // animal_opendate
    let closedDate: String      // animal_closeddate（認養開放截止日）
    let updateDate: String      // animal_update
    let shelterName: String     // shelter_name
    let albumFile: String       // album_file（照片網址）
    let shelterAddress: String  // shelter_address
    let shelterTel: String      // shelter_tel

    // MARK: CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id = "animal_id"
        case subId = "animal_subid"
        case areaId = "animal_area_pkid"
        case shelterId = "animal_shelter_pkid"
        case kindRaw = "animal_kind"
        case varietyRaw = "animal_Variety"
        case sexRaw = "animal_sex"
        case bodyTypeRaw = "animal_bodytype"
        case colour = "animal_colour"
        case ageRaw = "animal_age"
        case sterilizationRaw = "animal_sterilization"
        case bacterinRaw = "animal_bacterin"
        case foundPlace = "animal_foundplace"
        case statusRaw = "animal_status"
        case remark = "animal_remark"
        case openDate = "animal_opendate"
        case closedDate = "animal_closeddate"
        case updateDate = "animal_update"
        case shelterName = "shelter_name"
        case albumFile = "album_file"
        case shelterAddress = "shelter_address"
        case shelterTel = "shelter_tel"
    }

    // MARK: Decodable（容錯：缺漏欄位給預設值）

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        subId = (try? c.decode(String.self, forKey: .subId)) ?? ""
        areaId = (try? c.decode(Int.self, forKey: .areaId)) ?? 0
        shelterId = (try? c.decode(Int.self, forKey: .shelterId)) ?? 0
        kindRaw = (try? c.decode(String.self, forKey: .kindRaw)) ?? ""
        varietyRaw = (try? c.decode(String.self, forKey: .varietyRaw)) ?? ""
        sexRaw = (try? c.decode(String.self, forKey: .sexRaw)) ?? ""
        bodyTypeRaw = (try? c.decode(String.self, forKey: .bodyTypeRaw)) ?? ""
        colour = (try? c.decode(String.self, forKey: .colour)) ?? ""
        ageRaw = (try? c.decode(String.self, forKey: .ageRaw)) ?? ""
        sterilizationRaw = (try? c.decode(String.self, forKey: .sterilizationRaw)) ?? ""
        bacterinRaw = (try? c.decode(String.self, forKey: .bacterinRaw)) ?? ""
        foundPlace = (try? c.decode(String.self, forKey: .foundPlace)) ?? ""
        statusRaw = (try? c.decode(String.self, forKey: .statusRaw)) ?? ""
        remark = (try? c.decode(String.self, forKey: .remark)) ?? ""
        openDate = (try? c.decode(String.self, forKey: .openDate)) ?? ""
        closedDate = (try? c.decode(String.self, forKey: .closedDate)) ?? ""
        updateDate = (try? c.decode(String.self, forKey: .updateDate)) ?? ""
        shelterName = (try? c.decode(String.self, forKey: .shelterName)) ?? ""
        albumFile = (try? c.decode(String.self, forKey: .albumFile)) ?? ""
        shelterAddress = (try? c.decode(String.self, forKey: .shelterAddress)) ?? ""
        shelterTel = (try? c.decode(String.self, forKey: .shelterTel)) ?? ""
    }
}

// MARK: - Display Helpers

extension Animal {

    /// 種類列舉。
    var kind: AnimalKind { AnimalKind(raw: kindRaw) }

    /// 照片網址（可能為空）。
    var imageURL: URL? {
        let trimmed = albumFile.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : URL(string: trimmed)
    }

    /// 品種（去除 API 多餘空白）。
    var variety: String {
        let trimmed = varietyRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.notProvided : trimmed
    }

    /// 標題名稱：API 未提供名字，故以「種類 · 編號」呈現。
    var displayName: String {
        "\(kind.localizedName) · \(subId.isEmpty ? "\(id)" : subId)"
    }

    /// 性別文字。
    var sexText: String {
        switch sexRaw.uppercased() {
        case "M": return L10n.sexMale
        case "F": return L10n.sexFemale
        default: return L10n.unknown
        }
    }

    /// 年齡文字。
    var ageText: String {
        switch ageRaw.uppercased() {
        case "ADULT": return L10n.ageAdult
        case "CHILD": return L10n.ageChild
        default: return L10n.unknown
        }
    }

    /// 體型文字。
    var bodyTypeText: String {
        switch bodyTypeRaw.uppercased() {
        case "SMALL": return L10n.bodySmall
        case "MEDIUM": return L10n.bodyMedium
        case "BIG", "LARGE": return L10n.bodyBig
        default: return L10n.unknown
        }
    }

    /// 是否已絕育。
    var isSterilized: Bool { sterilizationRaw.uppercased() == "T" }

    /// 是否已打疫苗。
    var isVaccinated: Bool { bacterinRaw.uppercased() == "T" }

    /// 絕育文字。
    var sterilizationText: String { isSterilized ? L10n.sterilizedYes : L10n.sterilizedNo }

    /// 開放認養中。
    var isOpen: Bool { statusRaw.uppercased() == "OPEN" }

    /// 毛色（容錯）。
    var colourText: String {
        let trimmed = colour.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.notProvided : trimmed
    }

    /// 備註（容錯）。
    var remarkText: String {
        let trimmed = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.noRemark : trimmed
    }

    /// 所在縣市：先從收容所地址比對已知縣市，再退而從收容所名稱判斷。
    var city: String {
        let source = shelterAddress.isEmpty ? shelterName : shelterAddress
        for name in Self.taiwanCities where source.contains(name) {
            return name
        }
        return "其他"
    }

    /// 認養開放截止日（解析失敗或為遠期 2999 視為「無截止」）。
    var closedDateValue: Date? {
        let trimmed = closedDate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("2999") else { return nil }
        return Self.dateFormatter.date(from: trimmed)
    }

    /// 距離截止還有幾天（無截止回傳 nil）。
    var daysUntilClosed: Int? {
        guard let closed = closedDateValue else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                                   to: Calendar.current.startOfDay(for: closed)).day
        return days
    }

    /// 是否急需認養：開放中且 14 天內截止。
    var isUrgent: Bool {
        guard isOpen, let days = daysUntilClosed else { return false }
        return (0...14).contains(days)
    }

    /// 解析 API 日期字串的共用 formatter。
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// 全台縣市清單（含臺/台異體字），用於地區比對與篩選選單。
    static let taiwanCities: [String] = [
        "臺北市", "台北市", "新北市", "基隆市", "桃園市", "新竹市", "新竹縣",
        "苗栗縣", "臺中市", "台中市", "彰化縣", "南投縣", "雲林縣",
        "嘉義市", "嘉義縣", "臺南市", "台南市", "高雄市", "屏東縣",
        "宜蘭縣", "花蓮縣", "臺東縣", "台東縣", "澎湖縣", "金門縣", "連江縣"
    ]
}

// MARK: - AnimalListResponse

/// API 直接回傳的是一個 JSON 陣列，型別別名讓呼叫端語意更清楚。
typealias AnimalListResponse = [Animal]
