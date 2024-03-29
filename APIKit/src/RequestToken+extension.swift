//
//  RequestToken.swift
//  APIKit
//
//  Created by 林達也 on 2015/07/25.
//  Copyright © 2015年 林達也. All rights reserved.
//

import Foundation

public extension RequestToken {
    
    var baseURL: NSURL? {
        return nil
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var parameters: [String: AnyObject]? {
        return nil
    }
    
    var encoding: RequestEncoding {
        return .URL
    }
    
    var timeoutInterval: NSTimeInterval? {
        return nil
    }
    
    var statusCode: Set<Int>? {
        return nil
    }
    
    var contentType: Set<String>? {
        return nil
    }
}

public extension MultipartRequestToken {
    
    var method: HTTPMethod {
        return .POST
    }
}

public extension DebugRequestToken {
    
    func printCURL(description: String) {
        print(description)
    }
    
    func printResponseString(description: CustomDebugStringConvertible) {
        print(description)
    }
}
