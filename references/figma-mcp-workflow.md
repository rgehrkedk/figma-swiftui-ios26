# Figma MCP Workflow Reference

Optimal tool call sequences for translating between Figma designs and SwiftUI code using the Figma MCP server.

## Available MCP Tools

### Read Tools

| Tool | Purpose | When to Use |
|---|---|---|
| `get_design_context` | Fetch design code + screenshot + hints for a node | **Primary tool** — always start here for Figma→Code |
| `get_screenshot` | Get a PNG screenshot of a node | Visual reference, validation, comparing output to design |
| `get_metadata` | Get sparse XML of selection (IDs, names, types, positions, sizes) | Large files — find the right page/node before `get_design_context` |
| `get_variable_defs` | Fetch design token variables from a file | Mapping Figma tokens to project color/spacing/typography system |
| `search_design_system` | Find components in connected Figma libraries | Code→Figma direction, finding the right component name |
| `get_code_connect_map` | Check existing Code Connect mappings | Skip translation if a mapping already exists |
| `get_code_connect_suggestions` | AI-suggested component mappings | Bootstrapping Code Connect for a project |
| `get_figjam` | Convert FigJam diagrams to XML with screenshots | Extracting diagrams, flowcharts, or planning boards |
| `whoami` | Check identity, plan, seat type, and quota (remote only) | Verify access before starting work |

### Write Tools

| Tool | Purpose | When to Use |
|---|---|---|
| `use_figma` | General-purpose: create/edit/delete any Figma object | Code→Figma: push designs back into Figma. Currently **free during beta** |
| `add_code_connect_map` | Create mappings between Figma nodes and code components | After translating a component — codify the mapping for future reuse |
| `send_code_connect_mappings` | Confirm mappings after `get_code_connect_suggestions` | Accepting AI-suggested Code Connect mappings |
| `create_design_system_rules` | Generate rules files for AI agent context | Encoding iOS 26 SwiftUI conventions so agents follow project patterns |
| `generate_figma_design` | Capture web pages/live UIs into Figma designs (remote only) | Validate simulator output by generating a Figma design from a live UI |
| `generate_diagram` | Create FigJam diagrams from Mermaid syntax | Architecture docs, flowcharts, state diagrams, sequence diagrams |
| `create_new_file` | Create blank Figma Design or FigJam file in drafts | Starting fresh SwiftUI→Figma workflows without an existing file |

## Figma → SwiftUI Workflow

### Step 1: Get Design Context

Always start with `get_design_context`. This returns:
- **Code** (React + Tailwind by default, or SwiftUI if Code Connect is configured)
- **Screenshot** (visual preview)
- **Hints** (Code Connect snippets, component docs, annotations, tokens)

```
Tool: get_design_context
Parameters:
  fileKey: "<from URL>"
  nodeId: "<from URL, convert '-' to ':'>"
  clientFrameworks: "SwiftUI"  // Optional (remote only) — filters Code Connect to SwiftUI mappings
```

**URL parsing rules:**
- `figma.com/design/:fileKey/:name?node-id=:nodeId` → `nodeId`: replace `-` with `:`
- `figma.com/design/:fileKey/branch/:branchKey/:name` → use `branchKey` as fileKey
- `figma.com/make/:makeFileKey/:name` → use `makeFileKey`

### Step 2: Assess the Response

The response quality varies depending on the Figma file's setup:

| Response Contains | Action |
|---|---|
| **Code Connect snippets** | Use the mapped codebase component directly — best case |
| **Component documentation links** | Follow docs for usage context and API |
| **Design annotations** | Follow embedded designer notes |
| **Design tokens as CSS variables** | Map to project's token system (see property-mapping.md) |
| **Raw hex colors / absolute positioning** | Design is loosely structured — lean on screenshot more |

### Step 3: Get Screenshot for Visual Validation

Always get a screenshot alongside the code output. The code may not capture all visual nuances.

```
Tool: get_screenshot
Parameters:
  fileKey: "<same as step 1>"
  nodeId: "<same as step 1>"
  format: "png"
```

### Step 4: Translate React+Tailwind → SwiftUI

Using the code output from Step 1, apply translations from:
1. **react-to-swiftui.md** — Layout, styling, component mapping
2. **property-mapping.md** — Figma node properties → SwiftUI modifiers
3. **liquid-glass-translation.md** — Glass-specific translations

**Key decision points during translation:**

1. Check for iOS 26 glass indicators (backdrop-blur, translucent backgrounds, frosted appearance)
   → Use `.glassEffect()` / `.buttonStyle(.glass)` instead of `.background(.material)`

2. Check if it's a standard control (Button, Toggle, Tab, etc.)
   → Use standard SwiftUI control — glass is automatic on iOS 26

3. Check for existing project components that match the design intent
   → Reuse project components instead of generating new code

### Step 5: Validate Against Screenshot

Compare your SwiftUI output to the screenshot from Step 3. Common discrepancies:
- Spacing/padding values that need adjustment
- Color tokens that should map to project theme instead of hardcoded values
- Glass effects missing from standard controls (they're automatic — don't add them)
- Typography that should use Dynamic Type instead of fixed sizes

## SwiftUI → Figma Workflow

### Step 0: Screenshot the Running App (MANDATORY)

Before reading any code, capture a screenshot of the actual rendered UI from the simulator. This is the visual ground truth — code alone cannot convey exact colors (which interact with opacity and backgrounds), spacing feel, or visual weight.

Use XcodeBuildMCP tools if available:
1. `session_show_defaults` — verify simulator is configured
2. `build_run_sim` — build and launch the app
3. `tap` (label: "...") — navigate to the target screen using accessibility labels
4. `screenshot` (returnFormat: "base64") — capture the screen

If the target screen requires navigation (login, tab switches), use the `tap` tool with the element's accessibility label. Use `snapshot_ui` to discover available labels and coordinates if a label-based tap fails.

### Step 1: Read the Code Carefully

Read the SwiftUI view file AND its associated styles/constants file. Pay attention to:
- **Layout constants** — exact padding, corner radius, spacing, height values
- **Opacity values** — these dramatically affect visual appearance (0.25 vs 0.85 look completely different)
- **Font specs** — `.callout.weight(.semibold)` = 16pt semibold, `.caption2.weight(.bold)` = 11pt bold, etc.

### Step 2: Trace Colors and Icons to Source

Never guess colors from variable names. Follow the full resolution chain:

```
View: .foregroundStyle(trend.direction.trendColor)
  → TrendDirection enum: case .strongUp → AppTheme.success
    → Theme.swift: static let success = GeneratedColors.success
      → SemanticColors.swift: Color("Success")
        → theme.dark.json: "success": { "$value": "{green.400}" }
          → base.json: "green.400": "hsl(113 84% 60%)"
            → RGB: (0.22, 0.93, 0.17)
```

Do the same for SF Symbol icon names — trace through computed properties and enums:

```
View: Image(systemName: trend.iconName)
  → CardTrendResult.iconName → direction.iconName
    → TrendDirection.iconName: case .strongUp → "chevron.up.2"
```

### Step 3: Search for Matching Figma Components

Use `search_design_system` to find the Figma component that matches your SwiftUI view.

```
Tool: search_design_system
Parameters:
  searchTerm: "<component name or description>"
```

**Search term mapping** (SwiftUI → Figma search terms):

| SwiftUI Code | Search Term |
|---|---|
| `Button { }.buttonStyle(.glass)` | `"Button Liquid Glass"` |
| `TabView { }` | `"Tab Bar"` |
| `.toolbar { }` | `"Navigation Bar"` or `"Toolbar"` |
| `Toggle(isOn:)` | `"Toggle"` or `"Switch"` |
| `List { }` | `"Table"` or `"List"` |
| `.alert()` | `"Alert"` |
| `.sheet {}` | `"Sheet"` or `"Modal"` |
| `Picker { }.pickerStyle(.segmented)` | `"Segmented Control"` |
| `.contextMenu { }` | `"Menu"` |
| `NavigationSplitView` | `"Sidebar"` |
| Empty state view | `"Empty State"` |

See component-mapping.md "Reverse Lookup" section for the complete mapping.

### Step 4: Handle SF Symbols

The Apple iOS 26 Figma kit does NOT include standalone SF Symbol glyphs. The "Icons - Symbols" component set contains only size placeholders. **Use the SF Symbol CLI to export pixel-perfect vector SVGs, then inject via `figma.createNodeFromSvg()`.**

#### SF Symbol CLI Tool

A self-contained tool at `tools/sf-symbol-svg.sh` (in this skill directory) extracts exact Apple vector outlines from the system asset catalog. It auto-compiles on first use — no setup needed. Requires macOS 14+ and Xcode Command Line Tools.

**Export SVG:**
```bash
.claude/skills/figma-swiftui-ios26/tools/sf-symbol-svg.sh export chevron.right --weight bold --size 24
.claude/skills/figma-swiftui-ios26/tools/sf-symbol-svg.sh export chevron.up.2 --weight bold --size 24
```

**Search symbols:**
```bash
.claude/skills/figma-swiftui-ios26/tools/sf-symbol-svg.sh search chevron
.claude/skills/figma-swiftui-ios26/tools/sf-symbol-svg.sh info star.fill
```

**Weight options:** `ultralight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, `black` — match to the SwiftUI font weight context.

#### Cross-Platform Python Wrapper

`tools/sf_symbol_svg.py` wraps the CLI with fallback to pre-cached SVGs. Works on any OS with Python 3 — on macOS it auto-compiles and uses the Swift CLI for pixel-perfect results; elsewhere it uses `tools/symbol-cache/` (common symbols pre-exported at regular weight).

**Quick export for Figma (generates ready-to-paste JS):**
```bash
python3 .claude/skills/figma-swiftui-ios26/tools/sf_symbol_svg.py \
  export-for-figma chevron.up.2 --weight bold \
  --display-width 11 --display-height 12 --color "#38ED2B"
```

This outputs a JSON with a `js` field containing a complete `figma.createNodeFromSvg()` snippet — just paste it into `use_figma` code.

#### Inject into Figma

Use `figma.createNodeFromSvg()` in `use_figma` with the CLI output:

```javascript
// 1. Get SVG string from CLI output (or embed directly)
const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="7" height="11" 
  viewBox="-0.00 0.00 20.32 34.14">
  <path d="M20.32 17.07C20.31 18.06..." fill="currentColor"/>
</svg>`;

// 2. Create node from SVG
const node = figma.createNodeFromSvg(svg);
node.name = "chevron.right";

// 3. Resize to match the SwiftUI font size context
// .caption2.bold() ≈ 11pt → roughly 7x11px for chevron.right
node.resize(7, 11);

// 4. Recolor — SVG imports as black, change fills on the vector child
const vectors = node.findAll(n => n.type === "VECTOR");
for (const v of vectors) {
  v.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 }, opacity: 0.18 }];
}

// 5. Append to parent auto-layout frame
parentFrame.appendChild(node);
```

**Important notes:**
- Set `width` and `height` in the SVG tag to the desired display size (not the original export size) — the `viewBox` preserves the path proportions
- The CLI `--weight` flag maps to SwiftUI font weights: `regular`, `medium`, `semibold`, `bold`, `heavy`, `black`
- Match the weight to the SwiftUI icon context (e.g., `.caption2.bold()` → `--weight bold`)
- The CLI requires macOS 14+ with SF Symbols installed
- Caveats: uses CoreUI private API — works on macOS 14/15/26 but could change in future OS versions

#### What does NOT work

| Approach | Problem |
|---|---|
| Unicode codepoints as text (`String.fromCodePoint()`) | Figma's text renderer doesn't display SF Pro PUA characters (U+100000+) when inserted via Plugin API |
| Apple iOS 26 Figma kit "Icons - Symbols" | Only contains size placeholders, not actual glyphs |
| Copy-paste from SF Symbols Mac app | Works visually but is manual, not automatable from `use_figma` |
| npm packages with SF Symbol SVGs | Apple copyright violation risk |

### Step 5: Create or Update in Figma

Use `use_figma` to create new designs or modify existing ones. Build the Figma frame hierarchy to mirror the SwiftUI view hierarchy — each `VStack`/`HStack` becomes a Figma auto-layout frame.

### Step 6: Validate Against Screenshot

Compare the Figma output to the simulator screenshot from Step 0. Common discrepancies:
- Card opacity too high/low (check the styles file for exact values)
- Wrong accent color (trace through theme tokens)
- Wrong icon (trace through enum computed properties)
- Spacing doesn't match (check layout constants file)

## Design Token Workflow

### Extracting Tokens

```
Tool: get_variable_defs
Parameters:
  fileKey: "<file with design system>"
```

Returns variable collections (colors, spacing, typography) with:
- Variable names (e.g., `Colors/Primary`, `Spacing/Medium`)
- Values per mode (Light/Dark)
- Aliases (variable references to other variables)

### Mapping to Project Tokens

1. Compare Figma variable names to project's token system
2. Map semantic names: `Colors/Background/Primary` → `Color(.systemBackground)`
3. Map spacing scales: `Spacing/16` → project's spacing constants
4. For custom tokens: create project-level constants that reference Figma's semantic naming

## Handling Large Designs

### Many Pages / Complex Files

```
Tool: get_metadata
Parameters:
  fileKey: "<fileKey>"
```

This returns the file's page structure and top-level nodes. Use it to:
- Find the correct page before calling `get_design_context`
- Identify specific screens or components by name
- Get nodeIds for deeply nested elements

### Component Instances vs Main Components

When `get_design_context` returns a component instance:
- The response includes the main component's properties and variants
- Check if a Code Connect mapping exists for the main component
- Variant properties (e.g., `State=Pressed`, `Size=Large`) map to SwiftUI modifiers

## Figma Plugin API Gotchas (`use_figma`)

When writing JavaScript for `use_figma`, these are common errors and how to avoid them:

### Font Loading

Figma requires exact `{ family, style }` pairs. Names vary per font installation — never guess.

```javascript
// BAD — "SF Pro Text" and "SemiBold" are wrong on most systems
await figma.loadFontAsync({ family: "SF Pro Text", style: "SemiBold" });

// GOOD — discover first, then use exact names
const fonts = await figma.listAvailableFontsAsync();
const sfFonts = fonts.filter(f => f.fontName.family.startsWith("SF Pro"));
// Common correct names: "SF Pro" (not "SF Pro Text"), "Semi Bold" (with space for Inter)
await figma.loadFontAsync({ family: "SF Pro", style: "Semibold" });
await figma.loadFontAsync({ family: "SF Pro Rounded", style: "Bold" });
```

**Rule:** Always call `figma.listAvailableFontsAsync()` and check exact family/style strings before loading fonts. Font names differ between macOS, Windows, and Figma's cloud rendering.

### Auto-Layout Sizing

`layoutSizingHorizontal = "FILL"` and `layoutSizingVertical = "FILL"` can only be set on nodes that are **already children** of an auto-layout frame. Setting them before `appendChild` throws.

```javascript
// BAD — setting FILL before the node is a child of an auto-layout parent
const child = figma.createFrame();
child.layoutSizingHorizontal = "FILL"; // ERROR: not a child of auto-layout frame
parent.appendChild(child);

// GOOD — add to parent first, then set sizing
const child = figma.createFrame();
parent.appendChild(child);
child.layoutSizingHorizontal = "FILL"; // Works — now it's a child of auto-layout parent
```

### counterAxisSizingMode vs layoutSizing

`counterAxisSizingMode` only accepts `"FIXED"` or `"AUTO"`. To make a child fill its parent's cross-axis, use `layoutSizingHorizontal`/`layoutSizingVertical` on the **child** after appending it.

```javascript
// BAD — "FILL_CONTAINER" is not a valid enum value for counterAxisSizingMode
frame.counterAxisSizingMode = "FILL_CONTAINER"; // ERROR

// GOOD — set on the child after appending
parent.appendChild(frame);
frame.layoutSizingHorizontal = "FILL";
```

### Frame Properties Are Not Extensible

Figma nodes are sealed objects. You cannot assign arbitrary properties (like `.fontSize` on a Frame). Only set properties that exist on the node type.

```javascript
// BAD — frames don't have fontSize
const header = figma.createFrame();
header.fontSize = 13; // TypeError: object is not extensible

// GOOD — fontSize goes on Text nodes only
const text = figma.createText();
text.fontSize = 13;
```

### Operation Order Summary

1. Create the frame/node
2. Set intrinsic properties (`resize`, `fills`, `cornerRadius`, `layoutMode`, `paddingTop`, etc.)
3. `appendChild` to parent
4. Set parent-dependent properties (`layoutSizingHorizontal = "FILL"`, `layoutSizingVertical = "FILL"`)

## Rate Limits and Efficiency

### Quota

- **Dev/Full seats** (Professional/Organization/Enterprise): Per-minute limits matching Figma REST API Tier 1
- **Starter/View/Collab seats**: Maximum **6 tool calls per month**
- **Write operations** (`use_figma`, `add_code_connect_map`, etc.): Currently **exempt from rate limits** during beta — will become usage-based paid
- Use `whoami` (remote only) to check your current plan, seat type, and remaining quota

### Optimization Tips

1. **Batch context requests** — Get multiple related nodes in fewer calls by targeting a parent frame
2. **Use `get_metadata` first** for unfamiliar files — avoids wasting calls on wrong nodes
3. **Cache `search_design_system` results** — component names don't change frequently
4. **Skip `get_screenshot`** when `get_design_context` code output is clearly structured
5. **Check `get_code_connect_map` first** — if mappings exist, no translation needed

### Error Handling

| Error | Cause | Fix |
|---|---|---|
| Node not found | Wrong nodeId format | Convert `-` to `:` in URL nodeId |
| Rate limit exceeded | Too many calls | Wait, batch requests, use cached results |
| Empty code output | Node is too simple (single icon/shape) | Use `get_screenshot` instead, implement manually |
| Partial code output | Node is very complex | Break into child nodes, call per-section |

## MCP Output Interpretation

### Understanding Code Connect Hints

When the response includes Code Connect data, it means the Figma component has been manually mapped to codebase components:

```
// Code Connect hint in response:
// → Use ProjectButton(style: .glass, title: "Action")
```

**Always prefer Code Connect hints over raw translation** — they reflect the project's actual API.

### Understanding Annotations

Designer annotations appear as notes attached to nodes:
- Spacing/layout constraints
- Interaction behavior descriptions
- Implementation notes

**Always follow annotations** — they contain designer intent that isn't captured in the visual output.

### Asset URLs

`get_design_context` may return localhost URLs for images/icons. These are:
- Temporary URLs valid during the MCP session
- Suitable for preview but not production
- Extract and add assets to the project's asset catalog for production use

## Code Connect Workflow

Code Connect maps Figma components directly to your SwiftUI code. Once set up, `get_design_context` returns your actual SwiftUI snippets instead of React+Tailwind — eliminating the translation step for mapped components.

### Setting Up Code Connect for SwiftUI

See [Code Connect SwiftUI Reference](code-connect-swiftui.md) for full setup details. Summary:

1. Add `@figma/code-connect` as a Swift Package dependency
2. Create `FigmaConnect` structs that map Figma component properties to SwiftUI views
3. Use `add_code_connect_map` to register mappings via MCP
4. On the remote server, set `clientFrameworks: "SwiftUI"` to filter mappings

### Acceleration Loop

Code Connect works best as an optimization layer after initial translations:

1. **Translate** a Figma component to SwiftUI using this skill's reference tables
2. **Verify** the translation is correct (visual parity with screenshot)
3. **Codify** the mapping as a `FigmaConnect` struct in your Xcode project
4. **Register** via `add_code_connect_map` so future translations of the same component are automatic

```
Tool: add_code_connect_map
Parameters:
  fileKey: "<fileKey>"
  nodeId: "<component nodeId>"
  // Maps the component to your SwiftUI implementation
```

### Checking Existing Mappings

Always check for Code Connect mappings before translating:

```
Tool: get_code_connect_map
Parameters:
  fileKey: "<fileKey>"
  nodeId: "<nodeId>"
  clientFrameworks: "SwiftUI"  // Filter to SwiftUI mappings (remote only)
```

If mappings exist, use them directly — they reflect the project's actual API and are more accurate than a fresh translation.

## Design System Rules

Use `create_design_system_rules` to generate a rules file that teaches AI agents your project's iOS 26 SwiftUI conventions. This reduces repetitive prompting and ensures consistent output.

### Creating Rules for iOS 26 SwiftUI Projects

```
Tool: create_design_system_rules
```

When prompted, specify conventions like:
- Use `.glassEffect()` for navigation chrome, never for content areas
- Prefer `.buttonStyle(.glass)` over manual glass modifiers on buttons
- Use `GlassEffectContainer(spacing:)` when multiple glass elements are adjacent
- Prefer Dynamic Type (`.font(.headline)`) over fixed font sizes
- Map Figma design tokens to project's `AppTheme` constants
- Standard controls (Toggle, Slider, Stepper) get glass automatically on iOS 26 — don't add `.glassEffect()`

The generated rules file should be saved to your project's `rules/` or `.cursor/rules/` directory.

## FigJam Workflows

### Reading FigJam Boards

```
Tool: get_figjam
Parameters:
  fileKey: "<fileKey>"
  nodeId: "<nodeId>"
```

Returns XML metadata with screenshots of FigJam elements. Useful for extracting flowcharts, user journeys, or architectural diagrams that inform SwiftUI implementation.

### Generating Diagrams

```
Tool: generate_diagram
Parameters:
  // Describe the diagram in natural language — the agent generates Mermaid syntax
```

Supported diagram types: flowchart, Gantt chart, state diagram, sequence diagram. Useful for documenting SwiftUI view hierarchies or navigation flows as FigJam diagrams.

## New File Creation

```
Tool: create_new_file
```

Creates a blank Figma Design or FigJam file in the authenticated user's drafts. Use this when starting a SwiftUI→Figma workflow without an existing target file. If the user belongs to multiple plans, it will prompt for team/organization selection.

## Capturing Live UIs into Figma

```
Tool: generate_figma_design
// Remote MCP server only
```

Captures web pages or live UIs into native Figma designs. For SwiftUI workflows, this can be used to:
- Generate a Figma representation from a running web preview of your app
- Compare captured output against existing Figma designs
- Bootstrap a Figma file from an existing implementation

**Limitations:** Remote server only, select MCP clients, exempt from standard rate limits.

## Figma Make Integration

Figma Make is an AI app builder that creates working prototypes from natural language prompts. These prototypes can be used as input for SwiftUI translation.

### Figma Make → SwiftUI Workflow

```
1. Create prototype in Figma Make (prompt → working UI)
   ↓
2. Get the Make file URL: figma.com/make/:makeFileKey/:name
   ↓
3. Call get_design_context with makeFileKey as fileKey
   ↓
4. Translate the React+Tailwind output to SwiftUI using this skill
   ↓
5. Apply iOS 26 patterns (glass effects, controls, navigation)
```

Make files use the same `get_design_context` tool — use the `makeFileKey` from the URL as the `fileKey` parameter.

### When to Use Figma Make as Input

- **Rapid prototyping**: Describe a screen in natural language → get a prototype → translate to native SwiftUI
- **Exploring layouts**: Generate multiple layout variations quickly → pick the best → translate
- **Stakeholder mockups**: Build a quick interactive demo → then implement in SwiftUI with proper APIs

## Code-to-Canvas (SwiftUI → Figma)

Figma's Code-to-Canvas feature accepts code (React, HTML, or SwiftUI) and generates an editable Figma component. This is a faster alternative to manually building Figma frames via `use_figma`.

### Code-to-Canvas Workflow

```
1. Write or refine SwiftUI code
   ↓
2. Paste into Figma's Code-to-Canvas feature
   ↓
3. Figma generates an editable component on the canvas
   ↓
4. Refine in Figma (adjust spacing, colors, add design tokens)
   ↓
5. Optionally re-export via get_design_context to verify round-trip
```

### When Code-to-Canvas Is Better Than `use_figma`

| Approach | Best For |
|----------|---------|
| **Code-to-Canvas** | Quick one-shot conversion, visual refinement in Figma, design handoff |
| **`use_figma`** | Programmatic creation, batch operations, precise control, automation |
| **Combined** | Code-to-Canvas for initial structure → `use_figma` for refinements and SF Symbol injection |

### Limitations

- Code-to-Canvas works best with simple, self-contained components
- Complex SwiftUI (navigation stacks, sheets, state management) may not translate fully
- Design tokens and variables need manual connection after generation
- SF Symbols still require the CLI tool for pixel-perfect injection
