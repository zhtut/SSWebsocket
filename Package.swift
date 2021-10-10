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
                        .package(url: "https://github.com/vapor/websocket-kit", from: "2.2.0")
                      ],
                      targets: [
                        .target(name: "SSWebsocket", dependencies: [
                            .product(name: "WebSocketKit", package: "websocket-kit"),
                        ]),
                      ])
