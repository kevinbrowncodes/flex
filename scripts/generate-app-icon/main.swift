// Renders FlexAppIcon.swift to a 1024×1024 PNG (no alpha) on macOS.
// Usage: swiftc Flex/Flex/Support/FlexAppIcon.swift scripts/generate-app-icon/main.swift -o /tmp/gen-icon && /tmp/gen-icon out.png
import AppKit
import SwiftUI

@MainActor
func render(to path: String) throws {
    let renderer = ImageRenderer(content: FlexLiquidGlassIcon())
    renderer.scale = 1
    guard let cgImage = renderer.cgImage else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Render failed"])
    }

    // Flatten onto black and drop the alpha channel; the system masks the corners itself.
    let size = 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "No context"])
    }
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

    guard let flattened = context.makeImage() else {
        throw NSError(domain: "GenerateAppIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "No image"])
    }
    let rep = NSBitmapImageRep(cgImage: flattened)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateAppIcon", code: 4, userInfo: [NSLocalizedDescriptionKey: "No PNG"])
    }
    try png.write(to: URL(fileURLWithPath: path))
}

let output = CommandLine.arguments.dropFirst().first ?? "icon-1024.png"
do {
    try MainActor.assumeIsolated { try render(to: output) }
    print("wrote \(output)")
} catch {
    FileHandle.standardError.write("error: \(error.localizedDescription)\n".data(using: .utf8)!)
    exit(1)
}
