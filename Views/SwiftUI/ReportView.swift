// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct ReportView: View {
    @StateObject var viewModel: ReportViewModel

    @Environment(\.presentationMode) private var presentationMode
    fileprivate var dismissHostingController: (() -> Void)?

    var body: some View {
        Form {
            if let statusViewModel = viewModel.statusViewModel {
                Section {
                    ReportStatusView(viewModel: statusViewModel)
                        .frame(height: Self.statusHeight)
                }
            }
            Section {
                Text("report.hint")
            }
            Section(header: Text("report.additional-comments")) {
                TextEditor(text: $viewModel.elements.comment)
                    .accessibility(label: Text("report.additional-comments"))
            }
            if !viewModel.isLocalAccount {
                Section {
                    VStack(alignment: .leading) {
                        Text("report.forward.hint")
                        Toggle("report.forward-\(viewModel.accountHost)", isOn: $viewModel.elements.forward)
                    }
                }
            }
            Section {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Button("report.target-\(viewModel.accountName)") {
                        viewModel.report()
                    }
                }
            }
        }
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.events) {
            switch $0 {
            case .reported:
                dismiss()
            }
        }
        .navigationTitle("report.target-\(viewModel.accountName)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") {
                    dismiss()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ReportView {
    static let statusHeight: CGFloat = 100

    func dismiss() {
        if let dismissHostingController = dismissHostingController {
            dismissHostingController()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

final class ReportViewController: UIHostingController<ReportView> {
    init(viewModel: ReportViewModel) {
        super.init(rootView: ReportView(viewModel: viewModel))

        rootView.dismissHostingController = { [weak self] in self?.dismiss(animated: true) }
    }

    @available(*, unavailable)
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG
import PreviewViewModels

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportView(viewModel: .preview)
        }
    }
}
#endif
