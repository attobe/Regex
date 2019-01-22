import Foundation

public struct Regex {
    public let pattern: Pattern

    public init(_ pattern: StaticString, options: RegexOptions = .default) {
        try! self.init(dynamic: pattern.description, options: options)
    }

    public init(dynamic pattern: String, options: RegexOptions = .default) throws {
        self.pattern = try Pattern(pattern, options: options)
    }

    public func matches(_ string: String) -> Bool {
        do {
            let matcher = try pattern.createMatcher(for: string)
            return try matcher.matches()
        } catch {
            return false
        }
    }

    public func first(_ string: String, from offset: String.Index? = nil) -> Match? {
        do {
            let matcher = try pattern.createMatcher(for: string)
            guard try matcher.find(start: offset ?? string.startIndex)
                else { return nil }
            return try matcher.toMatch()
        } catch {
            return nil
        }
    }

    public func all(_ string: String) -> [Match] {
        do {
            let matcher = try pattern.createMatcher(for: string)
            var matches: [Match] = []
            while try matcher.find() {
                try matches.append(matcher.toMatch())
            }
            return matches
        } catch {
            return []
        }
    }
}

public func ~= (regex: Regex, string: String) -> Bool {
    return regex.matches(string)
}

public func ~= (string: String, regex: Regex) -> Bool {
    return regex.matches(string)
}
