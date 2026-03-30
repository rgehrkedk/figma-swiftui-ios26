# Figma MCP Workflow Reference

Optimal tool call sequences for translating between Figma designs and SwiftUI code using the Figma MCP server.

## Available MCP Tools

| Tool | Purpose | When to Use |
|---|---|---|
| `get_design_context` | Fetch design code + screenshot + hints for a node | **Primary tool** — always start here for Figma→Code |
| `get_screenshot` | Get a PNG screenshot of a node | Visual reference, validation, comparing output to design |
| `search_design_system` | Find components in connected Figma libraries | Code→Figma direction, finding the right component name |
| `get_variable_defs` | Fetch design token variables from a file | Mapping Figma tokens to project color/spacing/typography system |
| `get_metadata` | Get file structure and page list | Large files — find the right page/node before `get_design_context` |
| `get_code_connect_map` | Check existing Code Connect mappings | Skip translation if a mapping already exists |
| `get_code_connect_suggestions` | AI-suggested component mappings | Bootstrapping Code Connect for a project |
| `use_figma` | Create/modify Figma designs | Code→Figma: push designs back into Figma |
| `whoami` | Check authentication and quota | Verify access before starting work |

## Figma → SwiftUI Workflow

### Step 1: Get Design Context

Always start with `get_design_context`. This returns:
- **Code** (React + Tailwind by default)
- **Screenshot** (visual preview)
- **Hints** (Code Connect snippets, component docs, annotations, tokens)

```
Tool: get_design_context
Parameters:
  fileKey: "<from URL>"
  nodeId: "<from URL, convert '-' to ':'>"
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

### Step 1: Search for Matching Components

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

### Step 2: Get Component Details

Once you find the component, use `get_design_context` with its nodeId to get the full structure.

### Step 3: Create or Update in Figma

Use `use_figma` to create new designs or modify existing ones:

```
Tool: use_figma
Parameters:
  fileKey: "<target file>"
  updates: "<description of what to create/modify>"
```

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

## Rate Limits and Efficiency

### Quota

- **Organization Full seat**: 200 tool calls/day
- **Free/Viewer seat**: Lower limits

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
