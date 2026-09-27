// SPDX-License-Identifier: GPL-2.0-only

import SwiftUI
import WidgetKit

@available(watchOS 26.0, *)
struct AnylockWatchControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "cc.nmnm.anylock.watch-control") {
            ControlWidgetButton(action: LockMacIntent()) {
                Label("Lock Mac", systemImage: "lock.fill")
            }
        }
        .displayName("Joc")
        .description("Lock the connected Mac")
    }
}

@main
struct AnylockWatchControlBundle: WidgetBundle {
    var body: some Widget {
        if #available(watchOS 26.0, *) {
            AnylockWatchControl()
        }
    }
}
