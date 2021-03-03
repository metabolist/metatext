// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct AddRemoveFromListsView: View {
    @StateObject var viewModel: AddRemoveFromListsViewModel

    var body: some View {
        Group {
            if viewModel.loaded {
                List(viewModel.lists) { list in
                    Button {
                        if viewModel.listIdsWithAccount.contains(list.id) {
                            viewModel.removeFromList(id: list.id)
                        } else {
                            viewModel.addToList(id: list.id)
                        }
                    } label: {
                        HStack {
                            Text(list.title)
                            if viewModel.listIdsWithAccount.contains(list.id) {
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .accessibility(addTraits: viewModel.listIdsWithAccount.contains(list.id) ? [.isSelected] : [])
                }
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: viewModel.refreshLists)
        .onAppear(perform: viewModel.fetchListsWithAccount)
        .navigationTitle(Text("secondary-navigation.lists"))
        .alertItem($viewModel.alertItem)
    }
}
