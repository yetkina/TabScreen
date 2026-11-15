import AppKit

// Draws the app icon (monitor + tablet) at 1024px and writes it as PNG to argv[1].
let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Background squircle
let bg = NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 210, yRadius: 210)
bg.addClip()
NSGradient(colors: [NSColor(red: 0.36, green: 0.30, blue: 0.95, alpha: 1), NSColor(red: 0.10, green: 0.60, blue: 0.95, alpha: 1)])!
    .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -50)

// Monitor
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 150, y: 400, width: 560, height: 380), xRadius: 40, yRadius: 40).fill()
NSColor(red: 0.12, green: 0.14, blue: 0.35, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 182, y: 432, width: 496, height: 316), xRadius: 20, yRadius: 20).fill()
NSColor.white.setFill()
NSBezierPath(rect: NSRect(x: 400, y: 330, width: 60, height: 72)).fill()
NSBezierPath(roundedRect: NSRect(x: 320, y: 300, width: 220, height: 40), xRadius: 20, yRadius: 20).fill()

// Tablet (overlapping, bottom right)
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: NSColor.black.withAlphaComponent(0.35).cgColor)
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 560, y: 190, width: 330, height: 240), xRadius: 40, yRadius: 40).fill()
ctx.setShadow(offset: .zero, blur: 0, color: nil)
NSGradient(colors: [NSColor(red: 1.0, green: 0.55, blue: 0.30, alpha: 1), NSColor(red: 0.98, green: 0.25, blue: 0.55, alpha: 1)])!
    .draw(in: NSBezierPath(roundedRect: NSRect(x: 586, y: 216, width: 278, height: 188), xRadius: 22, yRadius: 22), angle: -40)

img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
