//
//  RegexTests.swift
//  RegexTests
//
//  Created by 戸部敦 on 2019/01/17.
//

import XCTest
@testable import Regex

class RegexTests: XCTestCase {

    func testExample() throws {
        print(try Regex(dynamic: "[abc]").matches("a"))
        print(try Regex(dynamic: "[abc]").matches("d"))
    }
}
