//
//  APIKit.swift
//  APIKit
//
//  Created by 林達也 on 2015/06/06.
//  Copyright (c) 2015年 林達也. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures

public typealias HTTPMethod = Alamofire.Method
public typealias RequestEncoding = Alamofire.ParameterEncoding
public typealias Request = Alamofire.Request
public typealias Result = BrightFutures.Result


extension Result {
    
    init(error: NSError) {
        self = .Failure(error)
    }
}

public enum ResponseEncoding {
    
    case Data
    case String(NSStringEncoding?)
    case JSON(NSJSONReadingOptions)
    case Custom(Request.Serializer)
    
    var serializer: Request.Serializer {
        switch self {
        case .Data:
            return Request.responseDataSerializer()
        case let .String(encoding):
            return Request.stringResponseSerializer(encoding: encoding)
        case let .JSON(options):
            return Request.JSONResponseSerializer(options: options)
        case let .Custom(serializer):
            return serializer
        }
    }
}

/**
*
*/
public final class API {
    
    private var execQueue: [Request] = []
    private let manager: Alamofire.Manager
    private let baseURL: String
    
    public init(baseURL: String = "", configuration: NSURLSessionConfiguration = .defaultSessionConfiguration()) {
        
        self.baseURL = baseURL
        self.manager = Manager.sharedInstance
    }
    
    public func request<T: RequestToken>(token: T) -> Future<T.Response> {
        let promise = Promise<T.Response>()
        
        let method = token.method
        let URL = self.baseURL + token.URL
        let parameters = token.parameters
        let encoding = token.encoding
        let serializer = token.resonseEncoding.serializer
        
        
        let URLRequest = encoding.encode({ () -> NSURLRequest in
            let URLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
            URLRequest.HTTPMethod = method.rawValue
            if let headers = token.headers {
                for (k, v) in headers {
                    URLRequest.addValue(v.description, forHTTPHeaderField: k)
                }
            }
            return URLRequest
            }(),
            parameters: parameters).0
        
        let request = manager.request(URLRequest)
        self.execQueue.append(request)
        
        request.APIKit_requestToken = token
        
        request.validate().response(serializer: serializer) { [weak self] (URLRequest, response, object, error) -> Void in
            
            if let s = self {
                s.execQueue = s.execQueue.filter({ $0 !== request })
            }
            
            if let error = error {
                promise.failure(error)
                return
            }
            
            let serialized = T.transform(URLRequest, response: response, object: object as! T.SerializedType)
            switch serialized {
            case let .Success(box):
                promise.success(box.value)
            case let .Failure(error):
                promise.failure(error)
            }
        }
        
        return promise.future
    }
    
    public func cancel<T: RequestToken>(clazz: T.Type) {
        cancel(clazz, f: { _ in true })
    }
    
    public func cancel<T: RequestToken>(clazz: T.Type, f: T -> Bool) {
        
        for request in self.execQueue {
            if let token = request.APIKit_requestToken as? T where f(token) {
                request.cancel()
            }
        }
    }
}

/**
*  各APIを表現するためのプロトコル定義
*/
public protocol RequestToken: class {
    
    typealias Response
    typealias SerializedType
    
    var method: HTTPMethod { get }
    var URL: String { get }
    var headers: [String: AnyObject]? { get }
    var parameters: [String: AnyObject]? { get }
    var encoding: RequestEncoding { get }
    
    var resonseEncoding: ResponseEncoding { get }
    
    static func transform(request: NSURLRequest, response: NSHTTPURLResponse?, object: SerializedType) -> Result<Response>
}

private var AlamofireRequest_APIKit_requestToken: UInt8 = 0
private extension Alamofire.Request {
    
    
    private var APIKit_requestToken: AnyObject? {
        get {
            return objc_getAssociatedObject(self, &AlamofireRequest_APIKit_requestToken)
        }
        set {
            objc_setAssociatedObject(self, &AlamofireRequest_APIKit_requestToken, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
}
