// Renders one app-preview caption (a white line, then the key words in the screenshot accent) on
// a translucent rounded box, as a PNG that scripts/preview.sh lays over the recording with
// ffmpeg's `overlay` filter (STORY_014). ffmpeg's own `drawtext` is not in every build; AppKit and
// the system font are on every Mac.
//
//   swift scripts/preview-overlay.swift "Log sets" "from your wrist" out.png
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write(Data("usage: preview-overlay.swift <top line> <bottom line> <out.png>\n".utf8))
    exit(2)
}
let top = arguments[1]
let bottom = arguments[2]
let output = URL(fileURLWithPath: arguments[3])

let width = 820   // of the 886-wide preview, centered by the caller
let height = 230
let accent = NSColor(red: 0x5A / 255.0, green: 0xA9 / 255.0, blue: 0xFF / 255.0, alpha: 1)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("could not make a bitmap\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let box = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: width, height: height), xRadius: 28, yRadius: 28)
NSColor.black.withAlphaComponent(0.55).setFill()
box.fill()

func draw(_ text: String, size: CGFloat, color: NSColor, baseline: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let string = NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: .bold),
        .foregroundColor: color,
        .paragraphStyle: style,
    ])
    let lineHeight = string.size().height
    string.draw(in: NSRect(x: 20, y: baseline, width: CGFloat(width - 40), height: lineHeight))
}

draw(top, size: 50, color: .white, baseline: 128)
draw(bottom, size: 58, color: accent, baseline: 38)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("could not encode the PNG\n".utf8))
    exit(1)
}
do {
    try png.write(to: output)
} catch {
    FileHandle.standardError.write(Data("could not write \(output.path): \(error)\n".utf8))
    exit(1)
}
