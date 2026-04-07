# Code Connect for SwiftUI (iOS 26)

Code Connect maps Figma components directly to your SwiftUI code. Once configured, `get_design_context` returns your actual SwiftUI snippets instead of React+Tailwind — eliminating the translation step for mapped components.

## When to Set Up Code Connect

Code Connect is an **optimization layer**, not a prerequisite. The recommended workflow:

1. **Start** by using this skill's translation tables (component-mapping.md, react-to-swiftui.md) to translate Figma→SwiftUI
2. **After translating 5-10 components**, codify the successful translations as Code Connect mappings
3. **Future translations** of the same components become automatic — no translation step needed
4. **New/unmapped components** still use the translation tables as fallback

## Setup

### 1. Add the Swift Package

In your `Package.swift` or Xcode project, add Code Connect as a dependency:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/code-connect.git", from: "1.0.0")
]
```

Add to your target:
```swift
.target(name: "MyApp", dependencies: [
    .product(name: "CodeConnect", package: "code-connect")
])
```

### 2. Create FigmaConnect Structs

Each mapping is a Swift struct conforming to `FigmaConnect`:

```swift
import CodeConnect

struct GlassButton_Connection: FigmaConnect {
    let component = "Button - Liquid Glass - Text"  // Figma component name
    
    @FigmaString("Label") var label: String
    @FigmaBoolean("Disabled") var isDisabled: Bool
    
    var body: some View {
        Button(label) { }
            .buttonStyle(.glass)
            .disabled(isDisabled)
    }
}
```

### 3. Register via MCP

Use the `add_code_connect_map` tool to register your mappings:

```
Tool: add_code_connect_map
Parameters:
  fileKey: "<your Figma file>"
  nodeId: "<component node ID>"
```

Or use `get_code_connect_suggestions` to get AI-suggested mappings, then confirm with `send_code_connect_mappings`.

### 4. Filter to SwiftUI (Remote Server)

On the remote MCP server, set `clientFrameworks` to filter Code Connect output:

```
Tool: get_design_context
Parameters:
  fileKey: "<fileKey>"
  nodeId: "<nodeId>"
  clientFrameworks: "SwiftUI"
```

On the desktop server, select your SwiftUI mapping in Dev Mode's inspect panel.

## Property Decorators

### @FigmaString

Maps text properties from Figma to Swift strings:

```swift
@FigmaString("Title") var title: String
@FigmaString("Subtitle") var subtitle: String
```

### @FigmaBoolean

Maps boolean properties (toggles, switches, visibility):

```swift
@FigmaBoolean("Disabled") var isDisabled: Bool
@FigmaBoolean("Show Icon", hideDefault: true) var showIcon: Bool
```

`hideDefault: true` suppresses the property in generated snippets when it has the default value — keeps output clean.

### @FigmaEnum

Maps variant selections to Swift enums:

```swift
@FigmaEnum("Style", mapping: [
    "Glass": ButtonVariant.glass,
    "Glass Prominent": ButtonVariant.glassProminent,
    "Bordered": ButtonVariant.bordered
]) var style: ButtonVariant
```

### @FigmaInstance

Connects child instances bound to instance-swap properties:

```swift
@FigmaInstance("Leading Icon") var icon: Image?
```

### @FigmaChildren

Handles nested instances not bound to instance-swap properties. Uses the **layer name** as parameter:

```swift
@FigmaChildren("Content") var content: [AnyView]
```

Nested instances must have their own separate Code Connect mappings.

## Variant Mapping

When one Figma component maps to multiple SwiftUI implementations:

```swift
// Glass button variant
struct GlassButton_Connection: FigmaConnect {
    let component = "Button - Liquid Glass"
    let variant = ["Style": "Glass"]
    
    @FigmaString("Label") var label: String
    
    var body: some View {
        Button(label) { }
            .buttonStyle(.glass)
    }
}

// Prominent glass variant
struct ProminentButton_Connection: FigmaConnect {
    let component = "Button - Liquid Glass"
    let variant = ["Style": "Prominent"]
    
    @FigmaString("Label") var label: String
    
    var body: some View {
        Button(label) { }
            .buttonStyle(.glassProminent)
    }
}
```

## Conditional Modifiers with figmaApply

Apply SwiftUI modifiers conditionally based on Figma properties:

```swift
struct Card_Connection: FigmaConnect {
    let component = "Card"
    
    @FigmaBoolean("Has Glass") var hasGlass: Bool
    @FigmaEnum("Size", mapping: [
        "Small": ControlSize.small,
        "Regular": ControlSize.regular,
        "Large": ControlSize.large
    ]) var size: ControlSize
    
    var body: some View {
        CardView()
            .controlSize(size)
            .figmaApply(hasGlass) { view in
                view.glassEffect(.regular, in: .rect(cornerRadius: 22))
            }
    }
}
```

`figmaApply` also supports `elseApply` for fallback:

```swift
.figmaApply(isProminent, apply: { $0.buttonStyle(.glassProminent) },
            elseApply: { $0.buttonStyle(.glass) })
```

## iOS 26 Code Connect Examples

### Glass Button

```swift
struct LiquidGlassButton_CC: FigmaConnect {
    let component = "Button - Liquid Glass - Text"
    
    @FigmaString("Label") var label: String
    @FigmaBoolean("Disabled") var isDisabled: Bool
    @FigmaEnum("Size", mapping: [
        "Mini": ControlSize.mini,
        "Small": ControlSize.small,
        "Regular": ControlSize.regular,
        "Large": ControlSize.large,
        "Extra Large": ControlSize.extraLarge
    ]) var size: ControlSize
    
    var body: some View {
        Button(label) { }
            .buttonStyle(.glass)
            .controlSize(size)
            .disabled(isDisabled)
    }
}
```

### Tab Bar

```swift
struct TabBar_CC: FigmaConnect {
    let component = "Tab Bar"
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") { /* content */ }
            Tab("Search", systemImage: "magnifyingglass") { /* content */ }
            Tab("Profile", systemImage: "person") { /* content */ }
        }
        // Glass is automatic on iOS 26
    }
}
```

### Liquid Glass Panel

```swift
struct GlassPanel_CC: FigmaConnect {
    let component = "Liquid Glass - Regular - Large"
    
    @FigmaChildren("Content") var content: [AnyView]
    @FigmaEnum("Shape", mapping: [
        "Rectangle": GlassShape.rect,
        "Capsule": GlassShape.capsule,
        "Circle": GlassShape.circle
    ]) var shape: GlassShape
    
    var body: some View {
        VStack {
            ForEach(content) { $0 }
        }
        .glassEffect(.regular, in: resolvedShape)
    }
}
```

## Xcode Previews

Code Connect structs work as Xcode previews via `#Preview`, eliminating duplicate example code:

```swift
#Preview {
    GlassButton_CC(label: "Action", isDisabled: false, size: .regular)
}
```

## Acceleration Loop Workflow

```
1. Translate component using reference tables
   ↓
2. Verify visual parity (screenshot comparison)
   ↓
3. Create FigmaConnect struct from verified translation
   ↓
4. Register via add_code_connect_map
   ↓
5. Future get_design_context calls return SwiftUI directly
   ↓
6. Translate next component... (repeat)
```

After 10-20 mappings, most common components are covered and `get_design_context` returns SwiftUI snippets directly for the majority of your design system.
