// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct AddIdentityView: View {
    @StateObject var viewModel: AddIdentityViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Form {
            #if os(macOS)
            Spacer()
            urlTextField
            #else
            urlTextField
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
            #endif
            Group {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Button("add-identity.log-in",
                        action: viewModel.logInTapped)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Button("add-identity.browse-anonymously", action: viewModel.browseAnonymouslyTapped)
                .frame(maxWidth: .infinity, alignment: .center)
            #if os(macOS)
            Spacer()
            #endif
        }
        .paddingIfMac()
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.addedIdentityID) { id in
            withAnimation {
                rootViewModel.newIdentitySelected(id: id)
            }
        }
    }
}

extension AddIdentityView {
    private var urlTextField: some View {
        TextField("add-identity.instance-url", text: $viewModel.urlFieldText)
    }
}

private extension View {
    func paddingIfMac() -> some View {
        #if os(macOS)
        return padding()
        #else
        return self
        #endif
    }
}

#if DEBUG
struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddIdentityView(viewModel: .development)
    }
}
#endif
