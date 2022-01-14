import XCTest
@testable import SSB

final class BotTests: XCTestCase {

    var ssb: SSB!
    var config: Config!
    var network: DataKey!
    var hmacKey: DataKey?
    var secret: Secret!
    var port: Int = 0
    var repoPath: String!

    override func setUp() {
        let fm = FileManager.default

        let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!

        // start fresh
        do {
            try fm.removeItem(atPath: appSupportDir.appending("/FBTT"))
        } catch {
            print(error)
            print("removing previous failed - propbably not exists")
        }
    }

    override func tearDown() {
        if let ssb = ssb {
            _ = ssb.stop()
        }
    }

    func testIsRunning() {
        givenAnSSB()
        let expectedValue = false
        XCTAssertEqual(expectedValue, ssb.isRunning)
    }

    func testGetVersion() throws {
        let expectedString = "beta1"
        let ssb = SSB()
        XCTAssertEqual(expectedString, ssb.version)
    }

    func testStart() {
        givenAnSSB()
        givenASecret()
        givenATestNetwork()
        givenAPath()

        let result = afterStarting()
        XCTAssertTrue(result)
    }

    func testPublish() {
        givenAnSSB()
        givenASecret()
        givenATestNetwork()
        givenAPath()
        afterStarting()

        let publishedMessageKey = afterPublishing()
        XCTAssertNotNil(publishedMessageKey)
        XCTAssertTrue(publishedMessageKey!.rawValue.hasPrefix("%"))
        XCTAssertTrue(publishedMessageKey!.rawValue.hasSuffix(Algorithm.ggfeedmsg.rawValue))

        do {
            let result = try ssb.statistics()
            XCTAssertEqual(result.messages, 1)
            XCTAssertEqual(result.lastHash, publishedMessageKey?.rawValue)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetReceiveLog() {
        givenAnSSB()
        givenASecret()
        givenATestNetwork()
        givenAPath()
        afterStarting()

        do {
            let result: [Content] = try ssb.getReceiveLog(startSeq: 1, limit: 1)
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func givenAPath() {
        let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let path = appSupportDir.appending("/FBTT")
        let network = DataKey(base64: "4vVhFHLFHeyutypUO842SyFd5jRIVhAyiZV29ftnKSU=")!
        repoPath = path.appending("/" + network.hexEncodedString())
    }

    private func givenAnSSB() {
        ssb = SSB()
    }

    private func givenASecret() {
        secret = Secret(from: """
        {"curve":"ed25519","id":"@shwQGai09Tv+Pjbgde6lmhQhc34NURtP2iwnI0xsKtQ=.ggfeed-v1","private":"RdUdi8VQFb38R3Tyv9/iWZwRmCy1L1GfbR6JVrTLHkKyHBAZqLT1O/4+NuB17qWaFCFzfg1RG0/aLCcjTGwq1A==.ed25519","public":"shwQGai09Tv+Pjbgde6lmhQhc34NURtP2iwnI0xsKtQ=.ed25519"}
        """)!
    }

    private func givenATestNetwork() {
        network = DataKey(base64: "4vVhFHLFHeyutypUO842SyFd5jRIVhAyiZV29ftnKSU=")!
        hmacKey = DataKey(base64: "1MQuQUGsRDyMyrFQQRdj8VVsBwn/t0bX7QQRQisMWjY=")
        port = 0
    }

    @discardableResult
    private func afterStarting() -> Bool {
        return ssb.start(network: network,
                         hmacKey: hmacKey,
                         secret: secret,
                         path: repoPath,
                         port: 0,
                         servicePubs: [])
    }

    @discardableResult
    private func afterPublishing() -> Key? {
        do {
            return try ssb.publish(content: "{\"content\":\"Hello World\"}")
        } catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }

    private func afterCreatingKeypairs() {
        let nicks = ["alice", "barbara", "claire", "denise", "page"]
        do {
            for n in nicks {
                try ssb.testingCreateKeypair(nick: n)
            }
        } catch {
            XCTFail("create test keys failed: \(error)")
        }
    }

    @discardableResult
    private func afterPublishingAsAlice() -> Key? {
        let nick = "alice"
        let content = Content(string: "Hello World")
        do {
            return try ssb.testingPublishAs(nick: nick, content: content)
        } catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }
}
