// Copyright © 2020 Metabolist. All rights reserved.

import KingfisherSwiftUI
import SwiftUI
import ViewModels

struct AddIdentityView: View {
    @StateObject var viewModel: AddIdentityViewModel
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Form {
            Section {
                TextField("add-identity.instance-url", text: $viewModel.urlFieldText)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                if let instance = viewModel.instance {
                    VStack(alignment: .center) {
                        KFImage(instance.thumbnail)
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fill)
                            .background(Color.blue)
                        Spacer()
                        Text(instance.title)
                            .font(.headline)
                        Text(instance.uri)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                }
                Group {
                    if viewModel.loading {
                        ProgressView()
                    } else {
                        Button("add-identity.log-in",
                               action: viewModel.logInTapped)
                        if viewModel.isPublicTimelineAvailable {
                            Button("add-identity.browse", action: viewModel.browseTapped)
                        }
                        if let instance = viewModel.instance,
                           let url = viewModel.url,
                           instance.registrations {
                            NavigationLink(
                                instance.approvalRequired
                                    ? "add-identity.request-invite"
                                    : "add-identity.join",
                                destination: RegistrationView(
                                    viewModel: viewModel.registrationViewModel(
                                        instance: instance,
                                        url: url)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .animation(.default, if: !accessibilityReduceMotion)
        .alertItem($viewModel.alertItem)
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
        NavigationView {
            AddIdentityView(viewModel: RootViewModel.preview.addIdentityViewModel())
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
