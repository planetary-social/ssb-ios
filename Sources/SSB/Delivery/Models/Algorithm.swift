//
//  Algorithm.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public enum Algorithm: String, Codable {

    case sha256
    case ed25519
    case ggfeed = "ggfeed-v1"
    case ggfeedmsg = "ggmsg-v1"
    case unsupported

    public init() {
        self = .unsupported
    }

    public init(fromRawValue: String) {
        self = Algorithm(rawValue: fromRawValue) ?? .unsupported
    }
    
}
