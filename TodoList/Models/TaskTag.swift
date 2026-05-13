import Foundation
import SwiftData

/// A label you can put on many tasks, like Work or Study.
@Model
final class TaskTag {
    var name: String
    var tasks: [PlannerTask] = []

    init(name: String) {
        self.name = name
    }

    /// Cleans up what someone typed: trims spaces and drops any leading #.
    /// "  #Work " becomes "Work". Returns an empty string if nothing is left.
    static func normalize(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds a tag with this name, ignoring upper/lower case.
    static func existing(named name: String, in tags: [TaskTag]) -> TaskTag? {
        let wanted = normalize(name)
        return tags.first { $0.name.caseInsensitiveCompare(wanted) == .orderedSame }
    }
}
