///
/// Copyright (c) 2022 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

import Foundation
import SwiftyDropbox

/// Objective-C compatible DropboxTeamBase.
/// For Swift see DropboxTeamBase.
@objc
public class DBXDropboxTeamBase: NSObject {
    let swift: DropboxTeamBase

    /// Routes within the team namespace. See DBTeamRoutes for details.
    @objc
    public var team: DBXTeamRoutes!

    @objc
    public convenience init(client: DBXDropboxTransportClient) {
        self.init(swiftClient: client.swift)
    }

    public init(swiftClient: DropboxTransportClient) {
        self.swift = DropboxTeamBase(client: swiftClient)

        self.team = DBXTeamRoutes(swift: swift.team)
    }
}
