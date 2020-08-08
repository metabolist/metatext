// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import KingfisherSwiftUI

struct IdentitiesView: View {
    @StateObject var viewModel: IdentitiesViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        Form {
            Section {
                NavigationLink(
                    destination: AddIdentityView(viewModel: rootViewModel.addIdentityViewModel()),
                    label: {
                        Label("identities.add", systemImage: "plus.circle")
                    })
            }
            Section {
                List {
                    ForEach(viewModel.identities) { identity in
                        Button {
                            withAnimation {
                                rootViewModel.newIdentitySelected(id: identity.id)
                            }
                        } label: {
                            HStack {
                                KFImage(identity.image,
                                        options: .downsampled(dimension: 28, scaleFactor: displayScale))
                                Text(identity.handle)
                                Spacer()
                                if identity.id == viewModel.identity.id {
                                    Image(systemName: "checkmark.circle")
                                }
                            }
                        }
                        .disabled(identity.id == viewModel.identity.id)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete {
                        guard let index = $0.first else { return }

                        rootViewModel.deleteIdentity(id: viewModel.identities[index].id)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                EditButton()
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
