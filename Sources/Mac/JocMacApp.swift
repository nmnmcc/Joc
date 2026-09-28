// SPDX-License-Identifier: GPL-2.0-only

import AppKit
import SwiftUI

@main
struct JocMacApp: App {
    @StateObject private var agent: MacAgent

    init() {
        let agent = MacAgent()
        agent.start()
        _agent = StateObject(wrappedValue: agent)
    }

    var body: some Scene {
        MenuBarExtra {
            MacMenuView(agent: agent)
        } label: {
            Label("Joc", systemImage: agent.status.state.symbolName)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class MacAgent: ObservableObject {
    @Published private(set) var status = LockStatusSnapshot.unknown

    private let store = CloudKitStore()
    private var pollTask: Task<Void, Never>?
    private var isPolling = false
    private var hasRemoteStatus = false
    private let processedCommandKey = "Joc.lastProcessedCommandID"

    deinit {
        pollTask?.cancel()
    }

    func start() {
        guard pollTask == nil else {
            return
        }

        pollTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func checkNow() {
        start()
        Task { [weak self] in
            await self?.pollForCommand()
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func refreshStatus() async {
        do {
            if let snapshot = try await store.fetchStatus() {
                status = snapshot
                hasRemoteStatus = true
            }
        } catch {
            status = .state(.offline, message: error.localizedDescription)
        }
    }

    private func runLoop() async {
        await refreshStatus()

        if !hasRemoteStatus {
            let ready = LockStatusSnapshot.state(
                .ready,
                message: "Waiting for a lock request",
                hostName: Host.current().localizedName ?? ProcessInfo.processInfo.hostName
            )
            await publish(ready)
            try? await store.updateStatus(ready)
        }

        while !Task.isCancelled {
            await pollForCommand()

            do {
                try await Task.sleep(nanoseconds: JocConfiguration.pollingIntervalNanoseconds)
            } catch {
                return
            }
        }
    }

    private func pollForCommand() async {
        guard !isPolling else {
            return
        }

        isPolling = true
        defer { isPolling = false }

        do {
            guard let command = try await store.latestCommand() else {
                if status.state == .unknown || status.state == .offline {
                    await publish(.state(.ready, message: "Waiting for a lock request"))
                }
                return
            }

            guard command.action == JocConfiguration.lockAction else {
                return
            }

            let commandID = command.id.uuidString
            if commandID == UserDefaults.standard.string(forKey: processedCommandKey) {
                return
            }

            if status.processedCommandID == command.id {
                UserDefaults.standard.set(commandID, forKey: processedCommandKey)
                return
            }

            let hostName = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
            let locking = LockStatusSnapshot.state(
                .locking,
                processedCommandID: command.id,
                hostName: hostName
            )
            await publish(locking)
            try? await store.updateStatus(locking)

            let didLock = ScreenLock.lock()
            let result = LockStatusSnapshot.state(
                didLock ? .locked : .failed,
                message: didLock ? nil : "The screen lock API is unavailable.",
                processedCommandID: command.id,
                hostName: hostName
            )
            UserDefaults.standard.set(command.id.uuidString, forKey: processedCommandKey)
            await publish(result)
            try? await store.updateStatus(result)
        } catch {
            await publish(.state(.offline, message: error.localizedDescription))
        }
    }

    private func publish(_ snapshot: LockStatusSnapshot) async {
        status = snapshot
    }
}

struct MacMenuView: View {
    @ObservedObject var agent: MacAgent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(agent.status.state.title, systemImage: agent.status.state.symbolName)
                .font(.headline)

            if let hostName = agent.status.hostName {
                Text(hostName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = agent.status.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Check Now", action: agent.checkNow)
            Button("Quit Joc", role: .destructive, action: agent.quit)
        }
        .padding(12)
        .task {
            await agent.refreshStatus()
        }
    }
}
