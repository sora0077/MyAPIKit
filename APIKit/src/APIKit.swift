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
import Result

public typealias HTTPMethod = Alamofire.Method
public typealias RequestEncoding = Alamofire.ParameterEncoding
public typealias Request = Alamofire.Request

public let APIKitErrorDomain = "jp.sora0077.APIKit.ErrorDomain"

/**
* ErrorType for APIKit
*/
public protocol APIKitErrorType: ErrorType {
    
    static func NetworkError(error: ErrorType) -> Self
    
    static func SerializeError(error: ErrorType) -> Self
    
    static func ValidationError(error: ErrorType) -> Self
}


/**
* API control class
*/
public class API<Error: APIKitErrorType> {
    
    private var execQueue: Set<Pack> = []
    private let manager: Alamofire.Manager
    private let baseURL: String
    
    private let debugger: APIDebugger?
    
    public init(baseURL: String = "", configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(), debugger: APIDebugger? = nil) {
        
        self.baseURL = baseURL
        if configuration.HTTPAdditionalHeaders == nil {
            configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        } else {
            for (k, v) in Manager.defaultHTTPHeaders {
                if configuration.HTTPAdditionalHeaders?[k] != nil {
                    configuration.HTTPAdditionalHeaders?[k] = v
                }
            }
        }
        self.manager = Manager(configuration: configuration)
        self.debugger = debugger
    }

    public func additionalHeaders() -> [String: AnyObject]? {
        return nil
    }
    
//    public func updateURLRequest(request: NSMutableURLRequest) {
//        
//    }
    
    /**
    validate(request:response:object)
    
    :param: URLRequest <#URLRequest description#>
    :param: resonse    <#resonse description#>
    :param: object     <#object description#>
    
    :returns: <#return value description#>
    */
    public func validate(request URLRequest: NSURLRequest, response: NSHTTPURLResponse, object: AnyObject?) -> Error? {
        return nil
    }

    /**
    cancel(_:)
    
    :param: clazz <#clazz description#>
    */
    public func cancel<T: RequestToken>(clazz: T.Type, _ f: T -> Bool = { _ in true }) {
        
        for pack in execQueue {
            if let token = pack.token as? T where f(token) {
                Queue.global.async {
                    pack.request.cancel()
                }
            }
        }
    }
}

extension API {
    
    /**
    request()
    
    :param: token RequestToken protocol
    
    :returns: Future<T.Response, APIKitError<Error>>
    */
    public final func request<T: RequestToken>(token: T) -> Future<T.Response, Error> {
        let promise = Promise<T.Response, Error>()
        
        let serializer = token.resonseEncoding.serializer
        let request = createRequest(token)
        let boxed = Pack(token, request)
        
        execQueue.insert(boxed)
        
        request.APIKit_requestToken = boxed
        
        request.response(serializer: serializer) { [weak self] URLRequest, response, object, error in
            self?.response(promise, token: token, pack: boxed, URLRequest: URLRequest, response: response, object: object, error: error)
        }
        
        return promise.future
    }

    /**
    request()
    
    :param: token RequestToken protocol with Optional Type
    
    :returns: Future<T.Response, APIKitError<Error>>
    */
    public final func request<T: RequestToken, U where T.SerializedType == Optional<U>>(token: T) -> Future<T.Response, Error> {
        let promise = Promise<T.Response, Error>()
        
        let serializer = token.resonseEncoding.serializer
        let request = createRequest(token)
        let boxed = Pack(token, request)
        
        execQueue.insert(boxed)
        
        request.APIKit_requestToken = boxed
        
        request.response(serializer: serializer) { [weak self] URLRequest, response, object, error in
            self?.responseNilable(promise, token: token, pack: boxed, URLRequest: URLRequest, response: response, object: object, error: error)
        }
        
        return promise.future
    }

    /**
    request()
    
    :param: token RequestToken protocol with Any Type
    
    :returns: Future<T.Response, APIKitError<Error>>
    */
    public final func request<T: RequestToken where T.SerializedType == Any>(token: T) -> Future<T.Response, Error> {
        let promise = Promise<T.Response, Error>()
        
        let serializer = token.resonseEncoding.serializer
        let request = createRequest(token)
        let boxed = Pack(token, request)
        
        execQueue.insert(boxed)
        
        request.APIKit_requestToken = boxed
        
        request.response(serializer: serializer) { [weak self] URLRequest, response, object, error in
            self?.responseAnyable(promise, token: token, pack: boxed, URLRequest: URLRequest, response: response, object: object, error: error)
        }
        
        return promise.future
    }
}

//
extension API {

    final func responseNilable<T: RequestToken, U where T.SerializedType == Optional<U>>(promise: Promise<T.Response, Error>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.NetworkError(error))
            return
        }
        
        if  let response = response,
            let error = validate(request: URLRequest!, response: response, object: object)
        {
            try! promise.failure(error)
            return
        }
        
        do {
            let serialized = try T.transform(URLRequest!, response: response, object: object as? U)
            try! promise.success(serialized)
        }
        catch let error {
            try! promise.failure(.SerializeError(error))
        }
    }

    final func responseAnyable<T: RequestToken where T.SerializedType == Any>(promise: Promise<T.Response, Error>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.NetworkError(error))
            return
        }
        
        if  let response = response,
            let error = validate(request: URLRequest!, response: response, object: object)
        {
            try! promise.failure(error)
            return
        }
        
        do {
            let serialized = try T.transform(URLRequest!, response: response, object: object)
            try! promise.success(serialized)
        }
        catch let error {
            try! promise.failure(.SerializeError(error))
        }
    }
    
    final func response<T: RequestToken>(promise: Promise<T.Response, Error>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.NetworkError(error))
            return
        }
        
        if  let response = response,
            let error = validate(request: URLRequest!, response: response, object: object)
        {
            try! promise.failure(error)
            return
        }
        
        do {
            let serialized = try T.transform(URLRequest!, response: response, object: object as! T.SerializedType)
            try! promise.success(serialized)
        }
        catch let error {
            try! promise.failure(.SerializeError(error))
        }
    }
}


extension API {
    
    private final func createRequest<T: RequestToken>(token: T) -> Request {
        
        func encodedUrl(str: String) -> String {
            if str.hasPrefix("http") {
                var vs = split(str.characters, maxSplit: 2, allowEmptySlices: true, isSeparator: { $0 == "/" }).map(String.init)
                let last = vs.count - 1
                vs[last] = url_encode(vs[last])
                return "/".join(vs)
            }
            
            return self.baseURL + url_encode(str)
        }
        
        let method = token.method
        let URL = encodedUrl(token.URL)
        let parameters = token.parameters
        let encoding = token.encoding
        
        let URLRequest = encoding.encode({ () -> NSURLRequest in
            let URLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
            URLRequest.HTTPMethod = method.rawValue
            if let headers = self.additionalHeaders() {
                for (k, v) in headers {
                    URLRequest.addValue("\(v)", forHTTPHeaderField: k)
                }
            }
            if let headers = token.headers {
                for (k, v) in headers {
                    URLRequest.addValue("\(v)", forHTTPHeaderField: k)
                }
            }
//            self.updateURLRequest(URLRequest)
            if let timeoutInterval = token.timeoutInterval {
                URLRequest.timeoutInterval = timeoutInterval
            }
            return URLRequest
            }(),
            parameters: parameters).0
        
        let request = manager.request(URLRequest)
        
        if let statusCode = token.statusCode {
            request.validate(statusCode: statusCode)
        }
        if let contentType = token.contentType {
            request.validate(contentType: contentType)
        }
        
        if let debugger = debugger {
            request.responseString(encoding: NSUTF8StringEncoding) { URLRequest, response, object, error in
                let result: Result<String!, NSError>
                if let e = error {
                    result = Result(error: e)
                } else {
                    result = Result(value: object)
                }
                debugger.response(URLRequest!, response: response!, result: result)
            }
        }
        
        return request
    }
}



private var AlamofireRequest_APIKit_requestToken: UInt8 = 0
private extension Alamofire.Request {
    
    
    private var APIKit_requestToken: AnyObject? {
        get {
            return objc_getAssociatedObject(self, &AlamofireRequest_APIKit_requestToken)
        }
        set {
            objc_setAssociatedObject(self, &AlamofireRequest_APIKit_requestToken, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
