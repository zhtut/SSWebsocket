//
//  File.swift
//  
//
//  Created by shutut on 2021/9/7.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(iOS 13.0, *)
@available(macOS 10.15, *)
open class SSWebSocket: NSObject, URLSessionWebSocketDelegate {
    
    open var url: URL? {
        return request.url
    }
    
    open lazy var delegateQueue: OperationQueue = {
        OperationQueue()
    }()
    
    open private(set) var request: URLRequest
    
    open weak var delegate: WebSocketDelegate?
    
    private lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        return session
    }()
    
    private var task: URLSessionWebSocketTask?
    
    open var state = WebSocketState.closed
    
    public init(url: URL) {
        self.request = URLRequest(url: url)
        super.init()
    }
    
    public init(request: URLRequest) {
        self.request = request
        super.init()
    }
    
    open func open() {
        state = .connecting
        
        task = session.webSocketTask(with: request)
        task?.maximumMessageSize = 4096
        task?.resume()
    }
    
    open func close(_ closeCode: Int? = nil, reason: Data? = nil) {
        state = .closing
        var code = URLSessionWebSocketTask.CloseCode.normalClosure
        if closeCode != nil {
            code = URLSessionWebSocketTask.CloseCode(rawValue: closeCode!)!
        }
        task?.cancel(with: code, reason: reason)
    }
    
    open func send(string: String) async throws {
        try await task?.send(.string(string))
    }
    
    open func send(data: Data) async throws {
        try await task?.send(.data(data))
    }
    
    open func sendPing(_ completionHandler: @escaping ((Error?) -> Void)) {
        task?.sendPing(pongReceiveHandler: completionHandler)
    }
    
    private func receive() async throws {
        guard let task = task else {
            return
        }
        do {
            let message = try await task.receive()
            switch message {
                case .string(let string):
                    delegate?.webSocket(didReceiveMessageWith: string)
                case .data(let data):
                    delegate?.webSocket(didReceiveMessageWith: data)
                @unknown default:
                    break
            }
        } catch {
            print("接收消息错误：\(error)")
        }
        try await receive()
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError:\(error?.localizedDescription ?? "")")
        didClose(code: -1, reason: "URLSession Invalid: \(String(describing: error))")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            print("didCompleteWithError:\(error?.localizedDescription ?? "")")
        }
        
        if let err = error as NSError?,
            err.code == 57 {
            print("读取数据失败，连接已中断：\(err)")
            didClose(code: err.code, reason: err.localizedDescription)
            return
        }
        if let error = error {
            delegate?.webSocket(didFailWithError: error)
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        state = .connected
        delegate?.webSocketDidOpen()
        Task {
            try await self.receive()
        }
    }
    
    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                           reason: Data?) {
        var r = ""
        if let d = reason {
            r = String(data: d, encoding: .utf8) ?? ""
        }
        let intCode = closeCode.rawValue
        didClose(code: intCode, reason: r)
    }
    
    func didClose(code: Int, reason: String?) {
        state = .closed
        delegate?.webSocket(didCloseWithCode: code, reason: reason)
        task = nil
    }
}
