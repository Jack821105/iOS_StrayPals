//
//  AdoptionJournalManager.swift
//  StrayPals (MaoWo)
//
//  【設計模式：單例 Singleton】
//  管理「認養紀錄 / 日記 / 照護提醒」的儲存與查詢。資料以 JSON 持久化於
//  Documents/Journal，照片另存於 Photos 子目錄。照護提醒會排程「本地通知」
//  （UNUserNotificationCenter），到期提醒飼主疫苗、回診、驅蟲等事項。
//

import UIKit
import UserNotifications

// MARK: - AdoptionJournalManager

final class AdoptionJournalManager {

    // MARK: Singleton

    static let shared = AdoptionJournalManager()

    /// 資料變動通知（畫面收到後刷新）。
    static let didChangeNotification = Notification.Name("AdoptionJournalManager.didChange")

    // MARK: State

    private(set) var records: [AdoptionRecord] = []
    private var entries: [JournalEntry] = []
    private var reminders: [CareReminder] = []

    // MARK: Storage

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var baseDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Journal", isDirectory: true)
    }
    private var photosDir: URL { baseDir.appendingPathComponent("Photos", isDirectory: true) }
    private var recordsURL: URL { baseDir.appendingPathComponent("records.json") }
    private var entriesURL: URL { baseDir.appendingPathComponent("entries.json") }
    private var remindersURL: URL { baseDir.appendingPathComponent("reminders.json") }

    // MARK: Init

    private init() {
        createDirectoriesIfNeeded()
        load()
    }

    // MARK: Records

    func record(id: UUID) -> AdoptionRecord? {
        records.first { $0.id == id }
    }

    func addRecord(_ record: AdoptionRecord) {
        records.insert(record, at: 0)
        persistRecords()
        notifyChange()
    }

    func updateRecord(_ record: AdoptionRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        persistRecords()
        notifyChange()
    }

    func deleteRecord(_ record: AdoptionRecord) {
        // 連帶刪除日記、提醒、照片與通知。
        for entry in entries(for: record.id) { deletePhoto(entry.photoFilename) }
        for reminder in reminders(for: record.id) { cancelNotification(reminder.notificationId) }
        deletePhoto(record.photoFilename)

        entries.removeAll { $0.recordId == record.id }
        reminders.removeAll { $0.recordId == record.id }
        records.removeAll { $0.id == record.id }

        persistRecords(); persistEntries(); persistReminders()
        notifyChange()
    }

    // MARK: Entries

    /// 某筆認養紀錄的日記（新到舊）。
    func entries(for recordId: UUID) -> [JournalEntry] {
        entries.filter { $0.recordId == recordId }.sorted { $0.date > $1.date }
    }

    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        persistEntries()
        notifyChange()
    }

    func deleteEntry(_ entry: JournalEntry) {
        deletePhoto(entry.photoFilename)
        entries.removeAll { $0.id == entry.id }
        persistEntries()
        notifyChange()
    }

    /// 體重歷史（舊到新），供趨勢顯示。
    func weightHistory(for recordId: UUID) -> [(date: Date, weight: Double)] {
        entries(for: recordId)
            .compactMap { entry in entry.weightKg.map { (entry.date, $0) } }
            .sorted { $0.0 < $1.0 }
    }

    // MARK: Reminders

    /// 某筆認養紀錄的提醒（依到期時間）。
    func reminders(for recordId: UUID) -> [CareReminder] {
        reminders.filter { $0.recordId == recordId }.sorted { $0.dueDate < $1.dueDate }
    }

    /// 所有「未完成、未來」的提醒（跨毛孩，最近者在前）。
    func upcomingReminders() -> [CareReminder] {
        reminders.filter { !$0.isDone && $0.dueDate >= Date() }.sorted { $0.dueDate < $1.dueDate }
    }

    func addReminder(_ reminder: CareReminder) {
        reminders.append(reminder)
        persistReminders()
        scheduleNotification(for: reminder)
        notifyChange()
    }

    func toggleReminderDone(_ reminder: CareReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isDone.toggle()
        if reminders[index].isDone {
            cancelNotification(reminder.notificationId)
        } else {
            scheduleNotification(for: reminders[index])
        }
        persistReminders()
        notifyChange()
    }

    func deleteReminder(_ reminder: CareReminder) {
        cancelNotification(reminder.notificationId)
        reminders.removeAll { $0.id == reminder.id }
        persistReminders()
        notifyChange()
    }

    // MARK: Notifications

    /// 請求通知授權（首次新增提醒時呼叫）。
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    private func scheduleNotification(for reminder: CareReminder) {
        guard reminder.dueDate > Date(), !reminder.isDone else { return }
        let petName = record(id: reminder.recordId)?.name ?? L10n.journalDefaultName

        let content = UNMutableNotificationContent()
        content.title = "🐾 \(petName)"
        content.body = reminder.title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: Photos

    /// 儲存照片，回傳檔名（失敗回 nil）。
    @discardableResult
    func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let url = photosDir.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    func loadPhoto(_ filename: String?) -> UIImage? {
        guard let filename else { return nil }
        let url = photosDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func deletePhoto(_ filename: String?) {
        guard let filename else { return }
        try? fileManager.removeItem(at: photosDir.appendingPathComponent(filename))
    }

    // MARK: Persistence

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)
    }

    private func load() {
        records = decode([AdoptionRecord].self, from: recordsURL) ?? []
        entries = decode([JournalEntry].self, from: entriesURL) ?? []
        reminders = decode([CareReminder].self, from: remindersURL) ?? []
        // 依認養日新到舊。
        records.sort { $0.adoptedDate > $1.adoptedDate }
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func persistRecords() { persist(records, to: recordsURL) }
    private func persistEntries() { persist(entries, to: entriesURL) }
    private func persistReminders() { persist(reminders, to: remindersURL) }

    private func persist<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url)
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
