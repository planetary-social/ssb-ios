//
//  Config.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

struct Config: Encodable {

    /// Base 64 encoded string
    let AppKey: String

    /// Base 64 encoded string. Can be empty.
    let HMACKey: String

    let KeyBlob: String

    let Repo: String

    let ListenAddr: String

    let Hops: UInt

    let SchemaVersion: UInt

    // Identities of services which supply planetary specific services
    let ServicePubs: [String]?

    #if DEBUG
    let Testing: Bool = true
    #else
    let Testing: Bool = false
    #endif

    public init(AppKey: String, HMACKey: String, KeyBlob: String, Repo: String, ListenAddr: String, Hops: UInt, SchemaVersion: UInt, ServicePubs: [String]?) {
        self.AppKey = AppKey
        self.HMACKey = HMACKey
        self.KeyBlob = KeyBlob
        self.Repo = Repo
        self.ListenAddr = ListenAddr
        self.Hops = Hops
        self.SchemaVersion = SchemaVersion
        self.ServicePubs = ServicePubs
    }
}
