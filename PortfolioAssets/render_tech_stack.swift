import AppKit

let canvasWidth = 1920
let canvasHeight = 1080
let outputURL = URL(fileURLWithPath: "/Users/antcolony/Documents/Personal/NexaDemo/iOS/NexaDemo/PortfolioAssets/nexademo-tech-stack.png")

let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.98, alpha: 1)
]

let sectionBodyAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.60, green: 0.67, blue: 0.79, alpha: 1)
]

let pillAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.94, green: 0.96, blue: 1.0, alpha: 1)
]

let tinyAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.17, alpha: 1)
]

let footerAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.72, green: 0.77, blue: 0.86, alpha: 1)
]

func drawText(_ text: String, at point: NSPoint, attributes: [NSAttributedString.Key: Any]) {
    NSString(string: text).draw(at: point, withAttributes: attributes)
}

func drawRoundedRect(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawGradient(in rect: NSRect, colors: [NSColor], angle: CGFloat) {
    let gradient = NSGradient(colors: colors)!
    gradient.draw(in: rect, angle: angle)
}

func drawPill(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat) {
    let rect = NSRect(x: x, y: y, width: width, height: 48)
    drawRoundedRect(
        rect,
        radius: 24,
        fill: NSColor(calibratedRed: 0.13, green: 0.20, blue: 0.31, alpha: 1)
    )
    let textSize = NSString(string: text).size(withAttributes: pillAttributes)
    let textX = x + ((width - textSize.width) / 2)
    let textY = y + ((48 - textSize.height) / 2) - 1
    drawText(text, at: NSPoint(x: textX, y: textY), attributes: pillAttributes)
}

func drawSection(
    originX: CGFloat,
    originY: CGFloat,
    width: CGFloat,
    height: CGFloat,
    title: String,
    subtitle: String,
    pills: [(String, CGFloat)]
) {
    let panelRect = NSRect(x: originX, y: originY, width: width, height: height)
    drawRoundedRect(
        panelRect,
        radius: 34,
        fill: NSColor(calibratedRed: 0.09, green: 0.14, blue: 0.23, alpha: 0.96),
        stroke: NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.30, alpha: 1)
    )
    drawText(title, at: NSPoint(x: originX + 34, y: originY + height - 60), attributes: sectionTitleAttributes)
    drawText(subtitle, at: NSPoint(x: originX + 34, y: originY + height - 92), attributes: sectionBodyAttributes)

    var currentX = originX + 34
    var currentY = originY + height - 150
    for (text, pillWidth) in pills {
        if currentX + pillWidth > originX + width - 34 {
            currentX = originX + 34
            currentY -= 64
        }
        drawPill(text, x: currentX, y: currentY, width: pillWidth)
        currentX += pillWidth + 14
    }
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvasWidth,
    pixelsHigh: canvasHeight,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Failed to create bitmap")
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Failed to create graphics context")
}
NSGraphicsContext.current = context

let fullRect = NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
drawGradient(
    in: fullRect,
    colors: [
        NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 1),
        NSColor(calibratedRed: 0.06, green: 0.11, blue: 0.19, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.16, alpha: 1)
    ],
    angle: 315
)

for glow in [
    (x: 250.0, y: 950.0, size: 260.0, color: NSColor(calibratedRed: 1.0, green: 0.54, blue: 0.35, alpha: 0.12)),
    (x: 1640.0, y: 930.0, size: 290.0, color: NSColor(calibratedRed: 0.21, green: 0.82, blue: 0.73, alpha: 0.10)),
    (x: 1470.0, y: 160.0, size: 340.0, color: NSColor(calibratedRed: 0.49, green: 0.36, blue: 1.0, alpha: 0.07))
] {
    let path = NSBezierPath(ovalIn: NSRect(x: glow.x, y: glow.y, width: glow.size, height: glow.size))
    glow.color.setFill()
    path.fill()
}

let badgeRect = NSRect(x: 104, y: 930, width: 260, height: 64)
let badgeGradient = NSGradient(colors: [
    NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.35, alpha: 1),
    NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.30, alpha: 1),
    NSColor(calibratedRed: 0.21, green: 0.82, blue: 0.73, alpha: 1)
])!
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 32, yRadius: 32)
badgeGradient.draw(in: badgePath, angle: 0)
drawText("iOS 26 ONLY", at: NSPoint(x: 136, y: 951), attributes: [
    .font: NSFont.systemFont(ofSize: 26, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.17, alpha: 1)
])

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 74, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.97, alpha: 1)
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.72, green: 0.77, blue: 0.86, alpha: 1)
]
drawText("NexaDemo Tech Stack", at: NSPoint(x: 104, y: 814), attributes: titleAttributes)
drawText(
    "AI, productivity, voice, payments, widgets, and system-level focus tooling",
    at: NSPoint(x: 104, y: 760),
    attributes: subtitleAttributes
)

let infoCard = NSRect(x: 1528, y: 832, width: 290, height: 130)
drawRoundedRect(
    infoCard,
    radius: 34,
    fill: NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 0.78),
    stroke: NSColor(calibratedRed: 0.14, green: 0.19, blue: 0.29, alpha: 1)
)
let miniBadge = NSRect(x: 1556, y: 900, width: 94, height: 34)
let miniBadgePath = NSBezierPath(roundedRect: miniBadge, xRadius: 17, yRadius: 17)
badgeGradient.draw(in: miniBadgePath, angle: 0)
drawText("STACK", at: NSPoint(x: 1578, y: 909), attributes: tinyAttributes)
drawText("Built for iPhone", at: NSPoint(x: 1556, y: 860), attributes: sectionTitleAttributes)
drawText("SwiftUI app + extensions", at: NSPoint(x: 1556, y: 834), attributes: sectionBodyAttributes)

drawSection(
    originX: 92,
    originY: 464,
    width: 550,
    height: 300,
    title: "Core App",
    subtitle: "Language, UI architecture, state, and navigation",
    pills: [
        ("Swift", 114), ("SwiftUI", 146), ("Concurrency", 194),
        ("Observation", 168), ("NavigationStack", 170), ("Tab API", 116),
        ("MVVM", 124), ("Service Layer", 180), ("UIKit Bridge", 150)
    ]
)

drawSection(
    originX: 684,
    originY: 464,
    width: 550,
    height: 300,
    title: "Data & Security",
    subtitle: "Persistence, identity, secure storage, and account flows",
    pills: [
        ("SwiftData", 154), ("Keychain", 148), ("App Groups", 152),
        ("UserDefaults", 168), ("Sign in with Apple", 238),
        ("Biometric Auth", 242), ("AuthenticationServices", 226)
    ]
)

drawSection(
    originX: 1276,
    originY: 464,
    width: 550,
    height: 300,
    title: "AI, Audio & Media",
    subtitle: "Camera intelligence, speech capture, and content upload",
    pills: [
        ("Core ML", 152), ("Vision", 124), ("MobileNetV2", 178),
        ("Speech Recognition", 228), ("AVFoundation", 168), ("PhotosUI", 132),
        ("ImageKit", 144), ("Voice Command Parsing", 324)
    ]
)

drawSection(
    originX: 92,
    originY: 144,
    width: 866,
    height: 280,
    title: "System Frameworks",
    subtitle: "Deep iOS integrations for widgets, Live Activities, alarms, and focus controls",
    pills: [
        ("WidgetKit", 152), ("ActivityKit", 156), ("AlarmKit", 138),
        ("AppIntents", 150), ("Notifications", 146),
        ("FamilyControls", 182), ("DeviceActivity", 174),
        ("ManagedSettings", 196), ("Dynamic Island", 204)
    ]
)

drawSection(
    originX: 1000,
    originY: 144,
    width: 826,
    height: 280,
    title: "Backend & SDK Integrations",
    subtitle: "Client APIs, Node.js backend, database, monetization, and realtime services",
    pills: [
        ("URLSession", 150), ("Custom REST API", 200), ("Node.js", 118), ("Supabase", 146),
        ("Railway", 120), ("Agora RTC", 142), ("RevenueCat", 168), ("Stripe", 120), ("ImageKitIO", 144)
    ]
)

let linePath = NSBezierPath()
linePath.move(to: NSPoint(x: 104, y: 96))
linePath.line(to: NSPoint(x: 1816, y: 96))
NSColor(calibratedRed: 0.85, green: 0.62, blue: 0.32, alpha: 0.55).setStroke()
linePath.lineWidth = 1
linePath.stroke()

drawText(
    "Designed from the app codebase and updated with backend stack details: Node.js, Supabase, and Railway.",
    at: NSPoint(x: 104, y: 46),
    attributes: footerAttributes
)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

try pngData.write(to: outputURL)
print("Rendered \(outputURL.path)")
