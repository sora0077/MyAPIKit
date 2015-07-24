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

/**
* ErrorType for APIKit
*/
public enum APIKitError<E: ErrorType>: ErrorType {
    case AlamofireError(NSError)
    case SerializedError(E)
    case ValidationError(E)
    case UnknownError
}

/**
* API control class
*/
public class API<Error: ErrorType> {
    
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
    public func validate(request URLRequest: NSURLRequest, response: NSHTTPURLResponse, object: AnyObject?) -> APIKitError<Error>? {
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
    public final func request<T: RequestToken>(token: T) -> Future<T.Response, APIKitError<Error>> {
        let promise = Promise<T.Response, APIKitError<Error>>()
        
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
    public final func request<T: RequestToken, U where T.SerializedType == Optional<U>>(token: T) -> Future<T.Response, APIKitError<Error>> {
        let promise = Promise<T.Response, APIKitError<Error>>()
        
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
    public final func request<T: RequestToken where T.SerializedType == Any>(token: T) -> Future<T.Response, APIKitError<Error>> {
        let promise = Promise<T.Response, APIKitError<Error>>()
        
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

    final func responseNilable<T: RequestToken, U where T.SerializedType == Optional<U>>(promise: Promise<T.Response, APIKitError<Error>>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.AlamofireError(error))
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
        catch let error as Error {
            try! promise.failure(.SerializedError(error))
        }
        catch {
            try! promise.failure(.UnknownError)
        }
    }

    final func responseAnyable<T: RequestToken where T.SerializedType == Any>(promise: Promise<T.Response, APIKitError<Error>>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.AlamofireError(error))
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
        catch let error as Error {
            try! promise.failure(.SerializedError(error))
        }
        catch {
            try! promise.failure(.UnknownError)
        }
    }
    
    final func response<T: RequestToken>(promise: Promise<T.Response, APIKitError<Error>>, token: T, pack: Pack, URLRequest: NSURLRequest?, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) {
        
        if execQueue.contains(pack) {
            execQueue.remove(pack)
        }
        
        if let error = error {
            try! promise.failure(.AlamofireError(error))
            return
        }
        
        if  let response = response,
            let error = validate(request: URLRequest!, response: response, object: object)
        {
            try! promise.failure(error)
            return
        }
        
        if let object = object as? T.SerializedType {
            
            do {
                let serialized = try T.transform(URLRequest!, response: response, object: object)
                try! promise.success(serialized)
            }
            catch let error as Error {
                try! promise.failure(.SerializedError(error))
            }
            catch {
                try! promise.failure(.UnknownError)
            }
        } else {
            fatalError("")
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
    
    
    var timeoutInterval: NSTimeInterval? { get }
    
    var statusCode: Set<Int>? { get }
    var contentType: Set<String>? { get }
    
    static func transform(request: NSURLRequest, response: NSHTTPURLResponse?, object: SerializedType) throws -> Response
}

extension RequestToken {
    
    var headers: [String: AnyObject]? {
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
