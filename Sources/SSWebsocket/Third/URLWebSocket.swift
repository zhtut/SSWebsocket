//
//  File.swift
//  
//
//  Created by shutut on 2021/9/7.
//

#if os(iOS) || os(macOS)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Dispatch)
import Dispatch
#endif

open class URLWebSocket: NSObject, URLSessionWebSocketDelegate, SSWebSocketClient {
    
    open var url: URL?
    open var request: URLRequest?
    
    open weak var delegate: SSWebSocketDelegate?
    
    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    
    open var state = State.closed
    
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
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    open func open() {
        state = .connecting
        if url != nil && request == nil {
            request = URLRequest(url: url!)
        }
        if (request == nil) {
            fatalError("初始化失败，url和reuest都为空，");
        }
        
        task = session.webSocketTask(with: request!)
        task?.maximumMessageSize = 4096
        self.receive()
        task?.resume()
    }
    
    public func close() {
        close(nil, reason: nil)
    }
    
    public func close(_ closeCode: Int? = nil, reason: Data? = nil) {
        var code = URLSessionWebSocketTask.CloseCode.normalClosure
        if closeCode != nil {
            code = URLSessionWebSocketTask.CloseCode(rawValue: closeCode!)!
        }
        task?.cancel(with: code, reason: reason)
    }
    
    public func send(_ string: String) {
        send(string, completionHandler: nil)
    }
    
    public func send(_ data: Data) {
        send(data, completionHandler: nil)
    }
    
    open func send(_ string: String, completionHandler: ((Error?) -> Void)? = nil) {
        task?.send(.string(string), completionHandler: { error in
            completionHandler?(error)
        })
    }
    
    open func send(_ data: Data, completionHandler: ((Error?) -> Void)? = nil) {
        task?.send(.data(data), completionHandler: { error in
            completionHandler?(error)
        })
    }
    
    private func sendPing(_ completionHandler: ((Error?) -> Void)? = nil) {
        task?.sendPing(pongReceiveHandler: { [weak self] error in
            completionHandler?(error)
            if error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    self?.sendPing()
                }
            }
        })
    }
    
    private func receive() {
        task?.receive(completionHandler: { [weak self] (result) in
            switch result {
                case .success(let message):
                    switch message {
                        case .string(let string):
                            DispatchQueue.main.async {
                                self?.delegate?.webSocket(didReceiveMessageWith: string)
                            }
                        case .data(let data):
                            DispatchQueue.main.async {
                                self?.delegate?.webSocket(didReceiveMessageWith: data)
                            }
                        @unknown default:
                            break
                    }
                    break
                case .failure(let error):
                    let err = error as NSError
                    if err.code == 57 {
                        print("读取数据失败，连接中断了：\(err)")
                        return
                    }
                    DispatchQueue.main.async {
                        self?.delegate?.webSocket(didFailWithError: error)
                    }
            }
            self?.receive()
        })
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError:\(error?.localizedDescription ?? "")")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            print("didCompleteWithError:\(error?.localizedDescription ?? "")")
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        state = .connected
        self.delegate?.webSocketDidOpen()
        sendPing()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var r = ""
        if let d = reason {
            r = String(data: d, encoding: .utf8) ?? ""
        }
        state = .closed
        let intCode = closeCode.rawValue
        self.delegate?.webSocket(didCloseWithCode: intCode, reason: r)
    }
}

#endif
