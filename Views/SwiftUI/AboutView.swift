// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct AboutView: View {
    @StateObject var viewModel: NavigationViewModel

    var body: some View {
        Form {
            Section {
                VStack(spacing: .defaultSpacing) {
                    Text("metatext")
                        .font(.largeTitle)
                    Text(verbatim: "\(Self.version) (\(Self.build))")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Section(header: Text("about.made-by-metabolist")) {
                Button {
                    viewModel.navigateToOfficialAccount()
                } label: {
                    Label {
                        Text("about.official-account").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "checkmark.seal")
                    }
                }
                Link(destination: Self.websiteURL) {
                    Label {
                        Text("about.website").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "link")
                    }
                }
            }
            Section {
                NavigationLink(
                    destination: AcknowledgmentsView()) {
                    Label("about.acknowledgments", systemImage: "curlybraces")
                }
            }
        }
        .navigationTitle("about")
    }
}

private extension AboutView {
    static let websiteURL = URL(string: "https://metabolist.org")!
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
    }
}

#if DEBUG
import PreviewViewModels

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(viewModel: NavigationViewModel(identityContext: .preview))
    }
}
#endif
