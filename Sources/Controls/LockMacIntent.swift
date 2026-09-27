// SPDX-License-Identifier: GPL-2.0-only

import AppIntents
import CloudKit

@available(iOS 18.0, watchOS 26.0, *)
struct LockMacIntent: AppIntent {
    static let title: LocalizedStringResource = "Lock Mac"
    static let description = IntentDescription("Send a lock request to the Mac connected to Joc.")

    func perform() async throws -> some IntentResult {
        _ = try await CloudKitStore().requestLock(source: "Control Center")
        return .result()
    }
}
