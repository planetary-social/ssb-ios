//
//  FSCKMode.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation

public enum FSCKMode: UInt32 {

    /// Compares the message count of a feed with the sequence number of last message of a feed
    case feedLength = 1

    /// Goes through all the messages and makes sure the sequences increament correctly for each feed
    case sequences = 2

}
