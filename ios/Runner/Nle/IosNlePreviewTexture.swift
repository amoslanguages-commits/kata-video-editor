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
        drawPlaceholder(label: "iOS Native Preview", playheadMicros: 0)
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

    func drawPlaceholder(
        label: String,
        playheadMicros: Int64
    ) {
        lock.lock()
        defer { lock.unlock() }

        guard let pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            return
        }

        context.setFillColor(UIColor(red: 0.03, green: 0.04, blue: 0.08, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.setStrokeColor(UIColor.cyan.withAlphaComponent(0.75).cgColor)
        context.setLineWidth(3)
        context.stroke(CGRect(x: 10, y: 10, width: width - 20, height: height - 20))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: max(24, CGFloat(width) * 0.035)),
            .paragraphStyle: paragraph
        ]

        let smallAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.78),
            .font: UIFont.systemFont(ofSize: max(14, CGFloat(width) * 0.018)),
            .paragraphStyle: paragraph
        ]

        let titleRect = CGRect(
            x: 0,
            y: CGFloat(height) * 0.42,
            width: CGFloat(width),
            height: 60
        )

        NSString(string: label).draw(
            in: titleRect,
            withAttributes: titleAttributes
        )

        let subtitle = "Texture ID: \(textureId) • \(width)x\(height)"
        NSString(string: subtitle).draw(
            in: CGRect(
                x: 0,
                y: CGFloat(height) * 0.50,
                width: CGFloat(width),
                height: 34
            ),
            withAttributes: smallAttributes
        )

        let playhead = "Playhead: \(playheadMicros / 1000) ms"
        NSString(string: playhead).draw(
            in: CGRect(
                x: 0,
                y: CGFloat(height) * 0.55,
                width: CGFloat(width),
                height: 34
            ),
            withAttributes: smallAttributes
        )

        let footer = "iOS native engine path ready. Metal compositor comes later."
        NSString(string: footer).draw(
            in: CGRect(
                x: 0,
                y: CGFloat(height) - 46,
                width: CGFloat(width),
                height: 34
            ),
            withAttributes: smallAttributes
        )

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
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
