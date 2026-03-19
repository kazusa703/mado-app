import SwiftUI
import MetalKit

struct SessionMetalView: UIViewRepresentable {
    let renderer: StimulusRenderer

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.024, green: 0.031, blue: 0.055, alpha: 1.0)
        mtkView.preferredFramesPerSecond = 120
        mtkView.delegate = renderer
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
