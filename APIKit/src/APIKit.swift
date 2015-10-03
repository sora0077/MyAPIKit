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
    
    static func networkError(error: ErrorType) -> Self
    
    static func serializeError(error: ErrorType) -> Self
    
    static func validationError(error: ErrorType) -> Self
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

public extension API {
    
    /**
    request()
    
    :param: token RequestToken protocol
    
    :returns: Future<T.Response, APIKitError<Error>>
    */
    final func request<T: RequestToken>(token: T) -> Future<T.Response, Error> {
        
        let promise = Promise<T.Response, Error>()
        
        let ticket = createRequest(token)
        
        switch token.serializer {
        case .Data:
            ticket.responseData { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try T.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch {
                        promise.failure(Error.serializeError(error))
                    }
                case let .Failure(error):
                    promise.failure(Error.networkError(error))
                }
            }
        case let .String(encoding):
            ticket.responseString(encoding: encoding) { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try T.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch {
                        promise.failure(Error.serializeError(error))
                    }
                case let .Failure(error):
                    promise.failure(Error.networkError(error))
                }
            }
        case let .JSON(options):
            ticket.responseJSON(options: options) { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try T.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch {
                        promise.failure(Error.serializeError(error))
                    }
                case let .Failure(error):
                    promise.failure(Error.networkError(error))
                }
            }
        }
        
        return promise.future
    }
}

private extension API {
    
    func createRequest<T: RequestToken>(token: T) -> Request {
        
        func encodedUrl(str: String) -> String {
            if str.hasPrefix("http") {
                var vs = str.characters.split(2, allowEmptySlices: true, isSeparator: { $0 == "/" }).map(String.init)
                let last = vs.count - 1
                vs[last] = url_encode(vs[last])
                return vs.joinWithSeparator("/")
            }
            
            return self.baseURL + url_encode(str)
        }
        
        let method = token.method
        let URL = encodedUrl(token.URL)
        let parameters = token.parameters
        let encoding = token.encoding
        
        let URLRequest = encoding.encode({
            let URLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
            URLRequest.HTTPMethod = method.rawValue
            if let headers = self.additionalHeaders() {
                for (k, v) in headers {
                    URLRequest.addValue("\(v)", forHTTPHeaderField: k)
                }
            }
            if let headers = token.headers {
                for (k, v) in headers {
                    URLRequest.addValue(v, forHTTPHeaderField: k)
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
