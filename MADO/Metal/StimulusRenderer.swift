import MetalKit
import QuartzCore
import UIKit

// MARK: - Stimulus Types

enum StimulusType: Int, CaseIterable, Sendable {
    case car = 0
    case truck = 1

    var label: String {
        switch self {
        case .car: String(localized: "stimulus_car")
        case .truck: String(localized: "stimulus_truck")
        }
    }
}

enum SessionPhase: Sendable {
    case fixation
    case stimulus
    case mask
    case response
    case feedback
    case interTrial
}

// MARK: - Noise Parameters

struct NoiseParams {
    var seed: UInt32
    var blockSize: UInt32
    var opacity: Float
}

struct StimulusParams {
    var center: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
    var shapeType: Int32
    var opacity: Float
    var _padding: SIMD2<Float> = .zero
}

// MARK: - Renderer

final class StimulusRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let noisePipeline: MTLComputePipelineState
    private let stimulusPipeline: MTLRenderPipelineState

    // State
    var phase: SessionPhase = .fixation
    var centralStimulus: StimulusType = .car
    var stimulusDurationFrames: Int = 20
    var currentFrame: Int = 0
    var feedbackCorrect: Bool = false
    var noiseSeed: UInt32 = 0

    // Pre-allocated noise texture to avoid per-frame allocation
    private var noiseTexture: MTLTexture?
    private var noiseTextureSize: CGSize = .zero

    // Callbacks
    var onMaskComplete: (() -> Void)?

    private let fixationDurationFrames = 30  // ~500ms at 60fps
    private let maskDurationFrames = 18      // ~300ms at 60fps
    private let feedbackDurationFrames = 36  // ~600ms at 60fps

    init?(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let noiseFunc = library.makeFunction(name: "noiseKernel") else { return nil }

        self.device = device
        self.commandQueue = commandQueue
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.024, green: 0.031, blue: 0.055, alpha: 1.0)

        // Noise compute pipeline
        do {
            self.noisePipeline = try device.makeComputePipelineState(function: noiseFunc)
        } catch {
            print("Failed to create noise pipeline: \(error)")
            return nil
        }

        // Stimulus render pipeline
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = library.makeFunction(name: "stimulusVertex")
        pipelineDesc.fragmentFunction = library.makeFunction(name: "stimulusFragment")
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        do {
            self.stimulusPipeline = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Failed to create stimulus pipeline: \(error)")
            return nil
        }

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Recreate noise texture when size changes
        ensureNoiseTexture(width: Int(size.width), height: Int(size.height))
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        currentFrame += 1

        switch phase {
        case .fixation:
            drawFixation(descriptor: descriptor, commandBuffer: commandBuffer)
            if currentFrame >= fixationDurationFrames {
                currentFrame = 0
                phase = .stimulus
            }

        case .stimulus:
            drawStimulus(descriptor: descriptor, commandBuffer: commandBuffer)
            if currentFrame >= stimulusDurationFrames {
                currentFrame = 0
                phase = .mask
                noiseSeed = UInt32.random(in: 0..<UInt32.max)
            }

        case .mask:
            drawNoiseMask(view: view, commandBuffer: commandBuffer, descriptor: descriptor)
            if currentFrame >= maskDurationFrames {
                currentFrame = 0
                phase = .response
                onMaskComplete?()
            }

        case .response:
            drawFixation(descriptor: descriptor, commandBuffer: commandBuffer)

        case .feedback:
            drawFeedback(descriptor: descriptor, commandBuffer: commandBuffer)
            if currentFrame >= feedbackDurationFrames {
                currentFrame = 0
                phase = .fixation
            }

        case .interTrial:
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Noise Texture Management

    private func ensureNoiseTexture(width: Int, height: Int) {
        let newSize = CGSize(width: width, height: height)
        guard noiseTextureSize != newSize, width > 0, height > 0 else { return }
        noiseTextureSize = newSize

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        desc.usage = [.shaderWrite, .shaderRead]
        desc.storageMode = .private
        noiseTexture = device.makeTexture(descriptor: desc)
    }

    // MARK: - Drawing

    private func drawFixation(descriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        var params = StimulusParams(
            center: SIMD2<Float>(0.5, 0.5),
            size: SIMD2<Float>(0.02, 0.002),
            color: SIMD4<Float>(0.298, 0.651, 0.910, 1.0),
            shapeType: 0,
            opacity: 0.6
        )

        encoder.setRenderPipelineState(stimulusPipeline)
        encoder.setVertexBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.setFragmentBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Vertical bar
        params.size = SIMD2<Float>(0.002, 0.02)
        encoder.setVertexBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.setFragmentBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.endEncoding()
    }

    private func drawStimulus(descriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        var params = StimulusParams(
            center: SIMD2<Float>(0.5, 0.5),
            size: SIMD2<Float>(0.06, 0.08),
            color: SIMD4<Float>(0.9, 0.9, 0.9, 1.0),
            shapeType: Int32(centralStimulus.rawValue),
            opacity: 1.0
        )

        encoder.setRenderPipelineState(stimulusPipeline)
        encoder.setVertexBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.setFragmentBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.endEncoding()
    }

    private func drawNoiseMask(view: MTKView, commandBuffer: MTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        let w = Int(view.drawableSize.width)
        let h = Int(view.drawableSize.height)

        ensureNoiseTexture(width: w, height: h)
        guard let noiseTexture else { return }

        // Compute noise
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.setComputePipelineState(noisePipeline)
            computeEncoder.setTexture(noiseTexture, index: 0)

            noiseSeed &+= UInt32(currentFrame)
            var noiseParams = NoiseParams(seed: noiseSeed, blockSize: 4, opacity: 0.8)
            computeEncoder.setBytes(&noiseParams, length: MemoryLayout<NoiseParams>.size, index: 0)

            let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
            let threadGroups = MTLSize(
                width: (w + 15) / 16,
                height: (h + 15) / 16,
                depth: 1
            )
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
            computeEncoder.endEncoding()
        }

        // Blit noise to drawable
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.endEncoding()

        if let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
           let drawable = view.currentDrawable {
            blitEncoder.copy(from: noiseTexture,
                            sourceSlice: 0, sourceLevel: 0,
                            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                            sourceSize: MTLSize(width: w, height: h, depth: 1),
                            to: drawable.texture,
                            destinationSlice: 0, destinationLevel: 0,
                            destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
        }
    }

    private func drawFeedback(descriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        let color: SIMD4<Float> = feedbackCorrect
            ? SIMD4<Float>(0.204, 0.780, 0.349, 1.0)
            : SIMD4<Float>(1.0, 0.271, 0.227, 1.0)

        var params = StimulusParams(
            center: SIMD2<Float>(0.5, 0.5),
            size: SIMD2<Float>(0.04, 0.04),
            color: color,
            shapeType: 0,
            opacity: 0.9
        )

        encoder.setRenderPipelineState(stimulusPipeline)
        encoder.setVertexBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.setFragmentBytes(&params, length: MemoryLayout<StimulusParams>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    // MARK: - Control

    func startTrial(stimulus: StimulusType, durationFrames: Int) {
        centralStimulus = stimulus
        stimulusDurationFrames = durationFrames
        currentFrame = 0
        phase = .fixation
    }

    func showResponseFeedback(correct: Bool) {
        feedbackCorrect = correct
        currentFrame = 0
        phase = .feedback
    }
}
