import ActivityKit
import Foundation

public struct SpoofActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var speed: Double
        public var statusText: String
        public var isRouting: Bool
        
        public init(speed: Double, statusText: String, isRouting: Bool) {
            self.speed = speed
            self.statusText = statusText
            self.isRouting = isRouting
        }
    }
    
    public init() {}
}
