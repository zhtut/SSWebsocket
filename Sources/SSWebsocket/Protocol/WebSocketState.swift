//
//  File.swift
//  
//
//  Created by zhtg on 2023/3/18.
//

import Foundation

public struct WebSocketError: Error {
    var msg: String
}

public enum WebSocketState {
    case connecting
    case connected
    case closing
    case closed
}
