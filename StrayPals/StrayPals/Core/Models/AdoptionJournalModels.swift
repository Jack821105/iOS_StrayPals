//
//  AdoptionJournalModels.swift
//  StrayPals (MaoWo)
//
//  「認養後關懷 / 認養日記」的資料模型：
//    - AdoptionRecord：一筆認養紀錄（你帶回家的毛孩）。
//    - JournalEntry：日記條目（文字、照片、體重）。
//    - CareReminder：照護提醒（疫苗、驅蟲、回診…），可排程本地通知。
//

import Foundation

// MARK: - AdoptionRecord

/// 一筆認養紀錄。
struct AdoptionRecord: Codable, Hashable, Identifiable {

    let id: UUID
    var name: String
    var kindRaw: String          // 對應 AnimalKind 的原始字串（狗/貓/其他）
    var shelterName: String
    var adoptedDate: Date
    var photoFilename: String?   // 儲存於 Documents/Journal/Photos
    var sourceAnimalId: Int?     // 若由收藏/詳情帶入，記錄來源動物 id
    var note: String

    init(id: UUID = UUID(),
         name: String,
         kindRaw: String,
         shelterName: String = "",
         adoptedDate: Date = Date(),
         photoFilename: String? = nil,
         sourceAnimalId: Int? = nil,
         note: String = "") {
        self.id = id
        self.name = name
        self.kindRaw = kindRaw
        self.shelterName = shelterName
        self.adoptedDate = adoptedDate
        self.photoFilename = photoFilename
        self.sourceAnimalId = sourceAnimalId
        self.note = note
    }

    var kind: AnimalKind { AnimalKind(raw: kindRaw) }

    /// 已陪伴天數。
    var daysTogether: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: adoptedDate)
        let to = cal.startOfDay(for: Date())
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }
}

// MARK: - JournalEntry

/// 一則日記條目。
struct JournalEntry: Codable, Hashable, Identifiable {

    let id: UUID
    let recordId: UUID
    var date: Date
    var text: String
    var photoFilename: String?
    var weightKg: Double?

    init(id: UUID = UUID(),
         recordId: UUID,
         date: Date = Date(),
         text: String,
         photoFilename: String? = nil,
         weightKg: Double? = nil) {
        self.id = id
        self.recordId = recordId
        self.date = date
        self.text = text
        self.photoFilename = photoFilename
        self.weightKg = weightKg
    }
}

// MARK: - CareReminderKind

/// 照護提醒類型。
enum CareReminderKind: String, Codable, CaseIterable {
    case vaccine, deworm, checkup, medicine, grooming, other

    var symbol: String {
        switch self {
        case .vaccine:  return "syringe"
        case .deworm:   return "ant"
        case .checkup:  return "stethoscope"
        case .medicine: return "pills"
        case .grooming: return "scissors"
        case .other:    return "bell"
        }
    }

    var localizedTitle: String {
        switch self {
        case .vaccine:  return L10n.careKindVaccine
        case .deworm:   return L10n.careKindDeworm
        case .checkup:  return L10n.careKindCheckup
        case .medicine: return L10n.careKindMedicine
        case .grooming: return L10n.careKindGrooming
        case .other:    return L10n.careKindOther
        }
    }
}

// MARK: - CareReminder

/// 一筆照護提醒（對應一則本地通知）。
struct CareReminder: Codable, Hashable, Identifiable {

    let id: UUID
    let recordId: UUID
    var title: String
    var kindRaw: String
    var dueDate: Date
    var notificationId: String
    var isDone: Bool

    init(id: UUID = UUID(),
         recordId: UUID,
         title: String,
         kind: CareReminderKind,
         dueDate: Date,
         isDone: Bool = false) {
        self.id = id
        self.recordId = recordId
        self.title = title
        self.kindRaw = kind.rawValue
        self.dueDate = dueDate
        self.notificationId = "care-\(id.uuidString)"
        self.isDone = isDone
    }

    var kind: CareReminderKind { CareReminderKind(rawValue: kindRaw) ?? .other }

    /// 是否已逾期（未完成且時間已過）。
    var isOverdue: Bool { !isDone && dueDate < Date() }
}
