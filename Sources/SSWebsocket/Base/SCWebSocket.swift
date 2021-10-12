//
//  File.swift
//
//
//  Created by shutut on 2021/9/5.
//

import Foundation

class SCWebSocket: NSObject, SSWebSocketDelegate {
    
    deinit {
        webSocket?.close()
    }
    
    var urlStr: String {
        fatalError("这个变量需要子类去设定，父类的不可用")
    }
    var webSocket: SSWebSocketClient?
    
    var isConnected: Bool {
        return webSocket?.state == .connected
    }
    
    var waitingMessage = [[String: Any]]()
    
    override init() {
        super.init()
        open()
    }
    
    func open() {
        if isConnected {
            return
        }
        if let url = URL(string: urlStr) {
            webSocket = NIOWebSocket(url)
            webSocket?.delegate = self
            webSocket?.open()
        }
    }
    
    func sendMessage(message: [String: Any]) {
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
    
    func sendPing() {
        webSocket?.send("ping")
    }
    
    func sendWaitingMessage() {
        if waitingMessage.count > 0 {
            for mess in waitingMessage {
                sendMessage(message: mess)
            }
        }
        waitingMessage.removeAll()
    }
    
    func webSocketDidReceive(message: [String: Any]) {
        
    }
    
    /// 子类继承的类
    func webSocketDidReceive(string: String) {
        
    }
    
    func webSocketDidReceive(data: Data) {
        
    }
    
    func webSocketDidClosedWith(code: Int, reason: String?) {
        open()
    }
    
    /// 代理
    func webSocketDidOpen() {
        print("webSocketDidOpen")
        sendWaitingMessage()
    }
    func webSocket(didReceiveMessageWith string: String) {
        webSocketDidReceive(string: string)
    }
    func webSocket(didReceiveMessageWith data: Data) {
        webSocketDidReceive(data: data)
    }
    func webSocket(didFailWithError error: Error) {
        print("didFailWithError：\(error)")
        let desc = "\(error)"
        if desc.contains("connectTimeout") {
            self.open()
        }
    }
    func webSocket(didCloseWithCode code: Int, reason: String?) {
        webSocketDidClosedWith(code: code, reason: reason)
        print("didCloseWithCode:\(code), reason:\(reason ?? "")")
    }
}
