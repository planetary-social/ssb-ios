//
//  File.swift
//  
//
//  Created by Martin Dutra on 7/1/22.
//

import Foundation
import GoSSB

public class SSB {

    public static let shared = SSB()

    private var queue: DispatchQueue

    private var repoPath = "/tmp/FBTT/unset"

    init() {
        self.queue = DispatchQueue(label: "SSB",
                                   qos: .utility,
                                   attributes: .concurrent,
                                   autoreleaseFrequency: .workItem,
                                   target: nil)
        NotificationCenter.ssb.addObserver(forName: Notification.Name("did_receive_blob"),
                                            object: nil,
                                            queue: OperationQueue.current) { [weak self] notification in
            guard let key = notification.userInfo?["key"] as? Key else {
                return
            }
            self?.didReceiveBlobHandler?(key)
        }
        NotificationCenter.ssb.addObserver(forName: Notification.Name("new_bearer_token"),
                                            object: nil,
                                            queue: OperationQueue.current) { [weak self] notification in
            guard let token = notification.userInfo?["token"] as? String else {
                return
            }
            guard let expires = notification.userInfo?["expires"] as? Date else {
                return
            }
            self?.didUpdateBearerToken?(token, expires)

        }
        NotificationCenter.ssb.addObserver(forName: Notification.Name("update_fsck_repair"),
                                            object: nil,
                                            queue: OperationQueue.current) { [weak self] notification in
            guard let percent = notification.userInfo?["percent"] as? Double else {
                return
            }
            guard let remainingTime = notification.userInfo?["status"] as? String else {
                return
            }
            self?.didUpdateFSCKRepair?(percent, remainingTime)
        }
    }

    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    public var didReceiveBlobHandler: ((Key) -> Void)? = nil
    public var didUpdateBearerToken: ((String, Date) -> Void)? = nil
    public var didUpdateFSCKRepair: ((Double, String) -> Void)? = nil

    public var version: String {
        guard let v = ssbVersion() else {
            return "binding error"
        }
        return String(cString: v)
    }

    public var isRunning: Bool {
        return ssbBotIsRunning()
    }

    public var openConnections: UInt {
        return UInt(ssbOpenConnections())
    }

    public func openConnectionList() -> [(String, Key)] {
        var open: [(String, Key)] = []
        if let status = try? self.status() {
            for p in  status.Peers {
                // split of multiserver addr format
                // ex: net:1.2.3.4:8008~shs:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
                if !p.Addr.hasPrefix("net:") {
                    continue
                }

                let hostWithPubkey = p.Addr.dropFirst(4)
                guard let startOfPubKey = hostWithPubkey.firstIndex(of: "~") else {
                    continue
                }

                let host = hostWithPubkey[..<startOfPubKey]
                let keyB64Start = hostWithPubkey.index(startOfPubKey, offsetBy: 5) // ~shs:
                let pubkey = hostWithPubkey[keyB64Start...]

                open.append((String(host), Key(String(pubkey))))
            }
        }
        return open
    }

    public func createSecret() throws -> Secret? {
        guard let kp = ssbGenKey() else {
            throw SSBError.unexpectedFault("createSecret failed")
        }
        let secret = Secret(from: String(cString: kp))
        free(kp)
        return secret
    }

    /// blobReceivedHandler: gets called with the Key of the blob received
    /// newBearerTokenHandler: get's called with a token and an expiry date as unix timestamp
    public func start(network: DataKey,
                      hmacKey: DataKey? = nil,
                      secret: Secret,
                      path: String,
                      port: Int = 8000,
                      hops: UInt = 1,
                      schemaVersion: UInt = 0,
                      servicePubs: [Key]? = nil) -> Bool {

        let cBlobReceivedHandler: @convention(c) (Int64, UnsafePointer<Int8>?) -> Bool = { _, ref in
            guard let ref = ref else {
                return false
            }
            let key = Key(String(cString: ref))
            NotificationCenter.ssb.postSSBDidReceiveBlob(key: key)
            return true
        }

        let cNewBearerTokenHandler: @convention(c) (UnsafePointer<Int8>?, Int64) -> Void = { cstr, expires in
            let now = Int64(Date.init().timeIntervalSince1970)
            guard expires - now > 0 else {
                print("received expired token? \(expires)")
                return
            }
            guard let token = cstr else {
                return
            }
            let tok = String(cString: token)
            let expiresWhen = Date(timeIntervalSince1970: Double(expires))
            NotificationCenter.ssb.postSSBDidNotifyNewBearerToken(token: tok, expires: expiresWhen)
        }

        let config = Config(
            AppKey: network.string,
            HMACKey: hmacKey == nil ? "" : hmacKey!.string,
            KeyBlob: secret.jsonString()!,
            Repo: path,
            ListenAddr: ":\(port)",
            Hops: hops,
            SchemaVersion: schemaVersion,
            ServicePubs: servicePubs?.map { $0.rawValue } ?? [])

        let enc = JSONEncoder()
        var cfgStr: String
        do {
            let d = try enc.encode(config)
            cfgStr = String(data: d, encoding: .utf8)!
        } catch {
            // return SSBError.duringProcessing("config prep failed", error)
            return false
        }

        var worked = false
        cfgStr.withGoString {
            cfgGoStr in
            worked = ssbBotInit(cfgGoStr, cBlobReceivedHandler, cNewBearerTokenHandler)
        }
        if worked {
            repoPath = config.Repo
        }
        return worked
    }

    public func stop() -> Bool {
        return ssbBotStop()
    }

    @discardableResult
    public func disconnectAll() -> Bool {
        return ssbDisconnectAllPeers()
    }

    public func connectPeers(count: UInt32) -> Bool {
        return ssbConnectPeers(count)
    }

    public func connect(peer: Peer) -> Bool {
        let multiServ = "net:\(peer.tcpAddr)~shs:\(peer.key.identifier)"
        var worked = false
        multiServ.withGoString {
            worked = ssbConnectPeer($0)
        }
        return worked
    }

    public func statistics() throws -> RepoStatus {
        guard let counts = ssbRepoStats() else {
            throw SSBError.unexpectedFault("failed to get repo counts")
        }
        let countData = String(cString: counts).data(using: .utf8)!
        free(counts)
        let dec = JSONDecoder()
        return try dec.decode(RepoStatus.self, from: countData)
    }

    /// progressHandler: get's called with the messages left to process
    public func fsck(mode: FSCKMode) -> Bool {
        let cProgressHandler: @convention(c) (Float64, UnsafePointer<Int8>?) -> Void = { percDone, cRemaining in
            guard let cRemaining = cRemaining else {
                return
            }
            let timeRemaining = String(cString: cRemaining)
            let perc = percDone/100
            NotificationCenter.ssb.postSSBDidUpdateFSCKRepair(percent: perc, status: timeRemaining)
        }
        let ret = ssbOffsetFSCK(mode.rawValue, cProgressHandler)
        return ret == 0
    }

    public func heal() throws -> HealReport {
        guard let reportData = ssbHealRepo() else {
            throw SSBError.unexpectedFault("repo healing failed")
        }
        let d = String(cString: reportData).data(using: .utf8)!
        free(reportData)
        let dec = JSONDecoder()
        return try dec.decode(HealReport.self, from: d)
    }

    public func status() throws -> Status {
        guard let status = ssbBotStatus() else {
            throw SSBError.unexpectedFault("failed to get bot status")
        }
        let d = String(cString: status).data(using: .utf8)!
        free(status)
        let dec = JSONDecoder()
        return try dec.decode(Status.self, from: d)
    }

    public func block(feed: Key) {
        feed.rawValue.withGoString {
            ssbFeedBlock($0, true)
        }
    }

    public func unblock(feed: Key) {
        feed.rawValue.withGoString {
            ssbFeedBlock($0, false)
        }
    }

    /// Call this to fetch a feed without following it
    public func replicate(feed: Key) {
        feed.rawValue.withGoString {
            ssbFeedReplicate($0, true)
        }
    }

    public func dontReplicate(feed: Key) {
        feed.rawValue.withGoString {
            ssbFeedReplicate($0, false)
        }
    }

    public func nullContent(author: Key, sequence: UInt) throws -> Bool {
        guard author.algorithm == .ggfeed else {
            throw SSBError.unexpectedFault("unsupported feed format for deletion")
        }
        var worked = false
        author.rawValue.withGoString { goAuthor in
            worked = ssbNullContent(goAuthor, UInt64(sequence)) == 0
        }
        return worked
    }

    public func nullFeed(author: Key) -> Bool {
        var worked = false
        author.rawValue.withGoString { goAuthor in
            worked = ssbNullFeed(goAuthor) == 0
        }
        return worked
    }

    // MARK: Blobs

    public func addBlob(data: Data) throws -> Key {
        let p = Pipe()

        queue.async {
            p.fileHandleForWriting.write(data)
            p.fileHandleForWriting.closeFile()
        }

        let readFD = p.fileHandleForReading.fileDescriptor
        guard let rawBytes = ssbBlobsAdd(readFD) else {
            throw SSBError.unexpectedFault("blobsAdd failed")
        }

        let newRef = String(cString: rawBytes)
        free(rawBytes)

        return Key(newRef)
    }

    public func blobFileURL(ref: Key) throws -> URL {
        let hexRef = ref.hexEncodedString
        guard !hexRef.isEmpty else {
            throw SSBError.unexpectedFault("blobGet: could not make hex representation of blob reference")
        }
         // first 2 chars are directory
        let dir = String(hexRef.prefix(2))
        // rest ist filename
        let restIdx = hexRef.index(hexRef.startIndex, offsetBy:2)
        let rest = String(hexRef[restIdx...])

        var u = URL(fileURLWithPath: repoPath)
        u.appendPathComponent("blobs")
        u.appendPathComponent("sha256")
        u.appendPathComponent(dir)
        u.appendPathComponent(rest)

        return u
    }

    public func blobGet(ref: Key) throws -> Data? {
        let u = try blobFileURL(ref: ref)
        do {
            return try Data(contentsOf: u)
        } catch {
            blobsWant(ref: ref)
            return nil
        }
    }


    @discardableResult
    public func blobsWant(ref: Key) -> Bool {
        var worked = false
        ref.rawValue.withGoString {
            worked = ssbBlobsWant($0)
        }
        return worked
    }

    // MARK: Feed

    /// Retreive a list of stored feeds and their current sequence number
    public func getFeedList() throws -> [Key: Int] {
        let intfd = ssbReplicateUpTo()
        guard intfd != -1 else {
            throw SSBError.unexpectedFault("feedList pre-processing error")
        }

        let file = FileHandle(fileDescriptor: intfd, closeOnDealloc: true)
        let fld = file.readDataToEndOfFile()

        /* form of the response is
              {
                  "feed1": currSeqAsInt,
                  "feed2": currSeqAsInt,
                  "feed3": currSeqAsInt
              }
        */

        do {
            var feeds = [Key: Int]()
            let json = try JSONSerialization.jsonObject(with: fld, options: [])
            if let dictionary = json as? [String: Any] {
                for (feed, val) in dictionary {
                    feeds[Key(feed)] = val as? Int
                }
            }
            return feeds
        } catch {
            throw SSBError.duringProcessing("feedList json decoding error:", error)
        }
    }

    // MARK: Message streams

    // aka createLogStream
    public func getReceiveLog<T: Decodable>(startSeq: Int64, limit: Int) throws -> [T] {
        guard let rawBytes = ssbStreamRootLog(UInt64(startSeq), Int32(limit)) else {
            throw SSBError.unexpectedFault("rxLog pre-processing error")
        }
        let data = String(cString: rawBytes).data(using: .utf8)!
        free(rawBytes)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SSBError.duringProcessing("rxLog json decoding error:", error)
        }
    }

    // aka private.read
    public func getPrivateLog<T: Decodable>(startSeq: Int64, limit: Int) throws -> [T] {
        guard let rawBytes = ssbStreamPrivateLog(UInt64(startSeq), Int32(limit)) else {
            throw SSBError.unexpectedFault("privateLog pre-processing error")
        }

        let data = String(cString: rawBytes).data(using: .utf8)!
        free(rawBytes)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SSBError.duringProcessing("privateLog json decoding error:", error)
        }
    }

    // MARK: Publish

    public func publish(content: String) throws -> Key? {
        var key: Key? = nil
        content.withGoString {
            if let cRef = ssbPublish($0) {
                let newRef = String(cString: cRef)
                free(cRef)
                key = Key(newRef)
            }
        }
        return key
    }

    // MARK: Redeem invites

    public func acceptInvite(token: String) -> Bool {
        var worked = false
        token.withGoString { goStr in
            worked = ssbInviteAccept(goStr)
        }
        return worked
    }

    public func dropIndexData() -> Bool {
        return ssbDropIndexData()
    }
}
