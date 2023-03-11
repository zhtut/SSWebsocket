// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "SSWebsocket",
                      platforms: [ .iOS(.v13),
                                   .macOS(.v10_15) ],
                      products: [
                        .library(name: "SSWebsocket", targets: ["SSWebsocket"]),
                      ],
                      dependencies: [
                        
                      ],
                      targets: [
                        .target(name: "SSWebsocket", dependencies: [
                            
                        ]),
                      ])
