// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

final public class EmojiPickerViewModel: ObservableObject {
    private let identification: Identification

    public init(identification: Identification) {
        self.identification = identification
    }
}
