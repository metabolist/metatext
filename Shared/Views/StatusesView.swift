// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct StatusesView: View {
    @StateObject var viewModel: StatusesViewModel

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack {
                    ForEach(Array(zip(viewModel.statusSections.indices, viewModel.statusSections)),
                            id: \.0) { _, statuses in
                        ForEach(statuses) { status in
                            if status == viewModel.contextParent {
                                statusView(status: status)
                            } else {
                                NavigationLink(destination:
                                                LazyView(StatusesView(viewModel:
                                                                        viewModel.contextViewModel(status: status)))) {
                                    statusView(status: status)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Divider()
                        }
                    }
                    if viewModel.loading {
                        ProgressView()
                    }
                }
            }
            .onReceive(viewModel.scrollToStatusID.receive(on: DispatchQueue.main)) { id in
                withAnimation {
                    scrollViewProxy.scrollTo(id)
                }
            }
        }
        .onAppear { viewModel.request() }
        .alertItem($viewModel.alertItem)
    }
}

private extension StatusesView {
    func statusView(status: Status) -> some View {
        Text(status.content)
    }
}

#if DEBUG
struct StatusesView_Previews: PreviewProvider {
    static var previews: some View {
        StatusesView(viewModel: .development)
    }
}
#endif
