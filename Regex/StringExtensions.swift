import Foundation

extension String {
    public init(_ group: MatchGroup) {
        self.init(group.input[group.range])
    }

    public func replacing(_ pattern: Pattern, with replace: (Match) -> String?) -> String {
        do {
            let matcher = try pattern.createMatcher(for: self)
            var dest = ""
            while try matcher.find() {
                guard let replacement = try replace(matcher.toMatch())
                    else { break }
                try matcher.append(plainReplacement: replacement, to: &dest)
            }
            try matcher.appendTail(to: &dest)
            return dest
        } catch {
            return self
        }
    }

    public func replacing(_ regex: Regex, with replace: (Match) -> String?) -> String {
        return replacing(regex.pattern, with: replace)
    }

    public func replacing(pattern: StaticString, with replace: (Match) -> String?) -> String {
        return replacing(Regex(pattern, options: .default), with: replace)
    }

    public func replacing(_ pattern: Pattern, with replacement: String) -> String {
        do {
            let matcher = try pattern.createMatcher(for: self)
            var dest = ""
            while try matcher.find() {
                try matcher.append(replacement: replacement, to: &dest)
            }
            try matcher.appendTail(to: &dest)
            return dest
        } catch {
            return self
        }
    }

    public func replacing(_ regex: Regex, with replacement: String) -> String {
        return replacing(regex.pattern, with: replacement)
    }

    public func replacing(pattern: StaticString, with replacement: String) -> String {
        return replacing(Regex(pattern, options: .default), with: replacement)
    }

    public func split(by pattern: Pattern, limit: Int = 0) -> [String] {
        do {
            let matcher = try pattern.createMatcher(for: self)
            var result: [String] = []
            var start = startIndex
            while try (limit == 0 || result.count < limit - 1) && matcher.find() {
                try result.append(String(self[start..<matcher.start()]))
                start = try matcher.end()
            }
            result.append(String(self[start..<endIndex]))
            return result
        } catch {
            return []
        }
    }

    public func split(by regex: Regex, limit: Int = 0) -> [String] {
        return split(by: regex.pattern, limit: limit)
    }

    public func split(byPattern pattern: StaticString, limit: Int = 0) -> [String] {
        return split(by: Regex(pattern, options: .default), limit: limit)
    }
}
