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
public typealias AFuture = BrightFutures.Future

public let APIKitErrorDomain = "jp.sora0077.APIKit.ErrorDomain"

/**
* ErrorType for APIKit
*/
public protocol APIKitErrorType: ErrorType {
    
    static func networkError(error: ErrorType) -> Self
    
    static func serializeError(error: ErrorType) -> Self
    
    static func validationError(error: ErrorType) -> Self
    
    static func unsupportedError(error: ErrorType) -> Self
}


public protocol APIKitProtocol {
    
    typealias Error: ErrorType
    
    /**
     cancel
    
     - parameter clazz: <#clazz description#>
     */
    func cancel<T : RequestToken>(clazz: T.Type)
    
    /**
     cancel
     
     - parameter clazz: <#clazz description#>
     - parameter f:     specific token cancelization
     
     - returns: <#return value description#>
     */
    func cancel<T : RequestToken>(clazz: T.Type, _ f: T -> Bool)
    
    
    /**
     request
     
     - parameter token: <#token description#>
     
     - returns: Future<T.Response, Error>
     */
    func request<T: RequestToken>(token: T) -> Future<T.Response, Error>
    
    /**
     request
     
     - parameter token:      <#token description#>
     - parameter serializer: <#serializer description#>
     
     - returns: Future<T.Response, Error>
     */
    func request<T: RequestToken, S: ResponseSerializerType>(token: T, serializer: S) -> Future<T.Response, Error>
    
    /**
     multipart request
     
     - parameter token: <#token description#>
     
     - returns: <#return value description#>
     */
    func request<T: MultipartRequestToken>(token: T) -> Future<T.Response, Error>
    
    /**
     multipart request
     
     - parameter token:      <#token description#>
     - parameter serializer: <#serializer description#>
     
     - returns: <#return value description#>
     */
    func request<T: MultipartRequestToken, S: ResponseSerializerType>(token: T, serializer: S) -> Future<T.Response, Error>
}


/**
* API control class
*/
public final class API<Error: APIKitErrorType>: APIKitProtocol {
    
    private var execQueue: Set<Pack> = []
    private let manager: Alamofire.Manager
    private let baseURL: NSURL?
    
    public init(baseURL: NSURL? = nil, configuration: NSURLSessionConfiguration = .defaultSessionConfiguration()) {
        
        self.baseURL = baseURL
        
        if configuration.HTTPAdditionalHeaders?.count == 0 {
            configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        } else {
            for (k, v) in Manager.defaultHTTPHeaders {
                if configuration.HTTPAdditionalHeaders?[k] != nil {
                    configuration.HTTPAdditionalHeaders?[k] = v
                }
            }
        }
        self.manager = Manager(configuration: configuration)
    }
}

public extension API {
    
    public final func cancel<T : RequestToken>(clazz: T.Type) {
        cancel(clazz, { _ in true })
    }
    
    /**
    cancel(_:)
    
    :param: clazz <#clazz description#>
    */
    public final func cancel<T: RequestToken>(clazz: T.Type, _ f: T -> Bool) {
        
        for pack in execQueue {
            if let token = pack.token as? T where f(token) {
                Queue.global.async {
                    pack.request.cancel()
                }
            }
        }
    }
    
    /**
    <#Description#>
    
    - parameter token: RequestToken protocol
    
    - returns: <#return value description#>
    */
    final func request<T: RequestToken>(token: T) -> Future<T.Response, Error> {
        
        let future = createRequest(token)
        
        return future.flatMap {
            self.response(token, request: $0)
        }
    }
    
    /**
    request()
    
    - parameter token:      RequestToken protocol
    - parameter serializer: ResponseSerializerType protocol
    
    - returns: Future<T.Response, APIKitError<Error>>
    */
    final func request<T: RequestToken, S: ResponseSerializerType>(token: T, serializer: S) -> Future<T.Response, Error> {
        
        let future = createRequest(token)
        
        return future.flatMap {
            self.response(token, serializer: serializer, request: $0)
        }
    }
    
    /**
    request()
    
    - parameter token: MultipartRequestToken protocol
    
    - returns: Future<T.Response, APIKitError<Error>>
    */
    final func request<T: MultipartRequestToken>(token: T) -> Future<T.Response, Error> {
        
        let future = createMultipartFormDataRequest(token)
        
        return future.flatMap {
            self.response(token, request: $0)
        }
    }
    
    /**
    request()
    
    - parameter token:      RequestToken protocol
    - parameter serializer: ResponseSerializerType protocol
    
    - returns: Future<T.Response, APIKitError<Error>>
    */
    final func request<T: MultipartRequestToken, S: ResponseSerializerType>(token: T, serializer: S) -> Future<T.Response, Error> {
        
        let future = createMultipartFormDataRequest(token)
        
        return future.flatMap {
            self.response(token, serializer: serializer, request: $0)
        }
    }
    
    
    
    private func response<T: RequestToken>(token: T, request: Request) -> Future<T.Response, Error> {
        
        let promise = Promise<T.Response, Error>()
        
        switch token.serializer {
        case .Data:
            request.responseData { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try token.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch let error as Error {
                        promise.failure(error)
                    }
                    catch {
                        promise.failure(Error.unsupportedError(error))
                    }
                case let .Failure(error as Error):
                    promise.failure(error)
                case let .Failure(error):
                    promise.failure(Error.unsupportedError(error))
                }
            }
        case let .String(encoding):
            request.responseString(encoding: encoding) { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try token.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch let error as Error {
                        promise.failure(error)
                    }
                    catch {
                        promise.failure(Error.unsupportedError(error))
                    }
                case let .Failure(error as Error):
                    promise.failure(error)
                case let .Failure(error):
                    promise.failure(Error.unsupportedError(error))
                }
            }
        case let .JSON(options):
            request.responseJSON(options: options) { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try token.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch let error as Error {
                        promise.failure(error)
                    }
                    catch {
                        promise.failure(Error.unsupportedError(error))
                    }
                case let .Failure(error as Error):
                    promise.failure(error)
                case let .Failure(error):
                    promise.failure(Error.unsupportedError(error))
                }
            }
        case let .PropertyList(options):
            request.responsePropertyList(options: options) { r in
                
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try token.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch let error as Error {
                        promise.failure(error)
                    }
                    catch {
                        promise.failure(Error.unsupportedError(error))
                    }
                case let .Failure(error as Error):
                    promise.failure(error)
                case let .Failure(error):
                    promise.failure(Error.unsupportedError(error))
                }
            }
        case .Custom:
            fatalError("Custom needs ResponseSerializerType")
        }
        return promise.future
    }
    
    
    private func response<T: RequestToken, S: ResponseSerializerType>(token: T, serializer: S, request: Request) -> Future<T.Response, Error> {
        
        let promise = Promise<T.Response, Error>()
        
        switch token.serializer {
        case .Custom:
            request.response(responseSerializer: serializer, completionHandler: { r in
                switch r.result {
                case let .Success(object):
                    do {
                        let object = try token.transform(r.request, response: r.response, object: object as! T.SerializedObject)
                        promise.success(object)
                    }
                    catch {
                        promise.failure(Error.serializeError(error))
                    }
                case let .Failure(error as Error):
                    promise.failure(error)
                case let .Failure(error):
                    promise.failure(Error.unsupportedError(error))
                }
            })
        default:
            fatalError("Other token.serializer unneeds ResponseSerializerType")
        }
        return promise.future
    }
}

private extension API {
    
    func createRequest<T: RequestToken>(token: T) -> Future<Request, Error> {
        
        let method = token.method
        let URL = NSURL(string: token.path, relativeToURL: token.baseURL ?? baseURL)
        let parameters = token.parameters
        let encoding = token.encoding
        
        let URLRequest = encoding.encode({
            let URLRequest = NSMutableURLRequest(URL: URL!)
            URLRequest.HTTPMethod = method.rawValue
            if let headers = token.headers {
                for (k, v) in headers {
                    URLRequest.addValue(v, forHTTPHeaderField: k)
                }
            }
            
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
        
        if let token = token as? DebugRequestToken {
            token.printCURL(request.debugDescription)
        }
        
        return Future(value: request)
    }
    
    func createMultipartFormDataRequest<T: MultipartRequestToken>(token: T) -> Future<Request, Error> {
        
        let method = token.method
        let URL = NSURL(string: token.path, relativeToURL: token.baseURL)
        let encoding = token.encoding
        
        let URLRequest = encoding.encode({
            let URLRequest = NSMutableURLRequest(URL: URL!)
            URLRequest.HTTPMethod = method.rawValue
            if let headers = token.headers {
                for (k, v) in headers {
                    URLRequest.addValue(v, forHTTPHeaderField: k)
                }
            }
            
            if let timeoutInterval = token.timeoutInterval {
                URLRequest.timeoutInterval = timeoutInterval
            }
            return URLRequest
            }(),
            parameters: nil).0
        
        let promise = Promise<Request, Error>()
        
        manager.upload(
            URLRequest,
            multipartFormData: { m in
                if let parameters = token.parameters {
                    for (k, v) in parameters {
                        if let v = v as? String, data = v.dataUsingEncoding(NSUTF8StringEncoding) {
                            m.appendBodyPart(data: data, name: k)
                        }
                    }
                }
//                for (k, v) in token.multiparts {
//                    
//                }
            },
            encodingCompletion: { r in
                switch r {
                case let .Success(request, _, _):
                    if let statusCode = token.statusCode {
                        request.validate(statusCode: statusCode)
                    }
                    if let contentType = token.contentType {
                        request.validate(contentType: contentType)
                    }
                    promise.success(request)
                case let .Failure(error):
                    promise.failure(Error.serializeError(error))
                }
            }
        )
        return promise.future
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
