//
//  SSBError.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public enum SSBError {
    case alreadyStarted
    case duringProcessing(String, Error)
    case unexpectedFault(String)
}

extension SSBError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .alreadyStarted:
            return "Already started"
        case .duringProcessing(let string, let error):
            return "\(string): \(error.localizedDescription)"
        case .unexpectedFault(let string):
            return "Unexpected fault: \(string)"
        }
    }

}
