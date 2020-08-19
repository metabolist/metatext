// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct LazyView<V: View>: View {
    typealias RenderClosure = () -> V

    let render: RenderClosure

    init(_ render: @autoclosure @escaping RenderClosure) {
        self.render = render
    }

    var body: V {
        render()
    }
}
