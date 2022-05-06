//
//  File.swift
//
//
//  Created by shutut on 2021/9/5.
//

import Foundation
import NIOPosix

open class SSWebSocket: NSObject, SSWebSocketDelegate {
    
    deinit {
        webSocket?.close()
    }
    
    open var urlStr: String {
        fatalError("这个变量需要子类去设定，父类的不可用")
    }
    open var webSocket: SSWebSocketClient?
    
    open var isConnected: Bool {
        return webSocket?.state == .connected
    }
    
    open var waitingMessage = [[String: Any]]()
    
    /// 发送String还是发送Data，true发送String, false发送Data
    open var sendStr: Bool {
        true
    }
    
    /// init的时候是否自动连接
    open var autoConnect: Bool {
        true
    }
    
    public override init() {
        super.init()
        if autoConnect {
            open()
        }
    }
    
    open func open() {
        if let url = URL(string: urlStr) {
//#if os(Linux)
            webSocket = NIOWebSocket(url)
//#else
//            webSocket = URLSessionWebSocket(url)
//#endif
            webSocket?.delegate = self
            webSocket?.open()
            print("Websocket开始连接：\(url)")
        }
    }
    
    open func sendMessage(message: [String: Any]) {
        if !isConnected {
            waitingMessage.append(message)
            return
        }
        if let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) {
            if sendStr == false {
                webSocket?.send(data)
            } else {
                if let str = String(data: data, encoding: .utf8) {
                    webSocket?.send(str)
                }
            }
        }
    }
    
    open func close() {
        webSocket?.close()
    }
    
    open func sendPing() {
        webSocket?.sendPing({ error in
            
        })
    }
    
    open func sendWaitingMessage() {
        let messages = waitingMessage
        waitingMessage.removeAll()
        if messages.count > 0 {
            for mess in messages {
                sendMessage(message: mess)
            }
        }
    }
    
    // MARK: 代理
    
    open func webSocketDidOpen() {
        sendWaitingMessage()
    }
    
    open func webSocketDidReceivePing() {
        
    }
    
    open func webSocketDidReceivePong() {
        
    }
    
    open func webSocket(didReceiveMessageWith string: String) {

    }
    open func webSocket(didReceiveMessageWith data: Data) {

    }
    open func webSocket(didFailWithError error: Error) {
        print("didFailWithError：\(error)")
    }
    open func webSocket(didCloseWithCode code: Int, reason: String?) {
        print("didCloseWithCode:\(code), reason:\(reason ?? "")")
    }
}
