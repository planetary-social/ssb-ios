//
//  SSB+Testing.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation
import GoSSB

extension SSB {

    func testingCreateKeypair(nick: String) throws {
        var err: Error? = nil
        nick.withGoString {
            let ok = ssbTestingMakeNamedKey($0)
            if ok != 0 {
                err = SSBError.unexpectedFault("failed to create test key")
            }
        }

        if let e = err { throw e }
    }

    func testingPublishAs<T: Encodable>(nick: String, content: T) throws -> Key? {
        var contentStr: String = ""
        do {
            let cData = try JSONEncoder().encode(content)
            contentStr = String(data: cData, encoding: .utf8) ?? "]},invalid]-warning:invalid content"
        } catch {
            throw SSBError.duringProcessing("publish: failed to write content", error)
        }

        var key: Key? = nil
        contentStr.withGoString { goStrContent in
            nick.withGoString { goStrNick in
                guard let refCstr = ssbTestingPublishAs(goStrNick, goStrContent) else {
                    return
                }

                let newRef = String(cString: refCstr)
                free(refCstr)
                key = Key(newRef)
            }
        }
        return key
    }
}
