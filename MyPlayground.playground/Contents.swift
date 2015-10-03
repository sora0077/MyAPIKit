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
}

class Yahoo: API<Error> {
    
    init() {
        super.init(baseURL: "http://www.yahoo.co.jp/")
    }
}


struct Top: RequestToken {
    
    typealias Response = String
    typealias SerializedObject = String
    
    var method: HTTPMethod = .GET
    var URL: String = ""
    
    static func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: SerializedObject) throws -> Response {
        return object
    }
}

let yahoo = Yahoo()

yahoo.request(Top()).onSuccess { value in
    print(value)
     
}


XCPSetExecutionShouldContinueIndefinitely()
