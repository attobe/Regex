import Foundation

public struct Match: MatchGroup {
    let pattern: Pattern

    public let input: String
    public let range: Range<String.Index>
    private(set) var groups: [MatchGroup?]

    public var description: String {
        return String(input[range])
    }

    init(pattern: Pattern,
         input: String,
         range: Range<String.Index>,
         groupRanges: [Range<String.Index>?]) {
        self.pattern = pattern
        self.input = input
        self.range = range
        self.groups = groupRanges.map { range in
            if let range = range {
                return Group(input: input, range: range)
            } else {
                return nil
            }
        }
        assert(groups.count == pattern.groupCount, "Invalid group count")
    }

    private struct Group: MatchGroup {
        let input: String
        let range: Range<String.Index>

        var description: String {
            return String(input[range])
        }
    }
}

extension Match: RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return pattern.groupCount
    }

    public subscript(position: Int) -> MatchGroup? {
        if position == 0 {
            return self
        }
        return groups[position - 1]
    }
}

extension Match {
    public func getGroup(for name: String) throws -> MatchGroup? {
        return try self[pattern.getGroupNumber(from: name)]
    }

    public subscript(groupName: String) -> MatchGroup? {
        do {
            return try getGroup(for: groupName)
        } catch {
            return nil
        }
    }
}
