import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)
let outer = NSBezierPath(roundedRect: bounds.insetBy(dx: 42, dy: 42), xRadius: 210, yRadius: 210)
NSColor(calibratedWhite: 0.025, alpha: 1).setFill()
outer.fill()

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.65)
shadow.shadowBlurRadius = 38
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()

func card(_ rect: NSRect, angle: CGFloat, color: NSColor) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: rect.midX, yBy: rect.midY)
    transform.rotate(byDegrees: angle)
    transform.translateX(by: -rect.midX, yBy: -rect.midY)
    transform.concat()
    let path = NSBezierPath(roundedRect: rect, xRadius: 42, yRadius: 42)
    color.setFill()
    path.fill()
    NSColor(calibratedWhite: 0.95, alpha: 0.18).setStroke()
    path.lineWidth = 8
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
}

card(NSRect(x: 188, y: 282, width: 644, height: 474), angle: -8, color: NSColor(calibratedRed: 0.035, green: 0.22, blue: 0.13, alpha: 1))
card(NSRect(x: 196, y: 300, width: 644, height: 474), angle: 7, color: NSColor(calibratedRed: 0.025, green: 0.35, blue: 0.19, alpha: 1))

let face = NSBezierPath(roundedRect: NSRect(x: 196, y: 310, width: 632, height: 470), xRadius: 42, yRadius: 42)
NSColor(calibratedRed: 0.04, green: 0.055, blue: 0.05, alpha: 1).setFill()
face.fill()
NSColor(calibratedRed: 0.1, green: 0.95, blue: 0.49, alpha: 1).setStroke()
face.lineWidth = 12
face.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let tax = NSAttributedString(
    string: "TAX",
    attributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 232, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.1, green: 0.95, blue: 0.49, alpha: 1),
        .paragraphStyle: paragraph
    ]
)
tax.draw(in: NSRect(x: 200, y: 425, width: 624, height: 280))

let terms = NSAttributedString(
    string: "TERMS  /  STUDY",
    attributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 38, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.25, green: 0.63, blue: 1, alpha: 1),
        .kern: 5,
        .paragraphStyle: paragraph
    ]
)
terms.draw(in: NSRect(x: 200, y: 382, width: 624, height: 72))

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render icon")
}
try png.write(to: URL(fileURLWithPath: output), options: .atomic)
