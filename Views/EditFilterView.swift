// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import struct Mastodon.Filter
import ViewModels

struct EditFilterView: View {
    @StateObject var viewModel: EditFilterViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("filter.keyword-or-phrase")) {
                TextField("filter.keyword-or-phrase", text: $viewModel.filter.phrase)
            }

            Section {
                if viewModel.isNew || viewModel.filter.expiresAt == nil {
                    Toggle("filter.never-expires", isOn: .init(
                            get: { viewModel.filter.expiresAt == nil },
                            set: { viewModel.filter.expiresAt = $0 ? nil : viewModel.date }))
                }

                if viewModel.filter.expiresAt != nil {
                    DatePicker(selection: $viewModel.date, in: Date()...) {
                        Text("filter.expire-after")
                    }
                }
            }

            Section(header: Text("filter.contexts")) {
                ForEach(Filter.Context.allCasesExceptUnknown) { context in
                    Toggle(context.localized, isOn: .init(
                            get: { viewModel.filter.context.contains(context) },
                            set: { _ in viewModel.toggleSelection(context: context) }))
                }
            }

            Section {
                Toggle(isOn: $viewModel.filter.irreversible, label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("filter.irreversible")
                        Text("filter.irreversible-explanation")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                })
            }

            Section {
                Toggle(isOn: $viewModel.filter.wholeWord, label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("filter.whole-word")
                        Text("filter.whole-word-explanation")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                })
            }
        }
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.saveCompleted) { presentationMode.wrappedValue.dismiss() }
        .navigationTitle(viewModel.isNew ? "filter.add-new" : "filter.edit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Group {
                    if viewModel.saving {
                        ProgressView()
                    } else {
                        Button(viewModel.isNew ? "add" : "filter.save-changes",
                            action: viewModel.save)
                            .disabled(viewModel.isSaveDisabled)
                    }
                }
            }
        }
    }
}

extension Filter.Context {
    var localized: String {
        switch self {
        case .home:
            return NSLocalizedString("filter.context.home", comment: "")
        case .notifications:
            return NSLocalizedString("filter.context.notifications", comment: "")
        case .public:
            return NSLocalizedString("filter.context.public", comment: "")
        case .thread:
            return NSLocalizedString("filter.context.thread", comment: "")
        case .account:
            return NSLocalizedString("filter.context.account", comment: "")
        case .unknown:
            return NSLocalizedString("filter.context.unknown", comment: "")
        }
    }
}

#if DEBUG
import PreviewViewModels

struct EditFilterView_Previews: PreviewProvider {
    static var previews: some View {
        EditFilterView(viewModel: .mock())
    }
}
#endif
