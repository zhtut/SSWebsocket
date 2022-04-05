//
//  File.swift
//
//
//  Created by shutut on 2021/9/7.
//

import Foundation
import WebSocketKit
import NIO
import NIOHTTP1
import NIOWebSocket
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class NIOWebSocket: NSObject, SSWebSocketClient {
    
    open var url: URL?
    open var request: URLRequest?
    
    open weak var delegate: SSWebSocketDelegate?
    
    public var state: SSWebSocketState {
        if let ws = ws {
            if ws.isClosed {
                return .closed
            } else {
                return .connected
            }
        }
        return .closed
    }
    
    var elg = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    var ws: WebSocket?
    
    required public convenience init(_ url: URL) {
        self.init()
        self.url = url
        setup()
    }
    
    required public convenience init(_ request: URLRequest) {
        self.init()
        self.request = request
        setup()
    }
    
    private func setup() {
    }
    
    open func open() {
        let urlStr = url?.absoluteString ?? request?.url?.absoluteString
        
        guard let urlStr = urlStr else {
            print("url和request的url都为空，无法连接websocket")
            return
        }
        
        var httpHeaders = HTTPHeaders()
        if let requestHeaders = request?.allHTTPHeaderFields {
            for (key, value) in requestHeaders {
                httpHeaders.add(name: key, value: value)
            }
        }
        
        let config = WebSocketClient.Configuration()
        
        WebSocket.connect(to: urlStr, headers: httpHeaders, configuration: config, on: elg) { ws in
            self.setupWebSocket(ws: ws)
        }.whenComplete({ [weak self] result in
            switch result {
                case .success(_):
                    self?.delegate?.webSocketDidOpen()
                case .failure(let error):
                    self?.delegate?.webSocket(didFailWithError: error)
            }
        })
    }
    
    func setupWebSocket(ws: WebSocket) {
        self.ws = ws
        configWebSocket()
    }
    
    func configWebSocket() {
        ws?.onText({ [weak self] ws, string in
            DispatchQueue.main.async {
                self?.delegate?.webSocket(didReceiveMessageWith: string)
            }
        })
        ws?.onBinary({ [weak self] ws, buffer in
            DispatchQueue.main.async {
                let data = Data(buffer: buffer)
                self?.delegate?.webSocket(didReceiveMessageWith: data)
            }
        })
        ws?.onPong({ [weak self] ws in
            DispatchQueue.main.async {
                self?.delegate?.webSocketDidReceivePong()
            }
        })
        ws?.onPing({ [weak self] ws in
            DispatchQueue.main.async {
                self?.delegate?.webSocketDidReceivePing()
            }
        })
        ws?.onClose.whenComplete({ [weak self] result in
            DispatchQueue.main.async {
                let reson = "closed"
                let code = -1
                self?.delegate?.webSocket(didCloseWithCode: code, reason: reson)
            }
        })
    }
    
    public func close() {
        close(nil, reason: nil)
    }
    
    public func close(_ closeCode: Int? = nil, reason: Data? = nil) {
        _ = ws?.close(code: WebSocketErrorCode(codeNumber: closeCode ?? 1000))
    }
    
    public func send(_ string: String) {
        send(string, completionHandler: nil)
    }
    
    public func send(_ data: Data) {
        send(data, completionHandler: nil)
    }
    
    open func send(_ string: String, completionHandler: ((Error?) -> Void)? = nil) {
        let promise = self.elg.next().makePromise(of: Void.self)
        ws?.send(string, promise: promise)
        promise.futureResult.whenComplete { result in
            switch result {
            case .success(_):
                completionHandler?(nil)
            case .failure(let error):
                completionHandler?(error)
            }
        }
    }
    
    open func send(_ data: Data, completionHandler: ((Error?) -> Void)? = nil) {
        let promise = self.elg.next().makePromise(of: Void.self)
        let bytes = [UInt8](data)
        ws?.send(bytes, promise: promise)
        promise.futureResult.whenComplete { result in
            switch result {
            case .success(_):
                completionHandler?(nil)
            case .failure(let error):
                completionHandler?(error)
            }
        }
    }
    
    open func sendPing(_ completionHandler: ((Error?) -> Void)?) {
        let promise = self.elg.next().makePromise(of: Void.self)
        ws?.sendPing(promise: promise)
        promise.futureResult.whenComplete { result in
            switch result {
            case .success(_):
                completionHandler?(nil)
            case .failure(let error):
                completionHandler?(error)
            }
        }
    }
}
