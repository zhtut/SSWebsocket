// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "SSWebsocket",
                      platforms: [ .iOS(.v13),
                                   .macOS(.v10_15) ],
                      products: [
                        .library(name: "SSWebsocket", targets: ["SSWebsocket"]),
                      ],
                      dependencies: [
                        .package(url: "https://gitee.com/ztgtut/websocket-kit.git", from: "2.2.0"),
                        .package(url: "https://gitee.com/ztgtut/swift-nio.git", from: "2.33.0"),
                        .package(url: "https://gitee.com/ztgtut/swift-nio-ssl.git", from: "2.16.1"),
                      ],
                      targets: [
                        .target(name: "SSWebsocket", dependencies: [
                            .product(name: "WebSocketKit", package: "websocket-kit"),
                        ]),
                      ])
