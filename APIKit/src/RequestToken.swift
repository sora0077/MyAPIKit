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
    
    var URL: String { get }
    var headers: [String: String]? { get }
    var parameters: [String: AnyObject]? { get }
    var encoding: RequestEncoding { get }
    
    var serializer: Serializer { get }
        
    var timeoutInterval: NSTimeInterval? { get }
    
    var statusCode: Set<Int>? { get }
    var contentType: Set<String>? { get }
    
    static func transform(request: NSURLRequest?, response: NSHTTPURLResponse?, object: SerializedObject) throws -> Response
}

public enum Serializer {
    case Data
    case String(NSStringEncoding)
    case JSON(NSJSONReadingOptions)
}
