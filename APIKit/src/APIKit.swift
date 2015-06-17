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

public let APIKitErrorDomain = "jp.sora0077.APIKit.ErrorDomain"


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
final class Box<T> {
    let unbox: T
    
    init(_ v: T) {
        self.unbox = v
    }
}

func url_encode(str: String, characterSet: NSCharacterSet = .URLPathAllowedCharacterSet()) -> String {
    return str.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)!
}

public protocol APIDebugger {
    
    func response(request: NSURLRequest, response: NSHTTPURLResponse, result: Result<String!>)
}

/**
*
*/
public class API {
    
    private var execQueue: [Request] = []
    private let manager: Alamofire.Manager
    private let baseURL: String
    
    private let debugger: APIDebugger?
    
    public init(baseURL: String = "", configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(), debugger: APIDebugger? = nil) {
        
        self.baseURL = baseURL
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        self.manager = Manager(configuration: configuration)
        self.debugger = debugger
    }
    
    public func additionalHeaders() -> [String: AnyObject]? {
        return nil
    }
    
    public func request<T: RequestToken>(token: T) -> Future<T.Response> {
        let promise = Promise<T.Response>()
        
        func encodedUrl(str: String) -> String {
            if str.hasPrefix("http") {
                var vs = split(str, maxSplit: 2, allowEmptySlices: true, isSeparator: { $0 == "/" })
                let last = vs.count - 1
                vs[last] = url_encode(vs[last])
                return join("/", vs)
            }
            
            return self.baseURL + url_encode(str)
        }
        
        let method = token.method
        let URL = encodedUrl(token.URL)
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
            if let headers = self.additionalHeaders() {
                for (k, v) in headers {
                    URLRequest.addValue(v.description, forHTTPHeaderField: k)
                }
            }
            return URLRequest
            }(),
            parameters: parameters).0
        
        let request = manager.request(URLRequest).validate(statusCode: 200..<300)
        
        self.execQueue.append(request)
        
        request.APIKit_requestToken = Box(token)
        
        if let debugger = debugger {
            request.responseString(encoding: NSUTF8StringEncoding) { URLRequest, response, object, error in
                let result: Result<String!>
                if let e = error {
                    result = Result(error: e)
                } else {
                    result = Result(object)
                }
                debugger.response(URLRequest, response: response!, result: result)
            }
        }
        request.response(serializer: serializer) { [weak self] URLRequest, response, object, error in
            
            if let s = self {
                s.execQueue = s.execQueue.filter({ $0 !== request })
            }
            
            if let error = error {
                promise.failure(error)
                return
            }
            
            if let object = object as? T.SerializedType {
                let serialized = T.transform(URLRequest, response: response, object: object)
                switch serialized {
                case let .Success(box):
                    promise.success(box.value)
                case let .Failure(error):
                    promise.failure(error)
                }
            } else {
                fatalError("The operation couldn’t be completed.")
            }
        }
        
        return promise.future
    }
    
    public func cancel<T: RequestToken>(clazz: T.Type) {
        cancel(clazz, f: { _ in true })
    }
    
    public func cancel<T: RequestToken>(clazz: T.Type, f: T -> Bool) {
        
        for (i, request) in reverse(Array(enumerate(self.execQueue))) {
            if let box = request.APIKit_requestToken as? Box<T> where f(box.unbox)
            {
                request.cancel()
            }
        }
    }
}

/**
*  各APIを表現するためのプロトコル定義
*/
public protocol RequestToken {
    
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
