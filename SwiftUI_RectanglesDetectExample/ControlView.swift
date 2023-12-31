//
//  ControlView.swift
//  SwiftUI_RectanglesDetectExample
//
//  Created by cano on 2023/12/31.
//

import SwiftUI

struct ControlView: View {
    var startHandler: (() -> Void)
    var stopHandler: (() -> Void)
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 42) {
                Button("Start") { startHandler() }
                Button("Stop")  { stopHandler() }
            }.padding(24)
        }
    }
}

#Preview {
    ControlView(startHandler: {}, stopHandler: {})
}
