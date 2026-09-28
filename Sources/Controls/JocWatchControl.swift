// SPDX-License-Identifier: GPL-2.0-only

import SwiftUI
import WidgetKit

@available(watchOS 26.0, *)
struct JocWatchControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "cc.nmnm.joc.watch-control") {
            ControlWidgetButton(action: LockMacIntent()) {
                Label("Lock Mac", systemImage: "lock.fill")
            }
        }
        .displayName("Joc")
        .description("Lock the connected Mac")
    }
}

@main
struct JocWatchControlBundle: WidgetBundle {
    var body: some Widget {
        if #available(watchOS 26.0, *) {
            JocWatchControl()
        }
    }
}
