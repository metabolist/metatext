// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct StatusesView: View {
    @StateObject var viewModel: StatusesViewModel

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(zip(viewModel.statusSections.indices, viewModel.statusSections)),
                        id: \.0) { _, statuses in
                    ForEach(statuses) { status in
                        Text(status.content)
                        Divider()
                    }
                }
            }
        }
        .onAppear { viewModel.request() }
        .alertItem($viewModel.alertItem)
    }
}

#if DEBUG
struct StatusesView_Previews: PreviewProvider {
    static var previews: some View {
        StatusesView(viewModel: .development)
    }
}
#endif
