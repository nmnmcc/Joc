// SPDX-License-Identifier: GPL-2.0-only

import SwiftUI

@main
struct JocApp: App {
    @StateObject private var model = JocAppModel()

    var body: some Scene {
        WindowGroup {
            JocRootView(model: model)
        }
    }
}

@MainActor
final class JocAppModel: ObservableObject {
    @Published private(set) var status = LockStatusSnapshot.unknown
    @Published private(set) var isRequesting = false
    @Published private(set) var errorMessage: String?

    private let store = CloudKitStore()

    func requestLock() {
        guard !isRequesting else {
            return
        }

        isRequesting = true
        errorMessage = nil
        status = .state(.waiting)

        Task {
            do {
                let command = try await store.requestLock(source: "iPhone")
                await waitForResult(of: command.id)
            } catch {
                status = .state(.failed)
                errorMessage = error.localizedDescription
            }

            isRequesting = false
        }
    }

    private func waitForResult(of commandID: UUID) async {
        for _ in 0 ..< 12 {
            try? await Task.sleep(nanoseconds: 500_000_000)

            do {
                guard let snapshot = try await store.fetchStatus() else {
                    continue
                }

                if snapshot.processedCommandID == commandID {
                    status = snapshot
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
    }

    func refresh() async {
        do {
            if let snapshot = try await store.fetchStatus() {
                status = snapshot
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}

struct JocRootView: View {
    @ObservedObject var model: JocAppModel

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: model.status.state.symbolName)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(model.status.state == .locked ? .green : .primary)
                .frame(width: 64, height: 64)

            VStack(spacing: 5) {
                Text(model.status.state.title)
                    .font(.headline)

                if let hostName = model.status.hostName {
                    Text(hostName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let message = model.status.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button(action: model.requestLock) {
                Label("Lock Mac", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isRequesting)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .navigationTitle("Joc")
        .task {
            await model.refresh()
        }
        .refreshable {
            await model.refresh()
        }
        .alert("Joc", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: {
                if !$0 {
                    model.dismissError()
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }
}
