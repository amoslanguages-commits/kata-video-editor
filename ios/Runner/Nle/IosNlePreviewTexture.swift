import Foundation
import Flutter
import CoreVideo
import CoreGraphics
import UIKit

final class IosNlePreviewTexture: NSObject, FlutterTexture {
    let width: Int
    let height: Int

    private var pixelBuffer: CVPixelBuffer?
    private let lock = NSLock()

    private(set) var projectId: String?
    private(set) var sessionId: String?
    private(set) var textureId: Int64 = -1

    init(width: Int, height: Int) {
        self.width = max(width, 16)
        self.height = max(height, 16)
        super.init()
        createPixelBuffer()
    }

    func setTextureId(_ id: Int64) {
        textureId = id
    }

    func attach(projectId: String, sessionId: String?) {
        self.projectId = projectId
        self.sessionId = sessionId
    }

    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        lock.lock()
        defer { lock.unlock() }

        guard let pixelBuffer else {
            return nil
        }

        return Unmanaged.passRetained(pixelBuffer)
    }

    func render(image: CGImage) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let pixelBuffer else {
            throw NSError(
                domain: "IosNlePreviewTexture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Preview pixel buffer is missing."]
            )
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            throw NSError(
                domain: "IosNlePreviewTexture",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not create preview CGContext."]
            )
        }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let sourceWidth = CGFloat(image.width)
        let sourceHeight = CGFloat(image.height)
        let scale = min(CGFloat(width) / sourceWidth, CGFloat(height) / sourceHeight)
        let drawWidth = sourceWidth * scale
        let drawHeight = sourceHeight * scale
        let drawRect = CGRect(
            x: (CGFloat(width) - drawWidth) / 2.0,
            y: (CGFloat(height) - drawHeight) / 2.0,
            width: drawWidth,
            height: drawHeight
        )

        context.interpolationQuality = .high
        context.draw(image, in: drawRect)
    }

    func toMap() -> [String: Any?] {
        return [
            "textureId": textureId,
            "width": width,
            "height": height,
            "projectId": projectId,
            "sessionId": sessionId,
            "platform": "ios"
        ]
    }

    private func createPixelBuffer() {
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
    }
}
