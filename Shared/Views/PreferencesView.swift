// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel

    var body: some View {
        Form {
            Section(header: Text(viewModel.handle)) {
                NavigationLink("preferences.posting-reading",
                               destination: PostingReadingPreferencesView(
                                viewModel: viewModel.postingReadingPreferencesViewModel()))
            }
        }
        .navigationTitle("preferences")
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: .development)
    }
}
#endif
