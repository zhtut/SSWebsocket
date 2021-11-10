//
//  File.swift
//
//
//  Created by shutut on 2021/9/7.
//

import Foundation
import WebSocketKit
import NIO
import NIOWebSocket
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class NIOWebSocket: NSObject, SSWebSocketClient {
    
    open var url: URL?
    open var request: URLRequest?
    
    open weak var delegate: SSWebSocketDelegate?
    
    open var state: SSWebSocketState = .closed
    
    var elg = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    var ws: WebSocket?
    var client: WebSocketClient?
    
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
        client = WebSocketClient(eventLoopGroupProvider: .shared(elg))
    }
    
    open func open() {
        state = .connecting
        var urlStr: String?
        if url != nil {
            urlStr = url!.absoluteString
        }
           
        if urlStr == nil && request != nil {
            urlStr = request?.url?.absoluteString
        }
        guard let str = urlStr else {
            print("初始化失败，url和reuest都为空，");
            return
        }
        guard let url = URL(string: str) else {
            return
        }
        let port = url.port ?? 443
        guard let scheme = url.scheme else {
            return
        }
        guard let host = url.host else {
            return
        }
        client!.connect(scheme: scheme, host: host, port: port, path: url.path) { ws in
            self.setupWebSocket(ws: ws)
        }.whenComplete({ [weak self] result in
            switch result {
                case .success(_):
                    self?.delegate?.webSocketDidOpen()
                case .failure(let error):
                    self?.delegate?.webSocket(didFailWithError: error)
                    self?.state = .closed
            }
        })
    }
    
    func setupWebSocket(ws: WebSocket) {
        self.ws = ws
        configWebSocket()
        state = .connected
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.sendPing()
            }
        })
        ws?.onClose.whenComplete({ [weak self] result in
            DispatchQueue.main.async {
                self?.state = .closed
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
    
    private func sendPing(_ completionHandler: ((Error?) -> Void)? = nil) {
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
