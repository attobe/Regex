import Foundation
import Unicode

/// Equivalent to ICU RegexMatcher.
/// http://icu-project.org/apiref/icu4c/classicu_1_1RegexMatcher.html
final class RegexMatcher: Cloneable {
    /// The regular expression.
    public let pattern: String
    /// Pointer to URegularExpression.
    private let regexp: OpaquePointer
    /// Strong reference to the input characters.
    private var inputChars: [UInt16] = []

    /// Find callback function.
    ///
    /// To set this field, please use `setFindProgressCallback(_:)`.
    private(set) var findProgressCallback: ((RegexMatcher, Int) -> Bool)?

    /// Match callback function.
    ///
    /// To set this field, please use `setMatchCallback(_:)`.
    private(set) var matchCallback: ((RegexMatcher, Int) -> Bool)?

    /// Construct a `RegexMatcher` for a regular expression.
    ///
    /// - parameters:
    ///     - pattern: The regular expression to be compiled.
    ///     - options: Regular expression options.
    /// - throws: If the expression's syntax is invalid
    convenience init(pattern: String, options: RegexOptions) throws {
        let patternChars = Array(pattern.utf16)
        var error = UParseError()
        var status = U_ZERO_ERROR
        let regexp = uregex_open(patternChars, Int32(patternChars.count), options.rawValue, &error, &status)
        if status.rawValue > U_ZERO_ERROR.rawValue {
            throw RegexError.parseError(line: Int(error.line), offset: Int(error.offset))
        }
        self.init(pattern: pattern, regexp: regexp!)
    }

    private init(pattern: String, regexp: OpaquePointer) {
        self.pattern = pattern
        self.regexp = regexp
    }

    /// Resets this matcher, and set the current input position.
    ///
    /// - parameters:
    ///     - index: New input position.
    func reset(index: Int = 0) throws {
        var status = U_ZERO_ERROR
        uregex_reset(regexp, Int32(index), &status)
        try RegexError.throwIfNeeded(status: status)
    }

    /// Resets this matcher with a new input string.
    func reset(_ input: String) throws {
        let inputChars = Array(input.utf16)
        var status = U_ZERO_ERROR
        uregex_setText(regexp, inputChars, Int32(inputChars.count), &status)
        try RegexError.throwIfNeeded(status: status)
        self.inputChars = inputChars
    }

    /// Return true if the most recent matching operation attempted to access additional input beyond the available input text.
    ///
    /// - returns: true if the most recent match hit the end of input.
    func hitEnd() throws -> Bool {
        var status = U_ZERO_ERROR
        let result = uregex_hitEnd(regexp, &status)
        try RegexError.throwIfNeeded(status: status)
        return result != 0
    }

    /// Attempts to match the entire input region against the pattern.
    ///
    /// - parameters:
    ///     - start: The (native) index in the input string to begin the search.
    /// - returns: true if there is a match.
    func matches(start: Int = -1) throws -> Bool {
        var status = U_ZERO_ERROR
        let result = uregex_matches(regexp, Int32(start), &status)
        try RegexError.throwIfNeeded(status: status)
        return result != 0
    }

    /// Find the next pattern match in the input string.
    ///
    /// - returns: true if a match is found.
    func find() throws -> Bool {
        var status = U_ZERO_ERROR
        let result = uregex_findNext(regexp, &status)
        try RegexError.throwIfNeeded(status: status)
        return result != 0
    }

    /// Resets this RegexMatcher and then attempts to find the next substring of the input string that matches the pattern, starting at the specified index.
    ///
    /// - parameters:
    ///     - start: The (native) index in the input string to begin the search.
    /// - returns: true if a match is found.
    func find(start: Int) throws -> Bool {
        var status = U_ZERO_ERROR
        let result = uregex_find(regexp, Int32(start), &status)
        try RegexError.throwIfNeeded(status: status)
        return result != 0
    }

    /// Set a progress callback function for use with find operations on this Matcher.
    func setFindProgressCallback(_ findProgressCallback: ((RegexMatcher, Int) -> Bool)?) throws {
        var status = U_ZERO_ERROR
        if let findProgressCallback = findProgressCallback {
            let pointer = Unmanaged.passUnretained(self).toOpaque()
            self.findProgressCallback = findProgressCallback
            uregex_setFindProgressCallback(regexp, globalFindProgressCallback, pointer, &status)
        } else {
            self.findProgressCallback = nil
            uregex_setFindProgressCallback(regexp, nil, nil, &status)
        }
        try RegexError.throwIfNeeded(status: status)
    }

    /// Set a callback function for use with this Matcher.
    func setMatchCallback(_ matchCallback: ((RegexMatcher, Int) -> Bool)?) throws {
        var status = U_ZERO_ERROR
        if let matchCallback = matchCallback {
            let pointer = Unmanaged.passUnretained(self).toOpaque()
            self.matchCallback = matchCallback
            uregex_setMatchCallback(regexp, globalMatchCallback, pointer, &status)
        } else {
            self.matchCallback = nil
            uregex_setMatchCallback(regexp, nil, nil, &status)
        }
        try RegexError.throwIfNeeded(status: status)
    }

    /// Returns the number of capturing groups in this matcher's pattern.
    ///
    /// - returns: the number of capture groups
    func groupCount() throws -> Int {
        var status = U_ZERO_ERROR
        let result = uregex_groupCount(regexp, &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }

    /// Returns a string containing the text captured by the given group during the previous match operation.
    ///
    /// - parameters:
    ///     - number: the capture group number
    /// - returns: the captured text
    func group(_ number: Int) throws -> String {
        return try withBuffer { buffer, size, status in
            uregex_group(regexp, Int32(number), buffer, size, status)
        }
    }

    /// Returns the index in the input string of the start of the text matched by the specified capture group during the previous match operation.
    ///
    /// - parameters:
    ///     - group: the capture group number
    /// - returns: the (native) start position of substring matched by the specified group
    func start(group: Int = 0) throws -> Int {
        var status = U_ZERO_ERROR
        let result = uregex_start(regexp, Int32(group), &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }

    /// Returns the index in the input string of the character following the text matched by the specified capture group during the previous match operation.
    ///
    /// - parameters:
    ///     - group: the capture group number
    /// - returns: the index of the first character following the text captured by the specified group during the previous match operation
    func end(group: Int = 0) throws -> Int {
        var status = U_ZERO_ERROR
        let result = uregex_end(regexp, Int32(group), &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }

    /// Replaces every substring of the input that matches the pattern with the given replacement string.
    ///
    /// - parameters:
    ///     - replacement: a string containing the replacement text.
    /// - returns: a string containing the results of the find and replace.
    func replaceAll(with replacement: String) throws -> String {
        let replacementChars = Array(replacement.utf16)
        return try withBuffer(size: inputChars.count * 2) { buffer, size, status in
            uregex_replaceAll(regexp, replacementChars, Int32(replacementChars.count), buffer, size, status)
        }
    }

    /// Replaces the first substring of the input that matches the pattern with the replacement string.
    ///
    /// - parameters:
    ///     - replacement: a string containing the replacement text.
    /// - returns: a string in which the results are placed.
    func replaceFirst(with replacement: String) throws -> String {
        let replacementChars = Array(replacement.utf16)
        return try withBuffer(size: inputChars.count * 2) { buffer, size, status in
            uregex_replaceFirst(regexp, replacementChars, Int32(replacementChars.count), buffer, size, status)
        }
    }

    /// Implements a replace operation intended to be used as part of an incremental find-and-replace.
    ///
    /// - parameters:
    ///     - replacement: a string that provides the text to be substituted for the input text that matched the regexp pattern.
    ///     - string: a string to which the results of the find-and-replace are appended.
    func append(replacement: String, to string: inout String) throws {
        let replacementChars = Array(replacement.utf16)
        let result = try withBuffer { buffer, size, status in
            var buffers: [UnsafeMutablePointer<UInt16>?] = [buffer]
            var remaining = size
            return uregex_appendReplacement(regexp, replacementChars, Int32(replacementChars.count), &buffers, &remaining, status)
        }
        string.append(result)
    }

    /// As the final step in a find-and-replace operation, append the remainder of the input string.
    ///
    /// - parameters:
    ///     - string: a string to which the results of the find-and-replace are appended.
    /// - returns: the destination string.
    func appendTail(to string: inout String) throws {
        let result = try withBuffer { buffer, size, status in
            var buffers: [UnsafeMutablePointer<UInt16>?] = [buffer]
            var remaining = size
            return uregex_appendTail(regexp, &buffers, &remaining, status)
        }
        string.append(result)
    }

    func clone() -> RegexMatcher {
        var status = U_ZERO_ERROR
        let regexp = uregex_clone(self.regexp, &status)
        return RegexMatcher(pattern: pattern, regexp: regexp!)
    }

    private func withBuffer(size: Int = Int(BUFSIZ), callback: (UnsafeMutablePointer<UInt16>, Int32, UnsafeMutablePointer<UErrorCode>) throws -> Int32) throws -> String {
        var buffer = Array<UInt16>(repeating: 0, count: size)
        var status = U_ZERO_ERROR
        let length = try callback(&buffer, Int32(buffer.count), &status)
        if status == U_BUFFER_OVERFLOW_ERROR {
            buffer = Array<UInt16>(repeating: 0, count: Int(length))
            status = U_ZERO_ERROR
            _ = try callback(&buffer, Int32(buffer.count), &status)
        }
        try RegexError.throwIfNeeded(status: status)
        return String(utf16CodeUnits: buffer, count: Int(length))
    }

    deinit {
        uregex_close(regexp)
    }
}

private func globalFindProgressCallback(context: UnsafeRawPointer?, index: Int64) -> UBool {
    guard let context = context else { return 1 }
    let matcher = Unmanaged<RegexMatcher>.fromOpaque(context).takeUnretainedValue()

    guard let callback = matcher.findProgressCallback else { return 1 }

    return callback(matcher, Int(index)) ? 1 : 0
}

private func globalMatchCallback(context: UnsafeRawPointer?, steps: Int32) -> UBool {
    guard let context = context else { return 1 }
    let matcher = Unmanaged<RegexMatcher>.fromOpaque(context).takeUnretainedValue()

    guard let callback = matcher.matchCallback else { return 1 }

    return callback(matcher, Int(steps)) ? 1 : 0
}
