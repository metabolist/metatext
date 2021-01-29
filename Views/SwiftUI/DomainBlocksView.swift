// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct DomainBlocksView: View {
    @StateObject var viewModel: DomainBlocksViewModel
    var body: some View {
        Form {
            ForEach(viewModel.domainBlocks, id: \.self) { domain in
                Text(domain)
                    .onAppear {
                        if domain == viewModel.domainBlocks.last {
                            viewModel.request()
                        }
                    }
            }
            .onDelete {
                guard let index = $0.first else { return }

                viewModel.delete(domain: viewModel.domainBlocks[index])
            }
            if viewModel.loading {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.request()
        }
        .navigationTitle("preferences.blocked-domains")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                EditButton()
            }
        }
    }
}

#if DEBUG
import PreviewViewModels

struct DomainBlocksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DomainBlocksView(viewModel: .preview)
        }
    }
}
#endif
