// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel

    @State private var presentURL: URL?

    var body: some View {
        Form {
            HStack {
                TextField("registration.username", text: $viewModel.registration.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Text("@".appending(viewModel.instance.uri))
                    .foregroundColor(.secondary)
            }
            TextField("registration.email", text: $viewModel.registration.email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)
            SecureField("registration.password", text: $viewModel.registration.password)
                .textContentType(.password)
            SecureField("registration.password-confirmation", text: $viewModel.passwordConfirmation)
            if viewModel.instance.approvalRequired {
                VStack(alignment: .leading) {
                    Text("registration.reason-\(viewModel.instance.uri)")
                    TextEditor(text: $viewModel.registration.reason)
                }
            }
            Button("registration.server-rules") { presentURL = viewModel.serverRulesURL }
            Button("registration.terms-of-service") { presentURL = viewModel.termsOfServiceURL }
            Toggle("registration.agree-to-server-rules-and-terms-of-service",
                   isOn: $viewModel.registration.agreement)
            Group {
                if viewModel.registering {
                    ProgressView()
                } else {
                    Button(viewModel.instance.approvalRequired
                            ? "add-identity.request-invite"
                            : "add-identity.join",
                           action: viewModel.registerTapped)
                        .disabled(viewModel.registerDisabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .alertItem($viewModel.alertItem)
        .sheet(item: $presentURL) { SafariView(url: $0) }
    }
}

extension RegistrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .passwordConfirmationMismatch:
            return NSLocalizedString(
                "registration.password-confirmation-mismatch",
                comment: "")
        }
    }
}

#if DEBUG
import PreviewViewModels

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(viewModel: RootViewModel.preview
                            .addIdentityViewModel()
                            .registrationViewModel(instance: .preview,
                                                   url: .previewInstanceURL))
    }
}
#endif
