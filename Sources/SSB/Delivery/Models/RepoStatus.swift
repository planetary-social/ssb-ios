//
//  RepoStatus.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public struct RepoStatus: Decodable {

    public var messages: UInt

    public var feeds: UInt

    public var lastHash: String

    init(messages: UInt, feeds: UInt, lastHash: String) {
        self.messages = messages
        self.feeds = feeds
        self.lastHash = lastHash
    }

}
