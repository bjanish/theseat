import Foundation

enum SeatMessage: Codable, Sendable {
    case join(name: String, deviceID: String)
    case welcome(hostName: String)
    case question(text: String)
    case currentQuestion(text: String)
    case passTheSeat(toName: String)
    case youAreHost
    case newHost(name: String)
    case sessionEnd
    case heartbeat
}
