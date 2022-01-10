//
//  String+Sigil.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

extension String {

    /// The first character of the identifier indicating what kind of identifier this is
    var sigil: Sigil {
        if      hasPrefix(Sigil.blob.rawValue)         { return .blob }
        else if hasPrefix(Sigil.feed.rawValue)         { return .feed }
        else if hasPrefix(Sigil.message.rawValue)      { return .message }
        else                                           { return .unsupported }
    }

}
