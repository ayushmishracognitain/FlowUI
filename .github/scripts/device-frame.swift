#!/usr/bin/env swift
//
//  device-frame.swift
//
//  Drops a simulator screenshot into the iPhone frame used by the docs site, so
//  README mockups and site mockups are the same object rather than two things
//  that happen to look similar.
//
//  Usage:
//    swift .github/scripts/device-frame.swift <screenshot.png> <frame.png> <out.png> [scale]
//
//  The geometry is not guessed. It is the same set of constants the docs site
//  renders with, in DeviceFrames.tsx over in the flow-ui-doc-website repo:
//
//    SCREEN_INSET          left/right 6.67%, top/bottom 3.3% of the frame
//    SCREEN_RADIUS         6.8% of screen height
//    frame                 480 x 969
//
//  which lands the glass at exactly 416 x 905 offset (32, 32). A 1206 x 2622
//  iPhone 16 Pro capture is aspect 0.4600 against the panel's 0.4597, so it drops
//  in with no visible distortion.
//
//  Insets are vertically symmetric, so the screen rect is (32, 32, 416, 905) in
//  both top left and bottom left coordinate spaces. No flip needed.

import AppKit
import CoreGraphics

let frameSize = CGSize(width: 480, height: 969)
let insetX = 0.0667
let insetY = 0.033
let radiusOfHeight = 0.068

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("device-frame: \(message)\n".utf8))
    exit(1)
}

func loadCGImage(_ path: String) -> CGImage {
    guard let image = NSImage(contentsOfFile: path),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fail("could not read image at \(path)")
    }
    return cgImage
}

let args = CommandLine.arguments
guard args.count >= 4 else {
    fail("usage: device-frame.swift <screenshot.png> <frame.png> <out.png> [scale]")
}
let screenshot = loadCGImage(args[1])
let chrome = loadCGImage(args[2])
let outputPath = args[3]
let scale = args.count > 4 ? (Double(args[4]) ?? 2) : 2

let screen = CGRect(
    x: frameSize.width * insetX,
    y: frameSize.height * insetY,
    width: frameSize.width * (1 - insetX * 2),
    height: frameSize.height * (1 - insetY * 2)
)
let radius = screen.height * radiusOfHeight

let pixelWidth = Int(frameSize.width * scale)
let pixelHeight = Int(frameSize.height * scale)

guard let context = CGContext(
    data: nil,
    width: pixelWidth,
    height: pixelHeight,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fail("could not create the drawing context")
}

context.scaleBy(x: scale, y: scale)
context.interpolationQuality = .high

// The capture fills the glass. Aspect ratios agree to three decimals, so this is
// a fit rather than a stretch, but centre it anyway in case a future device does
// not line up as neatly.
let captureAspect = Double(screenshot.width) / Double(screenshot.height)
let screenAspect = screen.width / screen.height
var drawRect = screen
if captureAspect > screenAspect {
    drawRect.size.width = screen.height * captureAspect
    drawRect.origin.x = screen.midX - drawRect.width / 2
} else {
    drawRect.size.height = screen.width / captureAspect
    drawRect.origin.y = screen.midY - drawRect.height / 2
}

context.saveGState()
let glass = CGPath(roundedRect: screen, cornerWidth: radius, cornerHeight: radius, transform: nil)
context.addPath(glass)
context.clip()
context.draw(screenshot, in: drawRect)
context.restoreGState()

// Chrome last, over the whole canvas, exactly as the site layers it.
context.draw(chrome, in: CGRect(origin: .zero, size: frameSize))

guard let output = context.makeImage() else { fail("could not render the composite") }
let rep = NSBitmapImageRep(cgImage: output)
rep.size = frameSize
guard let png = rep.representation(using: .png, properties: [:]) else {
    fail("could not encode PNG")
}
do {
    try png.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fail("could not write \(outputPath): \(error.localizedDescription)")
}

print("\(outputPath)  \(pixelWidth)x\(pixelHeight)  @\(Int(scale))x")
