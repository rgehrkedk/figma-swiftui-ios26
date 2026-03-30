# Liquid Glass Translation: Figma ↔ SwiftUI

Complete mapping between Figma's iOS 26 Liquid Glass components and SwiftUI's glass APIs.

## Core API Reference

### `glassEffect(_:in:)`

The primary modifier for applying glass to custom views.

```swift
// Basic — uses DefaultGlassEffectShape (Capsule)
.glassEffect(.regular)

// With explicit shape
.glassEffect(.regular, in: .rect(cornerRadius: 16))

// With RoundedRectangle shape
.glassEffect(.regular, in: .rect(cornerRadius: 22))

// With Capsule (same as default)
.glassEffect(.regular, in: .capsule)

// With Circle
.glassEffect(.regular, in: .circle)
```

### Glass Variants

| SwiftUI | Transparency | When to Use |
|---|---|---|
| `.glassEffect(.regular)` | ~95% opaque | Default — most UI chrome, toolbars, cards |
| `.glassEffect(.clear)` | Higher transparency | Media overlays, photo/video viewers, content behind glass matters |
| `.glassEffect(.regular.interactive())` | ~95% + responds to touch/pointer | Buttons, interactive controls, custom tappable glass |
| `.glassEffect(.regular.tint(.blue))` | Tinted glass | Prominent/accented actions, selected states |

### Glass Effect Container

Groups multiple glass elements to avoid visual fragmentation. **Required** when multiple glass shapes appear near each other.

```swift
GlassEffectContainer(spacing: 8) {
    VStack(spacing: 8) {
        Button("Action 1") { }
            .glassEffect(.regular.interactive(), in: .capsule)
        Button("Action 2") { }
            .glassEffect(.regular.interactive(), in: .capsule)
    }
}
```

- Renders combined shadow/specular once (performance)
- Enables morph transitions between contained elements
- `spacing` parameter defines the visual gap between glass shapes
- Only wrap elements that are spatially related — not the entire screen

### Morph Transitions

Glass shapes can morph between states using matched geometry:

```swift
@Namespace private var glassNS

// Source state
view1
    .glassEffect(.regular, in: .capsule)
    .glassEffectID("action", in: glassNS)

// Destination state — same ID, glass morphs
view2
    .glassEffect(.regular, in: .rect(cornerRadius: 22))
    .glassEffectID("action", in: glassNS)
```

#### Transition Types

| Type | Usage | SwiftUI |
|---|---|---|
| Matched geometry | Elements close together, shape morphs | `.glassEffectID(_:in:)` — default when ID matches |
| Materialize | Elements far apart, dissolve transition | `.transition(.glassEffect.materialize)` |

#### Union (Combining Shapes)

Multiple glass shapes can be visually unified:

```swift
@Namespace private var unionNS

HStack {
    icon
        .glassEffectUnion(id: "combined", in: unionNS)
    label
        .glassEffectUnion(id: "combined", in: unionNS)
}
.glassEffect(.regular, in: .capsule)
```

## Figma Component → SwiftUI Glass Mapping

### Button Variants

| Figma Component | SwiftUI |
|---|---|
| `Button - Liquid Glass - Icon` | `Button { } label: { Image(systemName:) }.buttonStyle(.glass)` |
| `Button - Liquid Glass - Text` | `Button("Title") { }.buttonStyle(.glass)` |
| `Button - Liquid Glass - Combo` | `Button { } label: { Label("Title", systemImage:) }.buttonStyle(.glass)` |
| `Button - Gray - Text` | `Button("Title") { }.buttonStyle(.glass(.color))` or `.buttonStyle(.borderedProminent)` on iOS 26 |
| Prominent/tinted button variant | `Button("Title") { }.buttonStyle(.glassProminent)` |

#### Button Size from Figma

Figma buttons use explicit sizing. SwiftUI glass buttons have automatic sizing. Use `.controlSize()`:

| Figma Approximate Height | SwiftUI |
|---|---|
| ~28pt | `.controlSize(.mini)` |
| ~32pt | `.controlSize(.small)` |
| ~36-40pt (default) | `.controlSize(.regular)` — default |
| ~50pt | `.controlSize(.large)` |
| ~56pt | `.controlSize(.extraLarge)` |

### Tab Bar

| Figma Component | SwiftUI |
|---|---|
| `Tab Bar` | `TabView` — glass effect automatic on iOS 26 |
| Tab item (with icon + label) | `Tab("Title", systemImage: "icon") { content }` |
| Tab with badge | `Tab(...) { }.badge(count)` |
| Minimized tab bar state | `.tabBarMinimizeBehavior(.onScrollDown)` on content |
| Search tab (trailing position) | `Tab(role: .search) { }` |

### Toolbar / Navigation Bar

| Figma Component | SwiftUI |
|---|---|
| `Navigation Bar - Title Large` | `.navigationTitle("Title").navigationBarTitleDisplayMode(.large)` |
| `Navigation Bar - Title Inline` | `.navigationTitle("Title").navigationBarTitleDisplayMode(.inline)` |
| `Navigation Bar - Title Below` | `.navigationTitle("Title")` — iOS 26 default below-bar position |
| Toolbar button (glass) | `.toolbar { Button("Action") { } }` — auto-glass on iOS 26 |
| Toolbar with spacing groups | Use `ToolbarSpacer(.fixed)` or `ToolbarSpacer(.flexible)` between items |
| Bottom toolbar | `.toolbar { ToolbarItemGroup(placement: .bottomBar) { } }` |
| Safe area bar (custom) | `.safeAreaBar(edge: .bottom) { content }` |

### Materials / Backgrounds

| Figma Component | SwiftUI |
|---|---|
| `Material - Thick` | `.thick` material or `.glassEffect(.regular)` for custom glass |
| `Material - Regular` | `.regular` material or `.glassEffect(.regular)` |
| `Material - Thin` | `.thin` material |
| `Material - Ultra Thin` | `.ultraThinMaterial` or `.glassEffect(.clear)` for custom glass |
| Background blur effect | `.glassEffect(.regular)` on iOS 26 (preferred over `.background(.thinMaterial)`) |

### System Controls Refresh (iOS 26)

These controls automatically adopt glass appearance when compiled with Xcode 26:

| Figma Component | SwiftUI | Glass Behavior |
|---|---|---|
| `Toggle` | `Toggle(isOn:) { }` | Background becomes glass automatically |
| `Slider` | `Slider(value:in:) { }` | Track and thumb become glass |
| `Stepper` | `Stepper(value:in:) { }` | Plus/minus buttons become glass |
| `Picker` (segmented) | `Picker { }.pickerStyle(.segmented)` | Segments become glass |
| `DatePicker` | `DatePicker(selection:) { }` | Compact style becomes glass |
| `ProgressView` | `ProgressView(value:)` | Track becomes glass |

**No manual `.glassEffect()` needed** for standard controls — the system handles it.

## Visual Properties

### Corner Radius Mapping

Figma glass corner radii map to SwiftUI shape parameters:

| Figma Radius | Context | SwiftUI Shape |
|---|---|---|
| Full capsule / pill | Buttons, pills, chips | `.capsule` (default for glass) |
| 22pt | Large cards, sheets | `.rect(cornerRadius: 22)` |
| 16pt | Medium cards, action groups | `.rect(cornerRadius: 16)` |
| 12pt | Small cards | `.rect(cornerRadius: 12)` |
| Device corner matching | Edge-to-edge containers | `ConcentricRectangle` |

### Shadows and Specular

Glass effects include automatic shadows and specular highlights. **Do not add manual `.shadow()`** on top of `.glassEffect()` — it doubles the effect.

If Figma shows a shadow on a glass element:
- It's part of the glass rendering → `.glassEffect()` handles it
- **Do not translate the Figma shadow** to `.shadow()` separately

### Opacity and Transparency

| Figma Layer Opacity | SwiftUI |
|---|---|
| 100% opacity glass fill | `.glassEffect(.regular)` — system controls transparency |
| Lower opacity glass fill | `.glassEffect(.clear)` — not manual `.opacity()` |
| Content-over-glass with lower opacity | `.foregroundStyle(.secondary)` for de-emphasized text |

## When NOT to Use Glass

Not every translucent Figma layer should become `.glassEffect()`:

| Figma Pattern | Correct SwiftUI |
|---|---|
| Full-screen background blur | `.background(.ultraThinMaterial)` — not glass |
| Small inline subtle blur | `.background(.thinMaterial)` |
| Overlay dimming (scrim) | `Color.black.opacity(0.4)` |
| Text background highlight | `.background(.quaternary, in: .capsule)` |
| Interactive floating chrome | `.glassEffect(.regular.interactive())` ← **this IS glass** |
| Toolbar / tab bar backgrounds | Automatic — system applies glass to standard bars |
| Custom floating panels/cards | `.glassEffect(.regular, in: .rect(cornerRadius: 22))` ← **this IS glass** |

## Accessibility Considerations

Glass effects automatically respect these system settings:

| Setting | Behavior |
|---|---|
| Reduce Transparency | Glass becomes fully opaque — test your layout with this enabled |
| Increase Contrast | Glass tint intensifies for better visibility |
| Reduce Motion | Morph transitions become cross-dissolve |

Always ensure text on glass has sufficient contrast in **both** glass and opaque (reduced transparency) modes.

## Figma → SwiftUI Decision Tree

When you encounter a glass-like element in Figma:

1. **Is it a standard control** (Button, Toggle, Slider, Stepper, Picker, Tab, Toolbar)?
   → Use the standard SwiftUI control. Glass is automatic on iOS 26.

2. **Is it a standard navigation element** (TabView, NavigationStack toolbar)?
   → Use standard API. Glass is automatic.

3. **Is it interactive custom chrome** (floating action, custom control)?
   → `.glassEffect(.regular.interactive(), in: shape)`

4. **Is it a non-interactive floating panel/card**?
   → `.glassEffect(.regular, in: .rect(cornerRadius: N))`

5. **Is it a media overlay** (video player controls, photo viewer)?
   → `.glassEffect(.clear, in: shape)` for higher see-through

6. **Is it a full-screen background blur**?
   → `.background(.ultraThinMaterial)` — NOT glass

7. **Are there multiple glass elements close together**?
   → Wrap in `GlassEffectContainer(spacing:)`
