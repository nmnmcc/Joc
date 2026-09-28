// SPDX-License-Identifier: GPL-2.0-only

import CloudKit
import Foundation

enum JocConfiguration {
    static let containerIdentifier = "iCloud.cc.nmnm.joc"
    static let commandRecordType = "LockCommand"
    static let currentCommandRecordName = "current"
    static let statusRecordType = "LockStatus"
    static let currentStatusRecordName = "current"
    static let lockAction = "lock"
    static let pollingIntervalNanoseconds: UInt64 = 2_000_000_000
}

enum LockState: String, Sendable, Equatable {
    case unknown
    case ready
    case waiting
    case locking
    case locked
    case failed
    case offline

    var title: String {
        switch self {
        case .unknown:
            "Not connected"
        case .ready:
            "Mac ready"
        case .waiting:
            "Waiting for Mac"
        case .locking:
            "Locking"
        case .locked:
            "Mac locked"
        case .failed:
            "Could not lock"
        case .offline:
            "Mac offline"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown, .offline:
            "lock.slash"
        case .ready:
            "lock.open"
        case .waiting:
            "clock"
        case .locking:
            "lock.rotation"
        case .locked:
            "lock.fill"
        case .failed:
            "exclamationmark.triangle"
        }
    }
}

struct LockCommand: Sendable, Identifiable {
    let id: UUID
    let action: String
    let createdAt: Date
    let source: String
}

struct LockStatusSnapshot: Sendable, Equatable {
    let state: LockState
    let updatedAt: Date
    let message: String?
    let processedCommandID: UUID?
    let hostName: String?

    static let unknown = LockStatusSnapshot(
        state: .unknown,
        updatedAt: .distantPast,
        message: nil,
        processedCommandID: nil,
        hostName: nil
    )

    static func state(
        _ state: LockState,
        message: String? = nil,
        processedCommandID: UUID? = nil,
        hostName: String? = nil
    ) -> LockStatusSnapshot {
        LockStatusSnapshot(
            state: state,
            updatedAt: Date(),
            message: message,
            processedCommandID: processedCommandID,
            hostName: hostName
        )
    }
}

enum JocError: LocalizedError {
    case invalidCommand
    case accountUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidCommand:
            "The CloudKit command was incomplete."
        case .accountUnavailable:
            "Sign in to iCloud on this device to use Joc."
        }
    }
}

actor CloudKitStore {
    private let database: CKDatabase

    init(container: CKContainer = CKContainer(identifier: JocConfiguration.containerIdentifier)) {
        database = container.privateCloudDatabase
    }

    func requestLock(source: String) async throws -> LockCommand {
        let command = LockCommand(
            id: UUID(),
            action: JocConfiguration.lockAction,
            createdAt: Date(),
            source: source
        )

        let recordID = CKRecord.ID(recordName: JocConfiguration.currentCommandRecordName)
        let record: CKRecord

        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: JocConfiguration.commandRecordType, recordID: recordID)
        }

        record["commandID"] = command.id.uuidString as CKRecordValue
        record["action"] = command.action as CKRecordValue
        record["createdAt"] = command.createdAt as CKRecordValue
        record["source"] = command.source as CKRecordValue

        _ = try await database.save(record)
        return command
    }

    func latestCommand() async throws -> LockCommand? {
        let recordID = CKRecord.ID(recordName: JocConfiguration.currentCommandRecordName)
        let record: CKRecord

        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }

        guard let id = UUID(uuidString: record["commandID"] as? String ?? ""),
              let action = record["action"] as? String,
              let createdAt = record["createdAt"] as? Date
        else {
            throw JocError.invalidCommand
        }

        return LockCommand(
            id: id,
            action: action,
            createdAt: createdAt,
            source: record["source"] as? String ?? "Unknown"
        )
    }

    func fetchStatus() async throws -> LockStatusSnapshot? {
        let id = CKRecord.ID(recordName: JocConfiguration.currentStatusRecordName)

        do {
            let record = try await database.record(for: id)
            return status(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func updateStatus(_ snapshot: LockStatusSnapshot) async throws {
        let id = CKRecord.ID(recordName: JocConfiguration.currentStatusRecordName)
        let record: CKRecord

        do {
            record = try await database.record(for: id)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: JocConfiguration.statusRecordType, recordID: id)
        }

        record["state"] = snapshot.state.rawValue as CKRecordValue
        record["updatedAt"] = snapshot.updatedAt as CKRecordValue

        if let message = snapshot.message {
            record["message"] = message as CKRecordValue
        } else {
            record["message"] = nil
        }

        if let processedCommandID = snapshot.processedCommandID {
            record["processedCommandID"] = processedCommandID.uuidString as CKRecordValue
        } else {
            record["processedCommandID"] = nil
        }

        if let hostName = snapshot.hostName {
            record["hostName"] = hostName as CKRecordValue
        } else {
            record["hostName"] = nil
        }

        _ = try await database.save(record)
    }

    private func status(from record: CKRecord) -> LockStatusSnapshot {
        LockStatusSnapshot(
            state: LockState(rawValue: record["state"] as? String ?? "unknown") ?? .unknown,
            updatedAt: record["updatedAt"] as? Date ?? .distantPast,
            message: record["message"] as? String,
            processedCommandID: UUID(uuidString: record["processedCommandID"] as? String ?? ""),
            hostName: record["hostName"] as? String
        )
    }
}
