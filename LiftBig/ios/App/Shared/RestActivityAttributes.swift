import ActivityKit
import Foundation

public struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endsAt: Date
        public init(endsAt: Date) { self.endsAt = endsAt }
    }

    public var title: String
    public init(title: String) { self.title = title }
}
