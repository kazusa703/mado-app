import Foundation
import GRDB

actor DatabaseService {
    static let shared = DatabaseService()

    private let dbQueue: DatabaseQueue

    private init() {
        do {
            let url = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("mado.sqlite")

            var config = Configuration()
            config.journalMode = .wal

            dbQueue = try DatabaseQueue(path: url.path, configuration: config)
            try migrator.migrate(dbQueue)
        } catch {
            fatalError("Database setup failed: \(error)")
        }
    }

    private nonisolated var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "sessions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("taskType", .integer).notNull()
                t.column("threshold", .double).notNull()
                t.column("date", .datetime).notNull()
                t.column("duration", .double).notNull()
                t.column("totalTrials", .integer).notNull()
                t.column("correctTrials", .integer).notNull()
            }

            try db.create(table: "trials") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sessionId", .integer).notNull()
                    .references("sessions", onDelete: .cascade)
                t.column("trialNumber", .integer).notNull()
                t.column("stimulusDurationMs", .double).notNull()
                t.column("reactionTimeMs", .double).notNull()
                t.column("isCorrect", .boolean).notNull()
                t.column("eccentricity", .double)
                t.column("angle", .double)
            }
        }

        return migrator
    }

    // MARK: - Session CRUD

    @discardableResult
    func saveSession(_ session: SessionRecord) throws -> SessionRecord {
        try dbQueue.write { db in
            var s = session
            try s.save(db)
            return s
        }
    }

    func saveTrial(_ trial: TrialRecord) throws {
        try dbQueue.write { db in
            var t = trial
            try t.save(db)
        }
    }

    func fetchSessions(taskType: Int? = nil, limit: Int = 50) throws -> [SessionRecord] {
        try dbQueue.read { db in
            var request = SessionRecord.order(Column("date").desc)
            if let taskType {
                request = request.filter(Column("taskType") == taskType)
            }
            return try request.limit(limit).fetchAll(db)
        }
    }

    func fetchLatestSession(taskType: Int) throws -> SessionRecord? {
        try dbQueue.read { db in
            try SessionRecord
                .filter(Column("taskType") == taskType)
                .order(Column("date").desc)
                .fetchOne(db)
        }
    }

    func fetchTrials(sessionId: Int64) throws -> [TrialRecord] {
        try dbQueue.read { db in
            try TrialRecord
                .filter(Column("sessionId") == sessionId)
                .order(Column("trialNumber").asc)
                .fetchAll(db)
        }
    }

    func totalSessionCount() throws -> Int {
        try dbQueue.read { db in
            try SessionRecord.fetchCount(db)
        }
    }

    func streakDays() throws -> Int {
        try dbQueue.read { db in
            let dates = try SessionRecord
                .select(Column("date"))
                .order(Column("date").desc)
                .fetchAll(db)
                .map { Calendar.current.startOfDay(for: $0.date) }

            let uniqueDates = Array(Set(dates)).sorted(by: >)
            guard !uniqueDates.isEmpty else { return 0 }

            var streak = 1
            for i in 1..<uniqueDates.count {
                let diff = Calendar.current.dateComponents([.day], from: uniqueDates[i], to: uniqueDates[i-1])
                if diff.day == 1 {
                    streak += 1
                } else {
                    break
                }
            }

            // Check if streak includes today
            let today = Calendar.current.startOfDay(for: Date())
            if uniqueDates[0] < today {
                let diff = Calendar.current.dateComponents([.day], from: uniqueDates[0], to: today)
                if diff.day ?? 0 > 1 { return 0 }
            }

            return streak
        }
    }

    func bestThreshold(taskType: Int) throws -> Double? {
        try dbQueue.read { db in
            try SessionRecord
                .filter(Column("taskType") == taskType)
                .select(min(Column("threshold")))
                .fetchOne(db)
        }
    }

    func deleteAllData() throws {
        try dbQueue.write { db in
            try TrialRecord.deleteAll(db)
            try SessionRecord.deleteAll(db)
        }
    }
}
