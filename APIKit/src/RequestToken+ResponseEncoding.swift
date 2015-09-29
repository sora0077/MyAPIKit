//
//  RequestToken+ResponseEncoding.swift
//  APIKit
//
//  Created by 林達也 on 2015/07/25.
//  Copyright © 2015年 林達也. All rights reserved.
//

import Foundation


//MARK:
public extension RequestToken where SerializedObject == Any {
    
    var serializer: Serializer {
        return .Data
    }
}

public extension RequestToken where SerializedObject == Any? {
    
    var serializer: Serializer {
        return .Data
    }
}

public extension RequestToken where SerializedObject == Any! {
    
    var serializer: Serializer {
        return .Data
    }
}

//MARK:
public extension RequestToken where SerializedObject == NSData {
    
    var serializer: Serializer {
        return .Data
    }
}

public extension RequestToken where SerializedObject == NSData? {
    
    var serializer: Serializer {
        return .Data
    }
}

public extension RequestToken where SerializedObject == NSData! {
    
    var serializer: Serializer {
        return .Data
    }
}

//MARK:
public extension RequestToken where SerializedObject == String {
    
    var serializer: Serializer {
        return .String(NSUTF8StringEncoding)
    }
}

public extension RequestToken where SerializedObject == String? {
    
    var serializer: Serializer {
        return .String(NSUTF8StringEncoding)
    }
}

public extension RequestToken where SerializedObject == String! {
    
    var serializer: Serializer {
        return .String(NSUTF8StringEncoding)
    }
}

//MARK:
public extension RequestToken where SerializedObject == [String: AnyObject] {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [String: AnyObject]? {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [String: AnyObject]! {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

//MARK:
public extension RequestToken where SerializedObject == [[String: AnyObject]] {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [[String: AnyObject]]? {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [[String: AnyObject]]! {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

//MARK:
public extension RequestToken where SerializedObject == [AnyObject] {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [AnyObject]? {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}

public extension RequestToken where SerializedObject == [AnyObject]! {
    
    var serializer: Serializer {
        return .JSON(.AllowFragments)
    }
}
