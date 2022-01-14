//
//  NotificationCenter+SSB.swift
//  
//
//  Created by Martin Dutra on 13/1/22.
//

import Foundation

extension NotificationCenter {

    static let ssb = NotificationCenter()

    func postSSBDidReceiveBlob(key: Key) {
        post(name: Notification.Name("did_receive_blob"),
             object: SSB.shared,
             userInfo: ["key": key])
    }

    func postSSBDidUpdateFSCKRepair(percent: Double, status: String) {
        post(name: Notification.Name("update_fsck_repair"),
             object: SSB.shared,
             userInfo: ["percent": percent,
                        "status": status])
    }

    func postSSBDidNotifyNewBearerToken(token: String, expires: Date) {
        post(name: Notification.Name("new_bearer_token"),
             object: SSB.shared,
             userInfo: ["token": token,
                        "expires": expires])
    }

}
