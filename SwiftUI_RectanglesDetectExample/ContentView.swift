//
//  ContentView.swift
//  SwiftUI_RectanglesDetectExample
//
//  Created by cano on 2023/12/31.
//

import SwiftUI

struct ContentView: View {
    let manager = DetectManager()
    
    var body: some View {
        ZStack {
            if let image = manager.previewImage {
            Image(uiImage: image)
                    .resizable()
            }
            
            ControlView(
                startHandler: { manager.startCaptureSession() },
                stopHandler: { manager.stopCaptureSession() }
            )
        }.edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
