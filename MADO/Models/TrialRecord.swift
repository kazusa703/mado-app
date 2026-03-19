import Foundation
import GRDB

struct TrialRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    var sessionId: Int64
    var trialNumber: Int
    var stimulusDurationMs: Double
    var isCorrect: Bool
    var reactionTimeMs: Double
    var eccentricity: Double? // degrees, for Task 2/3
    var angle: Double? // radians, for Task 2/3

    static let databaseTableName = "trials"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
