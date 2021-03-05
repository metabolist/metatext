// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class ReportViewController: TableViewController {
    private let reportButton = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    private let viewModel: ReportViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ReportViewModel) {
        self.viewModel = viewModel

        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = String.localizedStringWithFormat(
            NSLocalizedString("report.target-%@", comment: ""),
            viewModel.accountName)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.presentingViewController?.dismiss(animated: true) })
        navigationItem.rightBarButtonItem = reportButton
        reportButton.primaryAction = UIAction(title: NSLocalizedString("report", comment: "")) { [weak self] _ in
            self?.viewModel.report()
        }

        tableView.tableHeaderView = ReportHeaderView(viewModel: viewModel)

        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true

        viewModel.$reportingState
            .sink { [weak self] in self?.apply(reportingState: $0) }
            .store(in: &cancellables)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

        guard let statusView = cell.contentView as? StatusView else { return }

        statusView.alpha = 0.75
        statusView.buttonsStackView.isHidden = true
        statusView.reportSelectionSwitch.isHidden = false

        for subview in statusView.subviews {
            subview.isUserInteractionEnabled = false
        }
    }

    override func configureRightBarButtonItem(expandAllState: ExpandAllState) {
        // no-op
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let statusViewModel = viewModel.viewModel(indexPath: indexPath) as? StatusViewModel else { return }

        if viewModel.elements.statusIds.contains(statusViewModel.id) {
            viewModel.elements.statusIds.remove(statusViewModel.id)
        } else {
            viewModel.elements.statusIds.insert(statusViewModel.id)
        }

        let selectedForReport = viewModel.elements.statusIds.contains(statusViewModel.id)

        statusViewModel.selectedForReport = selectedForReport

        guard let statusView = tableView.cellForRow(at: indexPath)?.contentView as? StatusView else { return }

        statusView.reportSelectionSwitch.setOn(selectedForReport, animated: true)
        statusView.refreshAccessibilityLabel()
    }
}

private extension ReportViewController {
    func apply(reportingState: ReportViewModel.ReportingState) {
        switch reportingState {
        case .composing:
            activityIndicatorView.stopAnimating()
            view.isUserInteractionEnabled = true
            reportButton.isEnabled = true
            view.alpha = 1
        case .reporting:
            activityIndicatorView.startAnimating()
            view.isUserInteractionEnabled = false
            reportButton.isEnabled = false
            view.alpha = 0.5
        case .done:
            presentingViewController?.dismiss(animated: true)
        }
    }
}
