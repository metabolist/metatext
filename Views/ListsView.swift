// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct ListsView: View {
    @StateObject var viewModel: ListsViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @State private var newListTitle = ""

    var body: some View {
        Form {
            Section {
                TextField("lists.new-list-title", text: $newListTitle)
                    .disabled(viewModel.creatingList)
                if viewModel.creatingList {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button {
                        viewModel.createList(title: newListTitle)
                    } label: {
                        Label("add", systemImage: "plus.circle")
                    }
                    .disabled(newListTitle == "")
                }
            }
            Section {
                ForEach(viewModel.lists) { list in
                    Button(list.title) {
                        rootViewModel.navigationViewModel?.timeline = .list(list)
                        rootViewModel.navigationViewModel?.presentingSecondaryNavigation = false
                    }
                }
                .onDelete {
                    guard let index = $0.first else { return }

                    viewModel.delete(list: viewModel.lists[index])
                }
            }
        }
        .navigationTitle(Text("secondary-navigation.lists"))
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                EditButton()
            }
        }
        .alertItem($viewModel.alertItem)
        .onAppear(perform: viewModel.refreshLists)
        .onReceive(viewModel.$creatingList) {
            if !$0 {
                newListTitle = ""
            }
        }
    }
}

#if DEBUG
import PreviewViewModels

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        ListsView(viewModel: .init(identification: .preview))
            .environmentObject(TabNavigationViewModel(identification: .preview))
    }
}
#endif
