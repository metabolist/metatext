// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import SwiftUI
import ViewModels

extension View {
    func alertItem(_ alertItem: Binding<AlertItem?>) -> some View {
        alert(item: alertItem) {
            Alert(title: Text($0.error.localizedDescription))
        }
    }

    @ViewBuilder
    func animation(_ animation: Animation?, if condition: Bool) -> some View {
        if condition {
            self.animation(animation)
        } else {
            self
        }
    }
}
