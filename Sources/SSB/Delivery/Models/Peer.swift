//
//  File.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public struct Peer {

    public var key: Key
    public var tcpAddr: String

    public init(key: Key, tcpAddr: String) {
        self.key = key
        self.tcpAddr = tcpAddr
    }

}
