# Property Mapping: Figma → SwiftUI

Direct translation of Figma node properties (from `get_design_context`, `get_metadata`, and `get_variable_defs`) to SwiftUI view modifiers.

## Auto-Layout → SwiftUI Layout

Figma auto-layout is the primary layout system. Each auto-layout frame maps to a SwiftUI container.

### Direction & Alignment

| Figma Property | Value | SwiftUI |
|---|---|---|
| `layoutMode` | `VERTICAL` | `VStack(alignment: _, spacing: _) { }` |
| `layoutMode` | `HORIZONTAL` | `HStack(alignment: _, spacing: _) { }` |
| `primaryAxisAlignItems` | `MIN` | `alignment: .leading` (VStack) / `.top` (HStack) |
| `primaryAxisAlignItems` | `CENTER` | `alignment: .center` |
| `primaryAxisAlignItems` | `MAX` | `alignment: .trailing` (VStack) / `.bottom` (HStack) |
| `primaryAxisAlignItems` | `SPACE_BETWEEN` | `Spacer()` between children |
| `counterAxisAlignItems` | `MIN` | Cross-axis: `.leading` (HStack) / `.top` (VStack) |
| `counterAxisAlignItems` | `CENTER` | Cross-axis: `.center` |
| `counterAxisAlignItems` | `MAX` | Cross-axis: `.trailing` (HStack) / `.bottom` (VStack) |
| `itemSpacing` | Number | `spacing:` parameter on VStack/HStack |

### Sizing Modes

| Figma Property | Value | SwiftUI |
|---|---|---|
| `primaryAxisSizingMode` | `FIXED` | `.frame(width:)` or `.frame(height:)` with explicit value |
| `primaryAxisSizingMode` | `AUTO` | No frame constraint — inherent size |
| `counterAxisSizingMode` | `FIXED` | `.frame()` with explicit cross-axis value |
| `counterAxisSizingMode` | `AUTO` | No constraint — content-driven |
| Child `layoutSizingHorizontal` | `FILL` | `.frame(maxWidth: .infinity)` |
| Child `layoutSizingVertical` | `FILL` | `.frame(maxHeight: .infinity)` |
| Child `layoutSizingHorizontal` | `FIXED` | `.frame(width: value)` |
| Child `layoutSizingHorizontal` | `HUG` | No frame — uses intrinsic content size |

### Padding

| Figma Property | SwiftUI |
|---|---|
| `paddingTop`, `paddingBottom`, `paddingLeft`, `paddingRight` all equal | `.padding(value)` |
| `paddingLeft` == `paddingRight` (horizontal symmetric) | `.padding(.horizontal, value)` |
| `paddingTop` == `paddingBottom` (vertical symmetric) | `.padding(.vertical, value)` |
| All different | `.padding(.top, pT).padding(.bottom, pB).padding(.leading, pL).padding(.trailing, pR)` |

## Fills & Colors

### Solid Fills

| Figma Property | SwiftUI |
|---|---|
| `fills: [{ type: "SOLID", color: { r, g, b }, opacity: a }]` | `Color(red: r, green: g, blue: b).opacity(a)` |
| `fills` on a frame (background) | `.background(Color(...))` |
| `fills` on text | `.foregroundStyle(Color(...))` |

### Gradient Fills

| Figma Property | SwiftUI |
|---|---|
| `type: "GRADIENT_LINEAR"` | `LinearGradient(colors: [...], startPoint: _, endPoint: _)` |
| `type: "GRADIENT_RADIAL"` | `RadialGradient(colors: [...], center: _, startRadius: _, endRadius: _)` |
| `type: "GRADIENT_ANGULAR"` | `AngularGradient(colors: [...], center: _)` |
| `gradientHandlePositions` | Map to `UnitPoint` for start/end points |

### Variable Fills (Design Tokens)

When `get_variable_defs` returns variables, map these to the project's token system:

| Figma Variable Pattern | SwiftUI Equivalent |
|---|---|
| `Labels/Primary` | `.foregroundStyle(.primary)` |
| `Labels/Secondary` | `.foregroundStyle(.secondary)` |
| `Labels/Tertiary` | `.foregroundStyle(.tertiary)` |
| `Fills/Quaternary` | `.background(.quaternary)` or `.ultraThinMaterial` |
| `Backgrounds/Primary` | `Color(.systemBackground)` |
| `Backgrounds/Secondary` | `Color(.secondarySystemBackground)` |
| `Separators/Non-opaque` | `Color(.separator)` or `Divider()` |
| `Accents/Blue` | `.tint(.blue)` or `Color.blue` |
| Custom semantic variables | Map to project design tokens (e.g., `AppTheme.success`) |

## Typography

### Font Properties

| Figma Property | SwiftUI |
|---|---|
| `fontFamily: "SF Pro"` | Use Dynamic Type `.font(.body)` etc. — don't hardcode SF Pro |
| `fontSize` + `fontWeight` combined | Prefer semantic fonts first, then explicit if needed |
| `fontSize: 34, fontWeight: 700` | `.font(.largeTitle)` |
| `fontSize: 28, fontWeight: 700` | `.font(.title)` |
| `fontSize: 22, fontWeight: 700` | `.font(.title2)` |
| `fontSize: 20, fontWeight: 600` | `.font(.title3)` |
| `fontSize: 17, fontWeight: 600` | `.font(.headline)` |
| `fontSize: 17, fontWeight: 400` | `.font(.body)` |
| `fontSize: 16, fontWeight: 400` | `.font(.callout)` |
| `fontSize: 15, fontWeight: 400` | `.font(.subheadline)` |
| `fontSize: 13, fontWeight: 400` | `.font(.footnote)` |
| `fontSize: 12, fontWeight: 400` | `.font(.caption)` |
| `fontSize: 11, fontWeight: 400` | `.font(.caption2)` |
| `textCase: "UPPER"` | `.textCase(.uppercase)` |
| `textAlignHorizontal: "CENTER"` | `.multilineTextAlignment(.center)` |
| `textAlignHorizontal: "RIGHT"` | `.multilineTextAlignment(.trailing)` |
| `lineHeightPx` | `.lineSpacing(value - fontSize)` if non-default |
| `letterSpacing` | `.tracking(value)` |
| `textDecoration: "UNDERLINE"` | `.underline()` |
| `textDecoration: "STRIKETHROUGH"` | `.strikethrough()` |

### Font Weight Mapping

| Figma `fontWeight` | SwiftUI `.fontWeight()` |
|---|---|
| 100 | `.ultraLight` |
| 200 | `.thin` |
| 300 | `.light` |
| 400 | `.regular` |
| 500 | `.medium` |
| 600 | `.semibold` |
| 700 | `.bold` |
| 800 | `.heavy` |
| 900 | `.black` |

## Corner Radius

| Figma Property | SwiftUI |
|---|---|
| `cornerRadius: N` (all corners equal) | `.clipShape(RoundedRectangle(cornerRadius: N))` |
| Per-corner: `topLeftRadius`, `topRightRadius`, `bottomLeftRadius`, `bottomRightRadius` | `UnevenRoundedRectangle(topLeadingRadius: TL, bottomLeadingRadius: BL, bottomTrailingRadius: BR, topTrailingRadius: TR)` |
| `cornerRadius` matching parent's inner curve | `ConcentricRectangle` (iOS 26+) — hardware-aligned nesting |

## Effects

### Shadows

| Figma Property | SwiftUI |
|---|---|
| `effects: [{ type: "DROP_SHADOW", color, offset, radius }]` | `.shadow(color: Color(...), radius: R, x: offsetX, y: offsetY)` |
| `effects: [{ type: "INNER_SHADOW" }]` | No direct equivalent — approximate with overlay + gradient |

### Blur

| Figma Property | SwiftUI |
|---|---|
| `effects: [{ type: "LAYER_BLUR", radius }]` | `.blur(radius: value)` |
| `effects: [{ type: "BACKGROUND_BLUR" }]` | `.background(.ultraThinMaterial)` or `.glassEffect()` on iOS 26 |

## Constraints & Responsive Behavior

| Figma Property | SwiftUI |
|---|---|
| `constraints.horizontal: "STRETCH"` | `.frame(maxWidth: .infinity)` |
| `constraints.horizontal: "CENTER"` | `.frame(maxWidth: .infinity)` + parent alignment center |
| `constraints.vertical: "TOP"` | Default behavior (top-aligned) |
| `constraints.vertical: "TOP_BOTTOM"` | `.frame(maxHeight: .infinity)` |
| `layoutGrow: 1` | `.frame(maxWidth: .infinity)` in HStack / `.frame(maxHeight: .infinity)` in VStack |

## Images & Assets

| Figma Property | SwiftUI |
|---|---|
| Image fill `scaleMode: "FILL"` | `.resizable().aspectRatio(contentMode: .fill)` |
| Image fill `scaleMode: "FIT"` | `.resizable().aspectRatio(contentMode: .fit)` |
| Image fill `scaleMode: "CROP"` | `.resizable().scaledToFill().clipped()` |
| SF Symbol reference | `Image(systemName: "symbol.name")` |
| Localhost image URL from MCP | Use directly — `AsyncImage(url: URL(string: "localhost:...")!)` for preview, extract asset for production |

## Boolean Operations → SwiftUI Shapes

| Figma Operation | SwiftUI |
|---|---|
| Union | Combined with `.union()` or `Path` addition |
| Subtract | `.subtracting()` or clip mask |
| Intersect | `.intersection()` |
| Exclude | `.symmetricDifference()` |

## Figma States → SwiftUI Interaction

| Figma Variant Property | SwiftUI |
|---|---|
| `State=Default` | Default view state |
| `State=Hover` | `.onHover { }` (iPadOS/macOS) |
| `State=Pressed` | `Button` pressed state (automatic) |
| `State=Focused` | `.focused()` / `@FocusState` |
| `State=Disabled` | `.disabled(true)` — auto-dims |
| `Mode=Light` / `Mode=Dark` | Automatic — use semantic colors, system handles mode |
