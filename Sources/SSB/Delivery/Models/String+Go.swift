//
//  File.swift
//  
//
//  Created by Martin Dutra on 9/1/22.
//

import Foundation
import GoSSB

extension String {

    func withGoString<R>(_ call: (gostring_t) -> R) -> R {
        func helper(_ pointer: UnsafePointer<Int8>?, _ call: (gostring_t) -> R) -> R {
            return call(gostring_t(p: pointer, n: utf8.count))
        }
        return helper(self, call)
    }
    
}
