//
//  Secret.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

// TODO: We should get rid of this public modifier
public struct Secret: Codable {

    var curve: Algorithm
    public var id: String
    public var `private`: String
    public var `public`: String

    public var identity: String {
        return id
    }

    public init?(from string: String) {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let secret = try? JSONDecoder().decode(Secret.self, from: data) else { return nil }
        self = secret
    }

    public func jsonString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let string = String(data: data, encoding: .utf8)
        return string
    }

    public func jsonStringUnescaped() -> String? {
        guard let string = self.jsonString() else { return nil }
        let unescaped = string.replacingOccurrences(of: "\\/", with: "/", options: .literal, range: nil)
        return unescaped
    }
    
}
