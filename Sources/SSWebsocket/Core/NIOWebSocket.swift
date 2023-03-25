//
//  File.swift
//
//
//  Created by shutut on 2021/9/7.
//

#if compiler(>=5.5) && canImport(_Concurrency)

import Foundation
import WebSocketKit
import NIO
import NIOWebSocket
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(iOS 15.0, *)
@available(macOS 12.0, *)
open class NIOWebSocket {
    
    open var url: URL? {
        return request.url
    }
    
    open private(set) var request: URLRequest
    
    open weak var delegate: WebSocketDelegate?
    
    open var state: WebSocketState {
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
    open var ws: WebSocket?
    
    /// 自动回复ping，默认为true
    open var autoReplyPing = true
    
    public init(url: URL) {
        self.request = URLRequest(url: url)
    }
    
    public init(request: URLRequest) {
        self.request = request
    }
    
    open func open() {
        Task {
            try await open()
        }
    }
    
    open func open() async throws {
        let urlStr = request.url?.absoluteString
        
        guard let urlStr = urlStr else {
            print("url和request的url都为空，无法连接websocket")
            return
        }
        
        var httpHeaders = HTTPHeaders()
        if let requestHeaders = request.allHTTPHeaderFields {
            for (key, value) in requestHeaders {
                httpHeaders.add(name: key, value: value)
            }
        }
        
        let config = WebSocketClient.Configuration()
        
        try await WebSocket.connect(to: urlStr, headers: httpHeaders, configuration: config, on: elg, onUpgrade: setupWebSocket)
    }
    
    func setupWebSocket(ws: WebSocket) async {
        self.ws = ws
        configWebSocket()
        delegate?.webSocketDidOpen()
    }
    
    func configWebSocket() {
        ws?.pingInterval = TimeAmount.minutes(8)
        ws?.onText({ [weak self] ws, string in
            self?.delegate?.webSocket(didReceiveMessageWith: string)
        })
        ws?.onBinary({ [weak self] ws, buffer in
            let data = Data(buffer: buffer)
            self?.delegate?.webSocket(didReceiveMessageWith: data)
        })
        ws?.onPong({ [weak self] ws in
            self?.delegate?.webSocketDidReceivePong()
        })
        ws?.onPing({ [weak self] ws in
            guard let self = self else { return }
            self.delegate?.webSocketDidReceivePing()
            if self.autoReplyPing {
                Task {
                    try await self.sendPong()
                }
            }
        })
        ws?.onClose.whenComplete({ [weak self] result in
            var reson = ""
            var code = -1
            if let closeCode = self?.ws?.closeCode {
                reson = "\(closeCode)"
                switch closeCode {
                    case .normalClosure:
                        code = 1000
                    case .goingAway:
                        code = 1001
                    case .protocolError:
                        code = 1002
                    case .unacceptableData:
                        code = 1003
                    case .dataInconsistentWithMessage:
                        code = 1007
                    case .policyViolation:
                        code = 1008
                    case .messageTooLarge:
                        code = 1009
                    case .missingExtension:
                        code = 1010
                    case .unexpectedServerError:
                        code = 1011
                    default:
                        code = -1
                }
            }
            self?.delegate?.webSocket(didCloseWithCode: code, reason: reson)
        })
    }
    
    public func close(_ closeCode: WebSocketErrorCode = .normalClosure) async throws {
        try await ws?.close(code: closeCode)
    }
    
    open func send(_ string: String) async throws {
        try await ws?.send(string)
    }
    
    open func send(_ data: Data) async throws {
        let bytes = [UInt8](data)
        try await ws?.send(bytes)
    }
    
    open func sendPing() async throws {
        try await ws?.sendPing()
    }
    
    open func sendPong() async throws {
        try await ws?.send(raw: Data(), opcode: .pong, fin: true)
    }
}

#endif
