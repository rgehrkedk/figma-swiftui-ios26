# Figma ↔ SwiftUI Translation Skill (iOS 26)

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that translates between Figma designs and SwiftUI code for iOS 26+. It bridges the [Figma MCP server](https://mcp.figma.com/mcp) output (React + Tailwind) with native SwiftUI APIs — including Liquid Glass, toolbars, navigation, and controls.

Works bidirectionally: **Figma → SwiftUI** and **SwiftUI → Figma**.

## Why This Exists

The Figma MCP server fetches design data and returns **React + Tailwind code** by default. It knows nothing about SwiftUI — especially iOS 26-specific APIs like `.glassEffect()`, `.buttonStyle(.glass)`, `GlassEffectContainer`, or `ToolbarSpacer`. This skill provides the translation layer to turn Figma MCP output into correct, idiomatic SwiftUI and vice versa.

## What's Included

```
SKILL.md                              # Main skill definition (Claude Code reads this)
references/
  component-mapping.md                # Figma component ↔ SwiftUI view lookup table
  react-to-swiftui.md                 # React + Tailwind → SwiftUI translation rules
  property-mapping.md                 # Figma node properties → SwiftUI modifiers
  liquid-glass-translation.md         # Liquid Glass Figma ↔ .glassEffect() mapping
  figma-mcp-workflow.md               # All 16 MCP tools, workflows, Code Connect, Figma Make
  code-connect-swiftui.md             # Code Connect setup for SwiftUI (optimization layer)
  accessibility-mapping.md            # Figma annotations → SwiftUI accessibility modifiers
  mcp-ecosystem-guide.md              # Official vs third-party MCP server comparison
  figma-skills-integration.md         # Integration with Figma's 7 official MCP skills
tools/
  sf_symbol_cli.swift                 # Swift CLI for SF Symbol SVG extraction
  sf_symbol_svg.py                    # Cross-platform Python wrapper
  sf-symbol-svg.sh                    # Bash auto-compile wrapper
  symbol-cache/                       # Pre-cached SF Symbol SVGs
```

### Core Reference Files

| Reference | Purpose |
|-----------|---------|
| **Component Mapping** | Bidirectional lookup: Figma component name ↔ SwiftUI view/modifier (~80 components) |
| **React → SwiftUI** | Layout (Flexbox → Stacks), styling, components, animation, responsive patterns |
| **Property Mapping** | Figma auto-layout, fills, typography, effects → SwiftUI modifiers |
| **Liquid Glass** | Complete `.glassEffect()` API mapping, decision tree, when NOT to use glass |
| **Figma MCP Workflow** | All 16 MCP tools, Code Connect, Figma Make, Code-to-Canvas, rate limits |

### Extended Reference Files

| Reference | Purpose |
|-----------|---------|
| **Code Connect SwiftUI** | Set up Code Connect so `get_design_context` returns SwiftUI directly |
| **Accessibility Mapping** | Dynamic Type, VoiceOver, WCAG contrast, touch targets, glass a11y |
| **MCP Ecosystem Guide** | When to use official Figma MCP vs. Figma Console MCP vs. Figma-Context-MCP |
| **Figma Skills Integration** | How this skill extends Figma's 7 official MCP skills |

## Installation

### As a project skill (recommended)

Copy the skill into your project's `.claude/skills/` directory:

```bash
# From your project root
mkdir -p .claude/skills
git clone https://github.com/rgehrkedk/figma-swiftui-ios26.git .claude/skills/figma-swiftui-ios26
```

Claude Code automatically discovers skills in `.claude/skills/`.

### As a user-level skill

To make it available across all projects:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/rgehrkedk/figma-swiftui-ios26.git ~/.claude/skills/figma-swiftui-ios26
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or IDE extension
- [Figma MCP server](https://mcp.figma.com/mcp) connected (provides `get_design_context`, `search_design_system`, etc.)
- Apple's **iOS and iPadOS 26 (Community)** library enabled in your Figma file
- Xcode 26+ with iOS 26 SDK

## Usage

Once installed, the skill activates automatically when you ask Claude Code to translate between Figma and SwiftUI. Examples:

```
# Figma → SwiftUI
"Translate this Figma design to SwiftUI: https://figma.com/design/abc123/..."
"Convert this screen to SwiftUI using iOS 26 glass effects"

# SwiftUI → Figma
"Find the Figma component that matches this TabView code"
"What Figma component should I search for to represent a .glassEffect button?"
```

## Workflows

### Figma → SwiftUI

1. **Fetch** — `get_design_context` returns React + Tailwind code + screenshot
2. **Translate** — Skill converts React/Tailwind patterns to SwiftUI stacks, modifiers, and views
3. **Map iOS 26** — Identifies glass/blur patterns and maps to `.glassEffect()`, `.buttonStyle(.glass)`, etc.
4. **Apply tokens** — Replaces hardcoded values with your project's design system
5. **Validate** — Compares output against the Figma screenshot

### SwiftUI → Figma

1. **Read** — Understand the SwiftUI view hierarchy
2. **Map** — Find corresponding Figma component names using the component mapping table
3. **Search** — Call `search_design_system` with the Figma component name
4. **Create** — Use `use_figma` to build or modify the design, or paste into Figma's Code-to-Canvas

## iOS 26 APIs Covered

| SwiftUI API | Figma Component |
|-------------|----------------|
| `.glassEffect(.regular)` | Liquid Glass - Regular |
| `.glassEffect(.clear)` | Liquid Glass - Clear/Light |
| `.buttonStyle(.glass)` | Button - Liquid Glass |
| `GlassEffectContainer` | Grouped glass elements |
| `ToolbarSpacer(.fixed)` | Separated toolbar groups |
| `.tabBarMinimizeBehavior()` | Tab bar receding behavior |
| `.scrollEdgeEffectStyle()` | Scroll Edge Effect |
| `.safeAreaBar()` | Custom navigation bars |
| `ConcentricRectangle` | Nested rounded rectangles |

## Contributing

Contributions welcome. The reference files are the core value — if you find a missing Figma ↔ SwiftUI mapping, open a PR.

## License

MIT
