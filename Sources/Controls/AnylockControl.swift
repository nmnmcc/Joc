// SPDX-License-Identifier: GPL-2.0-only

import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct AnylockControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "cc.nmnm.anylock.control") {
            ControlWidgetButton(action: LockMacIntent()) {
                Label("Lock Mac", systemImage: "lock.fill")
            }
        }
        .displayName("Joc")
        .description("Lock the connected Mac")
    }
}

@main
struct AnylockControlBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            AnylockControl()
        }
    }
}
