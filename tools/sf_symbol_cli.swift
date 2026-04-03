import AppKit
import CoreText
import Foundation

// MARK: - CoreUI Private API Bridge

private let coreUIBundle = Bundle(path: "/System/Library/PrivateFrameworks/CoreUI.framework")!
private let carPath = "/System/Library/PrivateFrameworks/SFSymbols.framework/Versions/A/Resources/CoreGlyphs.bundle/Contents/Resources/Assets.car"

private var _catalog: AnyObject? = nil

func getCatalog() -> AnyObject? {
    if let c = _catalog { return c }
    coreUIBundle.load()
    guard let CUICatalog = NSClassFromString("CUICatalog") else { return nil }
    let catalog = (CUICatalog as! NSObject.Type).perform(NSSelectorFromString("alloc"))!.takeUnretainedValue()

    typealias InitFunc = @convention(c) (AnyObject, Selector, NSURL, AutoreleasingUnsafeMutablePointer<NSError?>?) -> AnyObject?
    let sel = NSSelectorFromString("initWithURL:error:")
    let method = class_getInstanceMethod(CUICatalog, sel)!
    let imp = method_getImplementation(method)
    let call = unsafeBitCast(imp, to: InitFunc.self)

    var error: NSError? = nil
    guard let result = call(catalog, sel, NSURL(fileURLWithPath: carPath), &error) else { return nil }
    _catalog = result
    return result
}

// glyphWeight mapping: 0=ultralight, 1=thin, 2=light, 3=regular(?), 4=regular, 5=medium, 6=semibold, 7=bold, 8=heavy, 9=black
func weightIndex(for weight: String) -> Int {
    switch weight {
    case "ultralight": return 0
    case "thin": return 1
    case "light": return 2
    case "regular": return 4
    case "medium": return 5
    case "semibold": return 6
    case "bold": return 7
    case "heavy": return 8
    case "black": return 9
    default: return 4
    }
}

func getVectorGlyph(name: String, weight: String = "regular", pointSize: CGFloat = 100) -> AnyObject? {
    guard let catalog = getCatalog() else { return nil }
    let CUICatalog: AnyClass = NSClassFromString("CUICatalog")!
    let sel = NSSelectorFromString("namedVectorGlyphWithName:scaleFactor:deviceIdiom:glyphSize:glyphWeight:glyphPointSize:appearanceName:")

    typealias GlyphFunc = @convention(c) (AnyObject, Selector, NSString, CGFloat, Int, Int, Int, CGFloat, NSString?) -> AnyObject?
    let method = class_getInstanceMethod(CUICatalog, sel)!
    let imp = method_getImplementation(method)
    let call = unsafeBitCast(imp, to: GlyphFunc.self)

    // glyphSize: 1=medium, glyphWeight: see weightIndex
    return call(catalog, sel, name as NSString, 2.0, 0, 1, weightIndex(for: weight), pointSize, nil)
}

func getCGPath(from glyph: AnyObject) -> CGPath? {
    let sel = NSSelectorFromString("CGPath")
    guard glyph.responds(to: sel), let result = glyph.perform(sel) else { return nil }
    return Unmanaged<CGPath>.fromOpaque(result.toOpaque()).takeUnretainedValue()
}

// MARK: - CGPath to SVG

func cgPathToSVGData(_ path: CGPath, flipY: Bool, flipHeight: CGFloat) -> String {
    var d = ""
    path.applyWithBlock { element in
        let p = element.pointee.points
        let h = flipHeight
        switch element.pointee.type {
        case .moveToPoint:
            let y = flipY ? h - p[0].y : p[0].y
            d += String(format: "M%.2f %.2f", p[0].x, y)
        case .addLineToPoint:
            let y = flipY ? h - p[0].y : p[0].y
            d += String(format: "L%.2f %.2f", p[0].x, y)
        case .addQuadCurveToPoint:
            let y0 = flipY ? h - p[0].y : p[0].y
            let y1 = flipY ? h - p[1].y : p[1].y
            d += String(format: "Q%.2f %.2f %.2f %.2f", p[0].x, y0, p[1].x, y1)
        case .addCurveToPoint:
            let y0 = flipY ? h - p[0].y : p[0].y
            let y1 = flipY ? h - p[1].y : p[1].y
            let y2 = flipY ? h - p[2].y : p[2].y
            d += String(format: "C%.2f %.2f %.2f %.2f %.2f %.2f", p[0].x, y0, p[1].x, y1, p[2].x, y2)
        case .closeSubpath:
            d += "Z"
        @unknown default:
            break
        }
    }
    return d
}

// MARK: - Symbol Export

func exportSymbolSVG(name: String, pointSize: CGFloat = 100, weight: String = "regular", rawCoords: Bool = false) -> String? {
    // Verify symbol exists
    guard NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil else { return nil }

    // Try vector extraction via CoreUI
    if let glyph = getVectorGlyph(name: name, weight: weight, pointSize: pointSize),
       let path = getCGPath(from: glyph) {
        let bounds = path.boundingBox
        guard !bounds.isEmpty && bounds.width > 0 else { return nil }

        // flipY=true → standard SVG (Y-down), flipY=false → raw CG coords (Y-up, for Pencil etc)
        let svgPath = cgPathToSVGData(path, flipY: !rawCoords, flipHeight: bounds.maxY)

        let vx = bounds.minX
        let vy = rawCoords ? bounds.minY : 0.0
        let w = bounds.width
        let h = bounds.height

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(ceil(w)))" height="\(Int(ceil(h)))" viewBox="\(String(format: "%.2f", vx)) \(String(format: "%.2f", vy)) \(String(format: "%.2f", w)) \(String(format: "%.2f", h))">
          <title>\(name)</title>
          <path d="\(svgPath)" fill="currentColor"/>
        </svg>
        """
    }

    return nil
}

// MARK: - Search

func searchSymbols(query: String) -> [String] {
    let searchURL = URL(fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/symbol_search.plist")
    let availURL = URL(fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist")

    guard let availData = try? Data(contentsOf: availURL),
          let availDict = try? PropertyListSerialization.propertyList(from: availData, format: nil) as? [String: Any],
          let symbols = availDict["symbols"] as? [String: String] else {
        return []
    }

    let q = query.lowercased()
    var results: Set<String> = []

    for name in symbols.keys {
        if name.lowercased().contains(q) {
            results.insert(name)
        }
    }

    if let searchData = try? Data(contentsOf: searchURL),
       let searchDict = try? PropertyListSerialization.propertyList(from: searchData, format: nil) as? [String: [String]] {
        for (name, keywords) in searchDict {
            if keywords.contains(where: { $0.lowercased().contains(q) }) {
                if symbols.keys.contains(name) {
                    results.insert(name)
                }
            }
            if name.lowercased().contains(q) && symbols.keys.contains(name) {
                results.insert(name)
            }
        }
    }

    return results.sorted()
}

// MARK: - JSON helpers

func jsonOutput(_ dict: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
       let str = String(data: data, encoding: .utf8) {
        print(str)
    }
}

// MARK: - Main

let args = Array(CommandLine.arguments.dropFirst())

guard !args.isEmpty else {
    jsonOutput([
        "usage": "sf-symbol <command> [args]",
        "commands": [
            "search <query>": "Search for SF Symbol names by name or keyword",
            "export <name> [--weight <w>] [--size <n>] [--output <path>]": "Export symbol as vector SVG",
            "info <name>": "Get info about a symbol",
            "list [--limit <n>]": "List all symbol names"
        ]
    ])
    exit(0)
}

let command = args[0]

switch command {
case "search":
    guard args.count > 1 else {
        jsonOutput(["error": "Usage: sf-symbol search <query>"])
        exit(1)
    }
    let query = args[1...].joined(separator: " ")
    let results = searchSymbols(query: query)
    jsonOutput([
        "query": query,
        "count": results.count,
        "symbols": Array(results.prefix(100))
    ])

case "export":
    guard args.count > 1 else {
        jsonOutput(["error": "Usage: sf-symbol export <name> [--weight <w>] [--size <n>] [--output <path>]"])
        exit(1)
    }
    let name = args[1]

    var weight = "regular"
    var size: CGFloat = 100
    var outputPath: String? = nil
    var rawCoords = false

    var i = 2
    while i < args.count {
        switch args[i] {
        case "--weight":
            if i + 1 < args.count { weight = args[i + 1]; i += 1 }
        case "--size":
            if i + 1 < args.count { size = CGFloat(Double(args[i + 1]) ?? 100); i += 1 }
        case "--output", "-o":
            if i + 1 < args.count { outputPath = args[i + 1]; i += 1 }
        case "--raw-coords":
            rawCoords = true
        default: break
        }
        i += 1
    }

    guard let svg = exportSymbolSVG(name: name, pointSize: size, weight: weight, rawCoords: rawCoords) else {
        jsonOutput(["error": "Symbol not found: \(name)"])
        exit(1)
    }

    if let path = outputPath {
        // Create parent directories if needed
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        do {
            try svg.write(toFile: path, atomically: true, encoding: .utf8)
            jsonOutput(["success": true, "symbol": name, "output": path, "weight": weight, "size": size])
        } catch {
            jsonOutput(["error": "Failed to write file: \(error.localizedDescription)"])
            exit(1)
        }
    } else {
        print(svg)
    }

case "info":
    guard args.count > 1 else {
        jsonOutput(["error": "Usage: sf-symbol info <name>"])
        exit(1)
    }
    let name = args[1]
    let availURL = URL(fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist")
    guard let availData = try? Data(contentsOf: availURL),
          let availDict = try? PropertyListSerialization.propertyList(from: availData, format: nil) as? [String: Any],
          let symbols = availDict["symbols"] as? [String: String] else {
        jsonOutput(["error": "Failed to load symbol data"])
        exit(1)
    }

    if let release = symbols[name] {
        var info: [String: Any] = [
            "name": name,
            "available_since": release,
            "exists": true
        ]
        let exists = NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        info["renderable"] = exists
        let related = symbols.keys.filter {
            $0 != name && ($0.hasPrefix(name + ".") || (name.contains(".") && $0.hasPrefix(name.components(separatedBy: ".").first! + ".")))
        }.sorted().prefix(20)
        info["related"] = Array(related)
        jsonOutput(info)
    } else {
        jsonOutput(["name": name, "exists": false])
    }

case "list":
    var limit = 100
    if args.count > 2 && args[1] == "--limit" {
        limit = Int(args[2]) ?? 100
    }
    let availURL = URL(fileURLWithPath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist")
    guard let availData = try? Data(contentsOf: availURL),
          let availDict = try? PropertyListSerialization.propertyList(from: availData, format: nil) as? [String: Any],
          let symbols = availDict["symbols"] as? [String: String] else {
        jsonOutput(["error": "Failed to load symbol data"])
        exit(1)
    }
    let sorted = symbols.keys.sorted()
    jsonOutput([
        "total": sorted.count,
        "symbols": Array(sorted.prefix(limit))
    ])

default:
    jsonOutput(["error": "Unknown command: \(command)"])
    exit(1)
}
