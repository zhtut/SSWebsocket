// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "SSWebsocket",
                      platforms: [ .iOS(.v15),
                                   .macOS(.v12) ],
                      products: [
                        .library(name: "SSWebsocket", targets: ["SSWebsocket"]),
                      ],
                      dependencies: [
                        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.2.0"),
                        .package(url: "https://github.com/apple/swift-nio.git", from: "2.33.0"),
                        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.16.1"),
                      ],
                      targets: [
                        .target(name: "SSWebsocket", dependencies: [
                            .product(name: "WebSocketKit", package: "websocket-kit"),
                            .product(name: "NIO", package: "swift-nio"),
                            .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                            .product(name: "NIOFoundationCompat", package: "swift-nio"),
                            .product(name: "NIOHTTP1", package: "swift-nio"),
                            .product(name: "NIOSSL", package: "swift-nio-ssl"),
                            .product(name: "NIOWebSocket", package: "swift-nio"),
                        ]),
                      ])
