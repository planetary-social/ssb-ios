//
//  Key.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public struct Key: Hashable {

    static let unsupported = Key("unsupported")

    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// The base64 number between the sigil, marker, and algorithm
    var identifier: String {
        let components = rawValue.components(separatedBy: ".")
        guard components.count == 2 else { return Key.unsupported.rawValue }
        let component = components[0] as String
        guard component.count > 1 else { return Key.unsupported.rawValue }
        guard component.hasSuffix("=") else { return Key.unsupported.rawValue }
        guard component.sigil != Sigil.unsupported else { return Key.unsupported.rawValue }
        let index = component.index(after: component.startIndex)
        return String(component[index...])
    }

    /// The first character of the identifier indicating what kind of identifier this is
    var sigil: Sigil {
        return rawValue.sigil
    }

    /// The trailing suffix indicating how the id is encoded
    var algorithm: Algorithm {
        if      rawValue.hasSuffix(Algorithm.sha256.rawValue)   { return .sha256 }
        else if rawValue.hasSuffix(Algorithm.ed25519.rawValue)  { return .ed25519 }
        else if rawValue.hasSuffix(Algorithm.ggfeed.rawValue)   { return .ggfeed }
        else                                                    { return .unsupported }
    }

    var isValidIdentifier: Bool {
        return sigil != .unsupported &&
               identifier != Key.unsupported.rawValue &&
               algorithm != .unsupported
    }

    var identifierBytes: Data? {
        guard isValidIdentifier else {
            #if DEBUG
            print("warning: invalid identifier:\(self)")
            #endif
            return nil
        }
        return Data(base64Encoded: self.identifier, options: .ignoreUnknownCharacters)
    }

    var hexEncodedString: String {
        guard let bytes = identifierBytes else {
            return ""
        }

        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(bytes.count * 2)

        for byte in bytes {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }

        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }

    public var hashValue: Int {
        return rawValue.hashValue
    }
    
}
