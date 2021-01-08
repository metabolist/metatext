// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol AttachmentsRenderingViewModel {
    var attachmentViewModels: [AttachmentViewModel] { get }
    var shouldShowAttachments: Bool { get }
    var shouldShowHideAttachmentsButton: Bool { get }
    var sensitive: Bool { get }
    var canRemoveAttachments: Bool { get }
    func attachmentSelected(viewModel: AttachmentViewModel)
    func removeAttachment(viewModel: AttachmentViewModel)
    func toggleShowAttachments()
}

public extension AttachmentsRenderingViewModel {
    var shouldShowAttachments: Bool { true  }
    var shouldShowHideAttachmentsButton: Bool { false }
    var sensitive: Bool { false }
    var canRemoveAttachments: Bool { false }
    func removeAttachment(viewModel: AttachmentViewModel) {}
    func toggleShowAttachments() {}
}
