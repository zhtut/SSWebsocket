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
/// 使用系统的URLSessionWebSocketTask实现的WebSocket客户端
open class SSWebSocket: NSObject, URLSessionWebSocketDelegate {
    
    /// url地址
    open var url: URL? {
        return request.url
    }
    
    /// 请求对象
    open private(set) var request: URLRequest
    
    /// 代理队列
    open lazy var delegateQueue: OperationQueue = {
        OperationQueue()
    }()
    
    /// 代理
    open weak var delegate: WebSocketDelegate?
    
    /// URLSession对象
    private lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        return session
    }()
    
    /// 请求task，保持长连接的task
    private var task: URLSessionWebSocketTask?
    
    /// 连接状态
    open var state = WebSocketState.closed
    
    public init(url: URL) {
        self.request = URLRequest(url: url)
        super.init()
    }
    
    public init(request: URLRequest) {
        self.request = request
        super.init()
    }
    
    /// 开始连接
    open func open() {
        state = .connecting
        
        task = session.webSocketTask(with: request)
        task?.maximumMessageSize = 4096
        task?.resume()
    }
    
    /// 关闭连接
    /// - Parameters:
    ///   - closeCode: 关闭的code，可不填
    ///   - reason: 关闭的原因，可不填
    open func close(_ closeCode: Int? = nil, reason: Data? = nil) {
        state = .closing
        var code = URLSessionWebSocketTask.CloseCode.normalClosure
        if closeCode != nil {
            code = URLSessionWebSocketTask.CloseCode(rawValue: closeCode!)!
        }
        task?.cancel(with: code, reason: reason)
    }
    
    /// 发送字符串
    /// - Parameter string: 要发送的字符串
    open func send(string: String) async throws {
        try await task?.send(.string(string))
    }
    
    /// 发送data
    /// - Parameter data: 要发送的data
    open func send(data: Data) async throws {
        try await task?.send(.data(data))
    }
    
    /// 发送一个ping
    /// - Parameter completionHandler: 完成的回调，可不传
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
