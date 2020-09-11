// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct AddIdentityView: View {
    @StateObject var viewModel: AddIdentityViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Form {
            Section {
                TextField("add-identity.instance-url", text: $viewModel.urlFieldText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                Group {
                    if viewModel.loading {
                        ProgressView()
                    } else {
                        Button("add-identity.log-in",
                               action: viewModel.logInTapped)
                        if viewModel.isPublicTimelineAvailable {
                            Button("add-identity.browse-anonymously", action: viewModel.browseAnonymouslyTapped)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            if let instance = viewModel.instance {
                Section {
                    VStack(alignment: .center) {
                        KFImage(instance.thumbnail)
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fill)
                        Text(instance.title)
                            .font(.headline)
                        Text(instance.uri)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .animation(.default)
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.addedIdentityID) { id in
            withAnimation {
                rootViewModel.identitySelected(id: id)
            }
        }
        .onAppear(perform: viewModel.refreshFilter)
    }
}

extension AddIdentityError: LocalizedError {
    public var errorDescription: String? {
        NSLocalizedString("add-identity.unable-to-connect-to-instance", comment: "")
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
