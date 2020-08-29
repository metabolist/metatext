// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct FiltersView: View {
    @StateObject var viewModel: FiltersViewModel

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: EditFilterView(
                                viewModel: viewModel.editFilterViewModel(filter: .new))) {
                    Label("add", systemImage: "plus.circle")
                }
            }
            Section {
                ForEach(viewModel.filters) { filter in
                    NavigationLink(destination: EditFilterView(
                                    viewModel: viewModel.editFilterViewModel(filter: filter))) {
                        HStack {
                            Text(filter.phrase)
                            Spacer()
                            Text(ListFormatter.localizedString(byJoining: filter.context.map(\.localized)))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("preferences.filters")
        .alertItem($viewModel.alertItem)
        .onAppear(perform: viewModel.refreshFilters)
    }
}

#if DEBUG
struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        FiltersView(viewModel: .development)
    }
}
#endif
