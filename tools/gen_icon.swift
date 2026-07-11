import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let inset: CGFloat = size * 0.09
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.2237, yRadius: rect.width * 0.2237)
path.addClip()

let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.98, green: 0.45, blue: 0.15, alpha: 1),
    ending: NSColor(calibratedRed: 0.88, green: 0.18, blue: 0.30, alpha: 1)
)
gradient?.draw(in: rect, angle: -60)

let config = NSImage.SymbolConfiguration(pointSize: 430, weight: .semibold)
if let symbol = NSImage(systemSymbolName: "checklist", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    symbol.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
    tinted.unlockFocus()

    let target = NSRect(
        x: (size - symbol.size.width) / 2,
        y: (size - symbol.size.height) / 2,
        width: symbol.size.width,
        height: symbol.size.height
    )
    tinted.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1)
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fatalError("PNG generation failed")
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try png.write(to: URL(fileURLWithPath: output))
print("written: " + output)
