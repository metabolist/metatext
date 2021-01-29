// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct ReportStatusView: UIViewRepresentable {
    private let configuration: StatusContentConfiguration

    init(viewModel: StatusViewModel) {
        configuration = StatusContentConfiguration(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> StatusView {
        let view = StatusView(configuration: configuration)

        view.alpha = 0.5
        view.buttonsStackView.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false

        return view
    }

    func updateUIView(_ uiView: StatusView, context: Context) {

    }
}
