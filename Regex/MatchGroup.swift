import Foundation

public protocol MatchGroup: CustomStringConvertible {
    var input: String { get }
    var range: Range<String.Index> { get }
}
