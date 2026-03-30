# Component Mapping: Figma ↔ SwiftUI (iOS 26)

Bidirectional lookup table mapping Apple's iOS 26 Figma UI kit components to their SwiftUI equivalents. Use this when:
- **Figma → Code**: You see a Figma component and need the SwiftUI implementation
- **Code → Figma**: You have SwiftUI code and need to find/reference the Figma component

## How to Use

- **Figma → Code**: Find the Figma component name in the left column → use the SwiftUI code in the right column
- **Code → Figma**: Find the SwiftUI API in the right column → use the Figma name to call `search_design_system`

## Buttons

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Button - Content Area | `Button { } label: { /* custom content */ }` | Standard button with arbitrary content |
| Button - Liquid Glass - Text | `Button("Label") { }.buttonStyle(.glass)` | iOS 26+. Fallback: `.bordered` on iOS 18 |
| Button - Liquid Glass - Symbol | `Button { } label: { Image(systemName: "icon") }.buttonStyle(.glass)` | iOS 26+. SF Symbol in glass button |
| Popup Button | `Menu { /* actions */ } label: { /* label */ } primaryAction: { /* default action */ }` | Tap = primary action, hold = menu |
| Picker Button | `Picker("Label", selection: $value) { /* options */ }.pickerStyle(.menu)` | Dropdown-style picker |

### Button Style Quick Reference (iOS 26)

```swift
// Liquid Glass button (iOS 26+)
Button("Action") { }.buttonStyle(.glass)

// Prominent glass button (primary action)
Button("Save") { }.buttonStyle(.glassProminent)

// Tinted glass button
Button("Custom") { }.buttonStyle(.glass(.blue))

// Bordered button (pre-iOS 26 fallback)
Button("Action") { }.buttonStyle(.bordered)
Button("Primary") { }.buttonStyle(.borderedProminent)
```

## Tab Bars

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Tab Bar | `TabView { Tab("Name", systemImage: "icon") { View() } }.tabViewStyle(.sidebarAdaptable)` | iOS 26+ auto-applies Liquid Glass |
| Tab Bar - iPhone | `TabView { /* tabs */ }` | Compact layout, bottom tab bar |
| Tab Bar - iPad | `TabView { /* tabs */ }.tabViewStyle(.sidebarAdaptable)` | Regular layout with optional sidebar |
| Tab Bars (multi-variant) | — | Figma showcase only, not a single view |

### Tab Bar Patterns (iOS 26)

```swift
// Standard tab bar — glass applied automatically on iOS 26
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Games", systemImage: "gamecontroller") { GamesView() }
    Tab(role: .search) { SearchView() } // Separated trailing search tab
}

// Auto-hiding tab bar on scroll
TabView { /* tabs */ }
    .tabBarMinimizeBehavior(.onScrollDown)

// Customizable sidebar-adaptable tabs
TabView { /* tabs */ }
    .tabViewStyle(.sidebarAdaptable)
    .tabViewCustomization($customization)
```

## Toolbars

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Toolbars - Top | `.toolbar { ToolbarItem(placement: .topBarTrailing) { } }` | Top navigation bar items |
| Toolbars - Bottom | `.toolbar { ToolbarItem(placement: .bottomBar) { } }` | Bottom toolbar items |
| Toolbar - Top - iPhone | `.toolbar { ToolbarItemGroup(placement: .topBarTrailing) { } }` | iPhone compact toolbar |
| Toolbar - Top - iPad | `.toolbar { }` inside `NavigationStack` | iPad regular width toolbar |
| Toolbar - Top - Sheet | `.toolbar { }` inside `.sheet` presentation | Sheet toolbar with close button |
| Toolbar - Bottom - iPhone | `.toolbar { ToolbarItemGroup(placement: .bottomBar) { } }` | iPhone bottom toolbar |
| Toolbar - Bottom - iPad | `.toolbar { ToolbarItemGroup(placement: .bottomBar) { } }` | iPad bottom toolbar |
| Sidebar Toolbar | `.toolbar { }` inside `NavigationSplitView` sidebar | Toolbar in sidebar context |
| Grabber | `.presentationDragIndicator(.visible)` | Sheet drag handle |

### Toolbar Grouping with Spacers (iOS 26)

```swift
// Two separated button groups in toolbar
.toolbar {
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Undo") { }
        Button("Redo") { }

        ToolbarSpacer(.fixed) // Separates groups visually

        Button("Markup") { }
        Button("More") { }
    }
}

// Close button pushed to trailing edge
.toolbar {
    ToolbarSpacer(.flexible, placement: .topBarTrailing)
    ToolbarItem(placement: .topBarTrailing) {
        Button(role: .close) { dismiss() }
    }
}
```

## Alerts & Dialogs

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Alert | `.alert("Title", isPresented: $show) { /* buttons */ } message: { /* message */ }` | Standard system alert |
| Alert (light/dark variants) | Same API — system handles appearance | Figma shows both modes |
| Overlay - Alerts | Automatic — system provides dimming | No code needed |

## Lists

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Row | Content inside `List { }` or `ForEach` | Standard list row |
| Row - Button | `Button { } label: { /* row content */ }` inside `List` | Tappable list row |
| Row with Swipe Actions | `.swipeActions(edge: .trailing) { Button("Delete", role: .destructive) { } }` | Swipe-to-reveal actions |
| Header | `Section("Title") { }` or `Section { } header: { Text("Title") }` | Section header in List |
| Section Header | `Section("Title") { }` | Plain section header text |
| Grouped Table Footer | `Section { } footer: { Text("Footer text") }` with `.listStyle(.insetGrouped)` | Section footer |

```swift
// iOS 26: Section headers auto-adopt title-style capitalization
// Update headers to "Title Case" instead of "ALL CAPS"
List {
    Section("Recent Games") { // ← Title case, not "RECENT GAMES"
        ForEach(games) { game in
            GameRow(game: game)
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) { delete(game) }
                }
        }
    }
}
.listStyle(.insetGrouped) // Increased row height + padding on iOS 26
```

## Sidebars

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Sidebar | `NavigationSplitView { List { /* sidebar */ } } detail: { /* detail */ }` | Two/three column layout |
| Sidebar Row | `Label("Title", systemImage: "icon")` in sidebar `List` | Standard sidebar row |
| Sidebar Search Field | `.searchable(text: $search)` on sidebar content | Search in sidebar |
| Sidebar with Multilevel Hierarchy | `DisclosureGroup` or `OutlineGroup` in sidebar | Expandable hierarchy |

```swift
// Sidebar with background extension effect (iOS 26)
NavigationSplitView {
    List(selection: $selection) { /* sidebar content */ }
} detail: {
    DetailView()
        .backgroundExtensionEffect() // Mirrors content under sidebar
}
```

## Controls

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Segmented control | `Picker("Label", selection: $value) { }.pickerStyle(.segmented)` | Segmented control |
| Sliders | `Slider(value: $value, in: 0...100)` | Standard slider — knob becomes glass on interaction (iOS 26) |
| Steppers | `Stepper("Label", value: $value, in: 0...10, step: 1)` | Increment/decrement control |
| Page control | `TabView { }.tabViewStyle(.page)` | Swipeable pages with dots |

## Pickers

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Date and time - Pickers | `DatePicker("Label", selection: $date, displayedComponents: [.date, .hourAndMinute])` | Date/time picker |
| Color Picker - iPad | `ColorPicker("Label", selection: $color)` | Color selection (iPad shows full panel) |

## Menus & Context Menus

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Menu - iPhone | `Menu { Button("Action") { } } label: { Label("Options", systemImage: "ellipsis.circle") }` | Dropdown menu |
| Menu - iPad - Actions | `Menu { Button("Delete", role: .destructive) { } } label: { }` | Menu with destructive actions |
| Context Menu | `.contextMenu { Button("Copy") { } Button("Delete", role: .destructive) { } }` | Long-press context menu |

## Popovers

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Popover | `.popover(isPresented: $show) { PopoverContent() }` | Standard popover |
| Popovers (iPad Only) | `.popover(isPresented: $show) { }` | Renders as popover on iPad, sheet on iPhone |

## Materials & Effects

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Liquid Glass - Regular - Large | `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))` | Large interactive glass element |
| Liquid Glass - Regular - Medium | `.glassEffect(.regular, in: .rect(cornerRadius: 16))` | Medium glass element |
| Liquid Glass - Regular - Small | `.glassEffect(.regular, in: .capsule)` | Small pill-shaped glass |
| Liquid Glass - Clear/Light | `.glassEffect(.clear)` | Transparent variant — media backgrounds only |
| Scroll Edge Effect - Soft | `.scrollEdgeEffectStyle(.soft, for: .top)` | Soft content fade at scroll edge |
| Scroll Edge Effect - Hard | `.scrollEdgeEffectStyle(.hard, for: .top)` | Hard content masking at scroll edge |

## Empty States

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Empty States | `ContentUnavailableView("Title", systemImage: "icon", description: Text("Description"))` | iOS 17+ |
| Empty States (alternate) | `ContentUnavailableView { Label("Title", systemImage: "icon") } actions: { Button("Action") { } }` | With action button |

## Widgets

| Figma Component | SwiftUI Equivalent | Notes |
|---|---|---|
| Home Screen Widgets | WidgetKit `.systemSmall` / `.systemMedium` / `.systemLarge` | Home screen widget families |
| Lock Screen Widget - Inline | WidgetKit `.accessoryInline` | Single-line lock screen widget |
| Lock Screen Widget / Circular / Icon | WidgetKit `.accessoryCircular` | Circular lock screen widget |
| Lock Screen Widget / Circular / Closed Gauge | `Gauge(value:) { }.gaugeStyle(.accessoryCircularCapacity)` | Circular gauge widget |
| Lock Screen Widget - Rectangular Text Gauge | WidgetKit `.accessoryRectangular` with `Gauge` | Rectangular with gauge |
| Lock Screen Widget - Rectangular with Chart | WidgetKit `.accessoryRectangular` with Swift Charts | Rectangular with chart |

## System Components (Non-Implementable)

These Figma components represent system-level UI. They exist for design reference, not for implementation:

| Figma Component | Purpose |
|---|---|
| Keyboard | System keyboard variants — shown via `.keyboardType()` modifier |
| Text Selection | System selection handles — automatic in `TextField`/`TextEditor` |
| Face ID | Biometric auth — triggered via `LAContext().evaluatePolicy()` |
| Notifications | Push notification banners — configured via `UNUserNotificationCenter` |
| Lock Screen / Home Screen / Control Center / Wallpapers | System screens — not implementable by apps |

## Reverse Lookup: SwiftUI → Figma Search Terms

When you have SwiftUI code and need to find the Figma component, use these search terms with `search_design_system`:

| SwiftUI Code | Search `search_design_system` With |
|---|---|
| `TabView { }` | "Tab Bar" |
| `.toolbar { }` | "Toolbar" |
| `.alert()` | "Alert" |
| `List { }` / `ForEach` | "Row" |
| `.swipeActions { }` | "Swipe" |
| `Section(header:)` | "Header" or "Section" |
| `NavigationSplitView` | "Sidebar" |
| `Picker(.segmented)` | "Segmented" |
| `Slider` | "Slider" |
| `Stepper` | "Stepper" |
| `TabView(.page)` | "Page control" |
| `.popover()` | "Popover" |
| `.contextMenu { }` | "Context Menu" |
| `Menu { }` | "Menu" |
| `DatePicker` | "Picker" or "Date" |
| `ColorPicker` | "Color Picker" |
| `.glassEffect()` | "Liquid Glass" |
| `ContentUnavailableView` | "Empty States" |
| `Button(.glass)` | "Button - Liquid Glass" |
| `.sheet { }` | "Grabber" (for the drag indicator) |
| `ShareLink` | "Overlay" (Activity Views category) |
