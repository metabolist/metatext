// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct NotificationTypesPreferencesView: View {
    @StateObject var viewModel: NotificationTypesPreferencesViewModel

    var body: some View {
        Form {
            Toggle("preferences.notification-types.follow",
                   isOn: $viewModel.pushSubscriptionAlerts.follow)
            Toggle("preferences.notification-types.favourite",
                   isOn: $viewModel.pushSubscriptionAlerts.favourite)
            Toggle("preferences.notification-types.reblog",
                   isOn: $viewModel.pushSubscriptionAlerts.reblog)
            Toggle("preferences.notification-types.mention",
                   isOn: $viewModel.pushSubscriptionAlerts.mention)
            Toggle("preferences.notification-types.poll",
                   isOn: $viewModel.pushSubscriptionAlerts.poll)
        }
        .navigationTitle("preferences.notification-types")
        .alertItem($viewModel.alertItem)
    }
}

#if DEBUG
import PreviewViewModels

struct NotificationTypesPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationTypesPreferencesView(viewModel: .init(identification: .preview))
    }
}
#endif
