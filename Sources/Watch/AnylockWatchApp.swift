// SPDX-License-Identifier: GPL-2.0-only

import SwiftUI

@main
struct AnylockWatchApp: App {
    var body: some Scene {
        WindowGroup {
            AnylockWatchView()
        }
    }
}

@MainActor
final class AnylockWatchModel: ObservableObject {
    @Published private(set) var status = LockStatusSnapshot.unknown
    @Published private(set) var isRequesting = false

    private let store = CloudKitStore()

    func requestLock() {
        guard !isRequesting else {
            return
        }

        isRequesting = true
        status = .state(.waiting)

        Task {
            do {
                _ = try await store.requestLock(source: "Apple Watch")
            } catch {
                status = .state(.failed, message: error.localizedDescription)
            }
            isRequesting = false
        }
    }

    func refresh() async {
        do {
            if let snapshot = try await store.fetchStatus() {
                status = snapshot
            }
        } catch {
            status = .state(.offline, message: error.localizedDescription)
        }
    }
}

struct AnylockWatchView: View {
    @StateObject private var model = AnylockWatchModel()

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: model.status.state.symbolName)
                .font(.title2)
                .foregroundStyle(model.status.state == .locked ? .green : .primary)

            Text(model.status.state.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button(action: model.requestLock) {
                Label("Lock", systemImage: "lock.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isRequesting)
        }
        .padding()
        .task {
            await model.refresh()
        }
    }
}
