//
//  Sigil.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

enum Sigil: String, Codable {
    case blob = "&"
    case feed = "@"     // identity is also @
    case message = "%"  // link is also %
    case unsupported
}
