// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct MuteView: View {
    @StateObject var viewModel: MuteViewModel

    @Environment(\.presentationMode) private var presentationMode
    fileprivate var dismissHostingController: (() -> Void)?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: .defaultSpacing) {
                    Text("account.mute.confirm-\(viewModel.accountName)")
                    Text("account.mute.confirm.explanation")
                }
                Toggle("account.mute.confirm.hide-notifications", isOn: $viewModel.notifications)
                Picker("account.mute.confirm.duration", selection: $viewModel.duration) {
                    ForEach(MuteViewModel.Duration.allCases) { duration in
                        Text(verbatim: duration.title).tag(duration)
                    }
                }
            }
            Section {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Button("account.mute.target-\(viewModel.accountName)") {
                        viewModel.mute()
                    }
                }
            }
        }
        .alertItem($viewModel.alertItem)
        .onReceive(viewModel.events) {
            switch $0 {
            case .muted:
                dismiss()
            }
        }
        .navigationTitle("account.mute.target-\(viewModel.accountName)")
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

private extension MuteView {
    func dismiss() {
        if let dismissHostingController = dismissHostingController {
            dismissHostingController()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

final class MuteViewController: UIHostingController<MuteView> {
    init(viewModel: MuteViewModel) {
        super.init(rootView: MuteView(viewModel: viewModel))

        rootView.dismissHostingController = { [weak self] in self?.dismiss(animated: true) }
    }

    @available(*, unavailable)
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MuteViewModel.Duration {
    static let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .full

        return formatter
    }()

    var title: String {
        switch self {
        case .indefinite:
            return NSLocalizedString("account.mute.indefinite", comment: "")
        default:
            return Self.dateComponentsFormatter.string(from: TimeInterval(rawValue)) ?? String(rawValue)
        }
    }
}

#if DEBUG
import PreviewViewModels

struct MuteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MuteView(viewModel: .preview)
        }
    }
}
#endif
