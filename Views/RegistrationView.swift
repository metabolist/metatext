// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel

    @State private var presentWebView = false
    @State private var toReview = ToReview.serverRules

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("registration.username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Text("@" + viewModel.instance.uri)
                        .foregroundColor(.secondary)
                }
                TextField("registration.email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                SecureField("registration.password", text: $viewModel.password)
                SecureField("registration.password-confirmation", text: $viewModel.passwordConfirmation)
                if viewModel.instance.approvalRequired {
                    VStack(alignment: .leading) {
                        Text("registration.reason-\(viewModel.instance.uri)")
                        TextEditor(text: $viewModel.reason)
                    }
                }
                Button("registration.server-rules") {
                    toReview = .serverRules
                    presentWebView = true
                }
                Button("registration.terms-of-service") {
                    toReview = .termsOfService
                    presentWebView = true
                }
                Toggle("registration.agree-to-server-rules-and-terms-of-service",
                       isOn: $viewModel.agreement)
            }
            Section {
                Group {
                    if viewModel.registering {
                        ProgressView()
                    } else {
                        Button(viewModel.instance.approvalRequired
                                ? "add-identity.request-invite"
                                : "add-identity.join",
                               action: viewModel.registerTapped)
                            .disabled(!viewModel.registerButtonEnabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .alertItem($viewModel.alertItem)
        .sheet(isPresented: $presentWebView) { () -> SafariView in
            let url: URL

            switch toReview {
            case .serverRules: url = viewModel.serverRulesURL
            case .termsOfService: url = viewModel.termsOfServiceURL
            }

            return SafariView(url: url)
        }
    }
}

private extension RegistrationView {
    enum ToReview {
        case serverRules
        case termsOfService
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
