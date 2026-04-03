---
name: figma-swiftui-ios26
description: Use when translating between Figma designs and SwiftUI code for iOS 26+. Bridges the Figma MCP server (get_design_context, search_design_system) with native SwiftUI APIs including Liquid Glass, toolbars, navigation, and controls. Works bidirectionally — Figma → SwiftUI and SwiftUI → Figma.
---

# Figma ↔ SwiftUI Translation (iOS 26)

Bidirectional translation layer between Apple's iOS 26 Figma UI kit and SwiftUI code. Designed to work with the official Figma MCP server (`https://mcp.figma.com/mcp`).

## Why This Skill Exists

The Figma MCP server handles discovery and fetching but outputs **React + Tailwind by default**. It knows nothing about SwiftUI APIs — especially iOS 26-specific ones like `.glassEffect()`, `.buttonStyle(.glass)`, `GlassEffectContainer`, or `ToolbarSpacer`. This skill provides the translation layer that turns Figma MCP output into correct, idiomatic SwiftUI — and the reverse mapping when going from code back to Figma.

## Reference Loading Guide

**ALWAYS load reference files if there is even a small chance the content may be required.** It's better to have the context than to miss a pattern or make a mistake.

| Reference | Load When |
|-----------|-----------|
| **[Component Mapping](references/component-mapping.md)** | Identifying which Figma component corresponds to a SwiftUI view, or which Figma component to search for when you have SwiftUI code |
| **[React → SwiftUI Translation](references/react-to-swiftui.md)** | Translating `get_design_context` output (React + Tailwind) into SwiftUI views and modifiers |
| **[Property Mapping](references/property-mapping.md)** | Converting Figma node properties (auto-layout, fills, corner radii, typography) to SwiftUI modifiers |
| **[Liquid Glass Translation](references/liquid-glass-translation.md)** | Translating Liquid Glass Figma components into `.glassEffect()` API calls, and understanding variant sizing |
| **[Figma MCP Workflow](references/figma-mcp-workflow.md)** | Optimal tool call sequences for Figma → Code and Code → Figma directions |

## Core Workflow

### Figma → SwiftUI

1. **Fetch structured data** — Call `get_design_context` with the Figma node URL/ID
2. **Get visual reference** — Call `get_screenshot` for layout fidelity verification
3. **Get design tokens** — Call `get_variable_defs` if the design uses variables for colors, spacing, typography
4. **Translate the output** — The React + Tailwind output is a *representation of design intent*, not target code. Use the [React → SwiftUI](references/react-to-swiftui.md) and [Property Mapping](references/property-mapping.md) references to convert to idiomatic SwiftUI
5. **Map iOS 26 components** — Identify Figma components from Apple's iOS 26 UI kit and replace with correct SwiftUI APIs using the [Component Mapping](references/component-mapping.md) reference
6. **Apply project conventions** — Use the project's existing design tokens, components, and patterns instead of hardcoded values
7. **Validate** — Compare the implemented UI against the Figma screenshot for visual parity

### SwiftUI → Figma

1. **Screenshot the running app first** — Before reading any code, capture a screenshot of the actual rendered UI from the simulator. Code alone cannot convey exact colors, opacity interactions, spacing feel, or visual weight. Use XcodeBuildMCP's `screenshot` tool (requires the app running in the simulator). This is the visual ground truth — everything else is verified against it.
2. **Read the SwiftUI code** — Understand the view hierarchy, modifiers, and layout intent. Read the styles/constants file too (e.g. `*Styles.swift`) for exact padding, corner radius, font sizes, and opacity values.
3. **Trace colors and icons to their source** — Never guess colors from variable names. Follow the full chain: view → data model/enum → theme token → design token → base palette value. A property named `trendColor` might resolve to `AppTheme.success.opacity(0.5)` → `green.400` → `hsl(113, 84%, 60%)`. Get the actual RGB values. Same for SF Symbol icon names — trace through enums and computed properties to find the exact `systemName` string.
4. **Map to Figma components** — Use the [Component Mapping](references/component-mapping.md) reference to find the corresponding Figma component names
5. **Search the design system** — Call `search_design_system` with the Figma component name to get the component key
6. **Create or update the design** — Use `use_figma` to build or modify frames in Figma, using library components where available
7. **Validate against the screenshot** — Compare the Figma output to the simulator screenshot captured in step 1. Iterate until they match.

## Quick Reference: Critical iOS 26 SwiftUI APIs

These APIs have **no equivalent in React/Tailwind** and require explicit knowledge to translate correctly from Figma designs:

| SwiftUI API | What It Does | Figma Component Name |
|-------------|--------------|---------------------|
| `.glassEffect()` | Applies Liquid Glass material (default: `.regular`, capsule shape) | "Liquid Glass - Regular - *" |
| `.glassEffect(.clear)` | Clear variant — media-rich backgrounds only | "Liquid Glass - Clear/Light" |
| `.glassEffect(.regular.interactive())` | Glass with touch/pointer reaction | Large touch targets |
| `.glassEffect(.regular.tint(.color))` | Tinted glass for prominence | Tinted Liquid Glass elements |
| `.buttonStyle(.glass)` | Liquid Glass button style | "Button - Liquid Glass - *" |
| `.buttonStyle(.glassProminent)` | Prominent glass button | Tinted/primary glass buttons |
| `GlassEffectContainer(spacing:)` | Combines glass shapes, enables morphing | Multiple adjacent glass elements |
| `.glassEffectID(_:in:)` | Unique ID for morph transitions | Animated glass transitions |
| `ToolbarSpacer(.fixed)` | Separates toolbar button groups | Separated toolbar item groups |
| `ToolbarSpacer(.flexible, placement:)` | Flexible space in toolbar | Spread-out toolbar items |
| `.tabBarMinimizeBehavior(.onScrollDown)` | Auto-hiding tab bar on scroll | Tab bar with receding behavior |
| `.scrollEdgeEffectStyle(_:for:)` | Content fade at scroll edges | "Scroll Edge Effect - *" |
| `.safeAreaBar(edge:content:)` | Custom bar with scroll edge | Custom navigation bars |
| `.backgroundExtensionEffect()` | Mirrors content under sidebar | Sidebar with blurred background |
| `ConcentricRectangle` | Hardware-aligned corner nesting | Nested rounded rectangles |

## Common Mistakes

1. **Treating `get_design_context` output as final code** — It's React + Tailwind. Always translate to SwiftUI using the reference tables. Never paste React JSX into a SwiftUI file.

2. **Hardcoding Figma pixel values** — Convert to SwiftUI layout: `width: FILL` → `.frame(maxWidth: .infinity)`, `itemSpacing: 12` → `VStack(spacing: 12)`, padding values → `.padding()`. Prefer project design tokens over literal numbers.

3. **Using `.glassEffect()` on content views** — Liquid Glass is for navigation and controls (tab bars, toolbars, sheets, buttons). Never apply to content areas, cards, or backgrounds. If the Figma design shows glass on content, it's likely a background material (`.ultraThinMaterial`) instead.

4. **Mixing `.regular` and `.clear` glass variants** — Apple explicitly forbids this. If a Figma design shows both, the "Clear/Light" component is for media-rich contexts only. Default to `.regular`.

5. **Missing `GlassEffectContainer`** — When multiple glass elements are adjacent, failing to wrap them in a container means no morph animation and degraded performance. If Figma shows grouped glass elements, use `GlassEffectContainer(spacing:)`.

6. **Ignoring `get_variable_defs`** — Skipping this tool means hardcoding colors instead of using the design's token system. Always call it when the Figma file uses variables.

7. **Searching Figma with SwiftUI names** — `search_design_system` uses Figma component names, not SwiftUI names. Search "Liquid Glass" not "glassEffect", "Row" not "List", "Segmented control" not "Picker(.segmented)".

8. **Forgetting backward compatibility** — If the project supports iOS 17/18 alongside iOS 26, wrap new APIs in `if #available(iOS 26, *)` guards. Figma shows the iOS 26 appearance; the code may need fallbacks.

9. **Skipping the simulator screenshot** — Translating SwiftUI → Figma from code alone consistently produces wrong results. Colors interact with opacity and backgrounds in ways that aren't obvious from reading code. A `cardOpacity: 0.25` looks completely different from `0.85`. Always screenshot the running app first.

10. **Guessing SF Symbol icons from context** — SF Symbols must be traced through the code. An icon labeled "trend" might use `chevron.up.2`, `arrow.up`, `chevron.up`, or `minus` depending on a computed property chain. Read the enum/model that produces the icon name, don't infer from the visual role.

11. **Using wrong SF Symbol approach in Figma** — The Apple iOS 26 Figma kit does NOT include usable SF Symbol glyphs (only size placeholders). Unicode codepoints via `String.fromCodePoint()` don't render in Figma's text engine. Hand-drawn vector paths are approximate. **The correct approach:** use the SF Symbol CLI (`tools/sf_symbol_cli.swift`) to export pixel-perfect SVGs from Apple's system asset catalog, then inject via `figma.createNodeFromSvg()`. See the [Figma MCP Workflow](references/figma-mcp-workflow.md) Step 4 for details.

## Prerequisites

- **Figma MCP server** connected at `https://mcp.figma.com/mcp`
- **iOS and iPadOS 26 (Community)** library enabled in the Figma file
- Target project using **SwiftUI** with **iOS 26+ SDK**
