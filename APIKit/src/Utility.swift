//
//  Utility.swift
//  APIKit
//
//  Created by 林達也 on 2015/07/25.
//  Copyright © 2015年 林達也. All rights reserved.
//

import Foundation
import Result

final class Pack {
    let token: Any
    let request: Request
    let uuid: NSUUID
    
    init(_ token: Any, _ request: Request) {
        self.token = token
        self.request = request
        self.uuid = NSUUID()
    }
}

extension Pack: Hashable {
    
    var hashValue: Int {
        return uuid.hashValue
    }
}

func ==(lhs: Pack, rhs: Pack) -> Bool {
    return lhs.uuid == rhs.uuid
}

func url_encode(str: String, characterSet: NSCharacterSet = .URLPathAllowedCharacterSet()) -> String {
    return str.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)!
}

public protocol APIDebugger {
    
    func response(request: NSURLRequest, response: NSHTTPURLResponse, result: Result<String!, NSError>)
}
