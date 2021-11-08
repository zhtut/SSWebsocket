//
//  File.swift
//
//
//  Created by shutut on 2021/9/5.
//

import Foundation

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
    
    public override init() {
        super.init()
        open()
    }
    
    open func open() {
        if isConnected {
            return
        }
        if let url = URL(string: urlStr) {
            webSocket = URLSessionWebSocket(url)
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
            if let str = String(data: data, encoding: .utf8) {
                webSocket?.send(str)
            }
        }
    }
    
    open func sendPing() {
        webSocket?.send("ping")
    }
    
    open func sendWaitingMessage() {
        if waitingMessage.count > 0 {
            for mess in waitingMessage {
                sendMessage(message: mess)
            }
        }
        waitingMessage.removeAll()
    }
    
    open func webSocketDidReceive(message: [String: Any]) {
        
    }
    
    /// 子类继承的类
    open func webSocketDidReceive(string: String) {
        
    }
    
    open func webSocketDidReceive(data: Data) {
        
    }
    
    open func webSocketDidClosedWith(code: Int, reason: String?) {
        open()
    }
    
    /// 代理
    open func webSocketDidOpen() {
        print("webSocketDidOpen")
        sendWaitingMessage()
    }
    open func webSocket(didReceiveMessageWith string: String) {
        webSocketDidReceive(string: string)
    }
    open func webSocket(didReceiveMessageWith data: Data) {
        webSocketDidReceive(data: data)
    }
    open func webSocket(didFailWithError error: Error) {
        print("didFailWithError：\(error)")
        let desc = "\(error)"
        if desc.contains("connectTimeout") {
            self.open()
        }
    }
    open func webSocket(didCloseWithCode code: Int, reason: String?) {
        webSocketDidClosedWith(code: code, reason: reason)
        print("didCloseWithCode:\(code), reason:\(reason ?? "")")
    }
}
