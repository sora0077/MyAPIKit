//
//  APIKitTests.swift
//  APIKitTests
//
//  Created by 林達也 on 2015/06/06.
//  Copyright (c) 2015年 林達也. All rights reserved.
//

import UIKit
import XCTest
@testable import APIKit

struct TopPage: RequestToken {
    
    typealias Response = Int
    typealias SerializedObject = String
    
    var method: HTTPMethod = .GET
    var path: String = ""
    
    static func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: TopPage.SerializedObject) throws -> TopPage.Response {
        return 1
    }
}

class APIKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
