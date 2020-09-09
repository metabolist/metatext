// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct AddIdentityView: View {
    @StateObject var viewModel: AddIdentityViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Form {
            urlTextField
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
            Group {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Button("add-identity.log-in",
                        action: viewModel.logInTapped)
                    Button("add-identity.browse-anonymously", action: viewModel.browseAnonymouslyTapped)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.addedIdentityID) { id in
            withAnimation {
                rootViewModel.identitySelected(id: id)
            }
        }
        .onAppear(perform: viewModel.refreshFilter)
    }
}

extension AddIdentityView {
    private var urlTextField: some View {
        TextField("add-identity.instance-url", text: $viewModel.urlFieldText)
    }
}

#if DEBUG
import PreviewViewModels

struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddIdentityView(viewModel: RootViewModel.preview.addIdentityViewModel())
    }
}
#endif
