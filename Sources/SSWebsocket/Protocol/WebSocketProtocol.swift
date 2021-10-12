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


public enum State {
    case connecting
    case connected
    case closing
    case closed
}

public protocol SSWebSocketDelegate: AnyObject {
    func webSocketDidOpen()
    func webSocket(didReceiveMessageWith string: String)
    func webSocket(didReceiveMessageWith data: Data)
    func webSocket(didFailWithError error: Error)
    func webSocket(didCloseWithCode code: Int, reason: String?)
}

public protocol SSWebSocketClient: AnyObject {
    
    init(_ url: URL)
    init(_ request: URLRequest)
    
    var delegate: SSWebSocketDelegate? { get set }
    var state: State { get set }
    
    func open()
    
    func close()
    func close(_ closeCode: Int?, reason: Data?)
    
    func send(_ string: String)
    func send(_ string: String, completionHandler: ((Error?) -> Void)?)
    func send(_ data: Data)
    func send(_ data: Data, completionHandler: ((Error?) -> Void)?)
}