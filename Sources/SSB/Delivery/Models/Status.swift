//
//  Status.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public struct Status: Decodable {

    public struct BlobWant: Decodable {
        public var Ref: String
        public var Dist: Int
    }

    public struct PeerStatus: Decodable {
        public var Addr: String
        public var Since: String
    }

    public var Root: Int
    public var Peers: [PeerStatus]
    public var Blobs: [BlobWant]

}
