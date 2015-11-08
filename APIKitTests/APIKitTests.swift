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
    
    func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: TopPage.SerializedObject) throws -> TopPage.Response {
        return 1
    }
}

enum Error: APIKitErrorType {
    
    case Unknown
    
    static func networkError(error: ErrorType) -> Error {
        return .Unknown
    }
    
    static func validationError(error: ErrorType) -> Error {
        return .Unknown
    }
    
    static func serializeError(error: ErrorType) -> Error {
        return .Unknown
    }
    
    static func unsupportedError(error: ErrorType) -> Error {
        return .Unknown
    }
}

struct Top: RequestToken {
    
    typealias Response = String
    typealias SerializedObject = String
    
    var method: HTTPMethod = .GET
    var baseURL: NSURL? = NSURL(string: "http://www.yahoo.co.jp/")
    var path: String = "/"
    
    func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: SerializedObject) throws -> Response {
        return object
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
        
        let yahoo = API<Error>()
        
        yahoo.request(Top()).onSuccess { value in
            print(value)
            
        }

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
