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
                        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.6.1"),
                      ],
                      targets: [
                        .target(name: "SSWebsocket", dependencies: [
                            .product(name: "WebSocketKit", package: "websocket-kit"),
                        ]),
                      ])
