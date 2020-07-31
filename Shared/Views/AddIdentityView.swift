// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct AddIdentityView: View {
    @StateObject var viewModel: AddIdentityViewModel

    var body: some View {
        Form {
            #if os(iOS)
            urlTextField
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
            #else
            urlTextField
            #endif
            Group {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Button(
                        action: viewModel.goTapped,
                        label: { Text("go") })
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .alertItem($viewModel.alertItem)
    }
}

extension AddIdentityView {
    private var urlTextField: some View {
        TextField("add-identity.instance-url", text: $viewModel.urlFieldText)
    }
}

#if DEBUG
struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddIdentityView(viewModel: AddIdentityViewModel(
                            networkClient: MastodonClient.development,
                            // swiftlint:disable force_try
                            identityDatabase: try! IdentityDatabase(inMemory: true),
                            // swiftlint:enable force_try
                            secrets: Secrets(keychain: FakeKeychain())))
    }
}
#endif
