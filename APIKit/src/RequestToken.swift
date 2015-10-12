//
//  RequestToken.swift
//  APIKit
//
//  Created by 林達也 on 2015/07/25.
//  Copyright © 2015年 林達也. All rights reserved.
//

import Foundation

/**
*  各APIを表現するためのプロトコル定義
*/
public protocol RequestToken {
    
    typealias Response
    typealias SerializedObject
    
    var method: HTTPMethod { get }
    
    var baseURL: NSURL? { get }
    var path: String { get }
    
    var headers: [String: String]? { get }
    var parameters: [String: AnyObject]? { get }
    var encoding: RequestEncoding { get }
    
    var serializer: Serializer { get }
        
    var timeoutInterval: NSTimeInterval? { get }
    
    var statusCode: Set<Int>? { get }
    var contentType: Set<String>? { get }
    
    func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: SerializedObject) throws -> Response
}

public protocol MultipartRequestToken: RequestToken {
    
    var multiparts: [String: FormData] { get }
}

public enum Serializer {
    case Data
    case String(NSStringEncoding)
    case JSON(NSJSONReadingOptions)
    case PropertyList(NSPropertyListReadOptions)
    case Custom
}

public struct FormData {
    
    public init(data: NSData, mimeType: String) {
        
    }
}

public protocol DebugRequestToken {
    
    func printCURL(description: String)
}
