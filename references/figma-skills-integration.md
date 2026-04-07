# Figma Skills Integration

How this skill complements Figma's official MCP skill ecosystem. This skill is a **SwiftUI translation layer** — it extends the official skills with iOS 26-specific knowledge they don't have.

## Official Figma Skills Overview

Figma provides 7 official MCP skills. Install via `npx skills add https://github.com/figma/mcp-server-guide --skill <name>`.

| Skill | Purpose | How This Skill Extends It |
|-------|---------|--------------------------|
| **figma-implement-design** | 7-step Figma→code workflow (fetch, translate, validate) | Provides the iOS 26 SwiftUI translation for Step 5 |
| **figma-create-design-system-rules** | Generate AI agent rules encoding project conventions | Supplies iOS 26 SwiftUI conventions for the rules file |
| **figma-code-connect-components** | Connect Figma components to code implementations | Component mapping table serves as the starting point |
| **figma-use** | Write-to-canvas (frames, components, variables, auto layout) | SF Symbol CLI + Figma Plugin API gotchas improve output |
| **figma-generate-library** | Build design system library from codebase | iOS 26 component knowledge helps build accurate libraries |
| **figma-generate-design** | Build full-page screens in Figma using design system | Liquid Glass component mapping guides correct screen assembly |
| **figma-create-new-file** | Create blank Figma/FigJam files | No extension needed — use directly |

## figma-implement-design + This Skill

The official `figma-implement-design` skill has a 7-step workflow. This skill **extends Step 5** (Translate Conventions) with iOS 26 SwiftUI-specific translation.

### Combined Workflow

1. **Steps 1-4**: Use `figma-implement-design` as-is (extract node ID, fetch context, capture screenshot, download assets)
2. **Step 5 (enhanced)**: Instead of generic framework translation, use this skill's references:
   - `react-to-swiftui.md` for layout/styling conversion
   - `component-mapping.md` for Figma→SwiftUI component lookup
   - `liquid-glass-translation.md` for glass effect detection and mapping
   - `property-mapping.md` for Figma properties → SwiftUI modifiers
3. **Steps 6-7**: Use `figma-implement-design` for visual parity validation

### When to Use Which

| Scenario | Use |
|----------|-----|
| Generic web framework (React, Vue, HTML) | `figma-implement-design` alone |
| SwiftUI without iOS 26 glass features | `figma-implement-design` + this skill's `react-to-swiftui.md` |
| SwiftUI with iOS 26 Liquid Glass | `figma-implement-design` + this skill's full reference set |
| SwiftUI→Figma (reverse direction) | This skill alone (official skill doesn't cover reverse) |

## figma-create-design-system-rules + This Skill

Use the official skill to generate a rules file, then add iOS 26 SwiftUI conventions.

### iOS 26 SwiftUI Rules to Include

When running `create_design_system_rules`, specify these iOS 26 patterns:

```
Framework: SwiftUI (iOS 26+)

Component conventions:
- Use .buttonStyle(.glass) for primary action buttons, not manual .glassEffect()
- Use .buttonStyle(.glassProminent) for the single most important action
- Standard controls (Toggle, Slider, Stepper, Picker) get glass automatically — never add .glassEffect() manually
- Use GlassEffectContainer(spacing:) when 2+ glass elements are adjacent
- Use ToolbarSpacer(.fixed) to visually separate toolbar button groups

Layout conventions:
- Prefer Dynamic Type (.font(.headline)) over fixed sizes (.font(.system(size: 17)))
- Use .frame(maxWidth: .infinity) for fill behavior, not hardcoded widths
- Use VStack/HStack spacing parameter, not manual padding between items

Material conventions:
- .glassEffect(.regular) for navigation chrome (toolbars, tab bars, sheets)
- .glassEffect(.clear) only for media-rich contexts (photo/video viewers)
- .background(.ultraThinMaterial) for full-screen background blur (NOT .glassEffect())
- Never mix .regular and .clear glass variants in the same view hierarchy

Token conventions:
- Map Figma variables to project's AppTheme/DesignTokens constants
- Prefer semantic system colors (Color(.systemBackground)) over raw hex values
```

## figma-code-connect-components + This Skill

This skill's `component-mapping.md` serves as the **starting point** for creating Code Connect mappings.

### Workflow

1. Use `component-mapping.md` to identify which Figma component maps to which SwiftUI view
2. Use the official `figma-code-connect-components` skill to create the actual `FigmaConnect` structs
3. See [Code Connect SwiftUI Reference](code-connect-swiftui.md) for iOS 26-specific mapping examples

### Example: Converting a Mapping Table Entry to Code Connect

From `component-mapping.md`:
> Figma: "Button - Liquid Glass - Text" → SwiftUI: `Button("Label") { }.buttonStyle(.glass)`

As a Code Connect struct:
```swift
struct GlassButton_Connection: FigmaConnect {
    let component = "Button - Liquid Glass - Text"
    
    @FigmaString("Label") var label: String
    @FigmaBoolean("Disabled") var isDisabled: Bool
    
    var body: some View {
        Button(label) { }
            .buttonStyle(.glass)
            .disabled(isDisabled)
    }
}
```

## figma-use + This Skill

The official `figma-use` skill improves `use_figma` tool calls. This skill adds:

- **SF Symbol injection**: The SF Symbol CLI (`tools/sf_symbol_cli.swift`) exports pixel-perfect Apple vector SVGs that can be injected via `figma.createNodeFromSvg()` — the Figma UI kit only includes size placeholders
- **Figma Plugin API gotchas**: Font loading, auto-layout sizing order, `counterAxisSizingMode` vs `layoutSizing`, sealed node types (see `figma-mcp-workflow.md`)
- **SwiftUI→Figma hierarchy mapping**: How `VStack`/`HStack` translates to Figma auto-layout frames

### Combined Workflow (SwiftUI→Figma)

1. Invoke `figma-use` skill for optimal `use_figma` output
2. Use this skill's `component-mapping.md` reverse lookup for Figma component names
3. Use this skill's SF Symbol CLI for icon injection
4. Apply Figma Plugin API gotchas from `figma-mcp-workflow.md`

## figma-generate-library + This Skill

When building an iOS 26 design system library from an existing SwiftUI codebase:

1. Use `figma-generate-library` for the phased workflow (discovery → foundations → structure → components → QA)
2. During the **component building phase**, use this skill's `component-mapping.md` to ensure Figma components match Apple's iOS 26 naming conventions
3. Use `liquid-glass-translation.md` to correctly build Liquid Glass variant components
4. Use the SF Symbol CLI to inject icons into component thumbnails

## figma-generate-design + This Skill

When generating full-page iOS 26 screens in Figma:

1. Use `figma-generate-design` for multi-section screen assembly
2. Reference this skill's `component-mapping.md` for correct Figma component names to search
3. Use `liquid-glass-translation.md` to correctly apply glass effects:
   - Navigation bars → Liquid Glass - Regular
   - Tab bars → automatic glass (iOS 26 Tab Bar component)
   - Floating buttons → Button - Liquid Glass
   - Content areas → no glass
4. Validate the generated screen against iOS 26 HIG patterns
