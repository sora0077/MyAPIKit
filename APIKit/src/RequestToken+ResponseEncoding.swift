//
//  RequestToken+ResponseEncoding.swift
//  APIKit
//
//  Created by 林達也 on 2015/07/25.
//  Copyright © 2015年 林達也. All rights reserved.
//

import Foundation


//MARK:
public extension RequestToken where SerializedType == NSData {
    
    var responseEncoding: ResponseEncoding {
        return .Data
    }
}

public extension RequestToken where SerializedType == NSData? {
    
    var responseEncoding: ResponseEncoding {
        return .Data
    }
}

public extension RequestToken where SerializedType == NSData! {
    
    var responseEncoding: ResponseEncoding {
        return .Data
    }
}

//MARK:
public extension RequestToken where SerializedType == String {
    
    var responseEncoding: ResponseEncoding {
        return .String(NSUTF8StringEncoding)
    }
}

public extension RequestToken where SerializedType == String? {
    
    var responseEncoding: ResponseEncoding {
        return .String(NSUTF8StringEncoding)
    }
}

public extension RequestToken where SerializedType == String! {
    
    var responseEncoding: ResponseEncoding {
        return .String(NSUTF8StringEncoding)
    }
}

//MARK:
public extension RequestToken where SerializedType == [String: AnyObject] {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [String: AnyObject]? {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [String: AnyObject]! {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

//MARK:
public extension RequestToken where SerializedType == [[String: AnyObject]] {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [[String: AnyObject]]? {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [[String: AnyObject]]! {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

//MARK:
public extension RequestToken where SerializedType == [AnyObject] {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [AnyObject]? {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedType == [AnyObject]! {
    
    var responseEncoding: ResponseEncoding {
        return .JSON(.AllowFragments)
    }
}
