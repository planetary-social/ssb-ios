//
//  DataKey.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

open class DataKey {

    public var data: Data
    public var string: String

    public init?(base64 string: String) {
        guard let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters) else { return nil }
        if data.count != 32 {
            #if DEBUG
            print("warning: invalid network key. only \(data.count) bytes")
            #endif
            return nil
        }
        self.data = data
        self.string = string
    }

    /// This seems like extra work, but the only way to ensure that
    /// the specified Data is base64 is to encode and decode again.
    /// So, leverage the other init() to do this.
    public convenience init?(base64 data: Data) {
        self.init(base64: data.base64EncodedString())
    }

    public func hexEncodedString() -> String {
        let bytes = self.data
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

}

extension DataKey: Equatable {

    public static func == (lhs: DataKey, rhs: DataKey) -> Bool {
        return lhs.string == rhs.string
    }

}
