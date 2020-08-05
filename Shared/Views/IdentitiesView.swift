// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct IdentitiesView: View {
    @StateObject var viewModel: IdentitiesViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Form {
            Section {
                NavigationLink(
                    destination: AddIdentityView(viewModel: rootViewModel.addIdentityViewModel()),
                    label: {
                        Label("add new account", systemImage: "plus")
                    })
            }
            Section {
                List(viewModel.identities) { identity in
                    Button(identity.handle) {
                        rootViewModel.newIdentitySelected(id: identity.id)
                    }
                }
            }
        }
    }
}

struct IdentitiesView_Previews: PreviewProvider {
    static var previews: some View {
        IdentitiesView(viewModel: .development)
            .environmentObject(RootViewModel.development)
    }
}
