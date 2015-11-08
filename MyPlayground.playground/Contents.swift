//: Playground - noun: a place where people can play

import UIKit
import APIKit
import XCPlayground

var str = "Hello, playground"

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

struct Top: RequestToken, DebugRequestToken {
    
    typealias Response = String
    typealias SerializedObject = String
    
    var method: HTTPMethod = .GET
    var baseURL: NSURL? = NSURL(string: "http://www.yahoo.co.jp/")
    var path: String = "/"
    
    func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: SerializedObject) throws -> Response {
        return object
    }
}

let yahoo = API<Error>()

yahoo.request(Top()).onSuccess { value in
    print(value)
    
}

XCPSetExecutionShouldContinueIndefinitely()
