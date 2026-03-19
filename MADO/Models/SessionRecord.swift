import Foundation
import GRDB

struct SessionRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    var taskType: Int // 1, 2, 3
    var threshold: Double // ms
    var date: Date
    var duration: TimeInterval // seconds
    var totalTrials: Int
    var correctTrials: Int

    static let databaseTableName = "sessions"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
