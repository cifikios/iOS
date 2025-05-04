import Foundation

struct TimeFormatter {
    // Format TimeInterval into "MM:SS:MS" string
    static func formatTime(_ time: TimeInterval) -> String {
        let totalMilliseconds = Int(time * 1000) // Convert to milliseconds
        let minutes = (totalMilliseconds / 60000) % 60
        let seconds = (totalMilliseconds / 1000) % 60
        let milliseconds = totalMilliseconds % 1000 / 10 // Only two digits for milliseconds
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    }
}
