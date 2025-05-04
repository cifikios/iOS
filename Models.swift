import Foundation

struct LocationSession: Identifiable, Codable, Comparable {
    let id: UUID
    let date: Date
    let fastestLap: String
    let slowestLap: String
    let averageLap: String
    let consistency: String
    let lapTimes: [String]
    let sectorTimes: [[String]]? // Nested array for sectors per lap
    let location: String?
    let totalTime: String

    // Implement Comparable
    static func < (lhs: LocationSession, rhs: LocationSession) -> Bool {
        return lhs.date < rhs.date
    }
}
