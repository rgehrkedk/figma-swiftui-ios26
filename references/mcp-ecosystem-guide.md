# MCP Ecosystem Guide

When to use the official Figma MCP server vs. third-party alternatives, and how to combine them for iOS 26 SwiftUI workflows.

## Server Comparison

| | Official Figma MCP | Figma Console MCP | Figma-Context-MCP |
|---|---|---|---|
| **Maintainer** | Figma | Southleft (open source) | GLips (open source) |
| **GitHub Stars** | Official product | 1.4k+ | 14k+ |
| **Tool Count** | 16 | 94+ (NPX) / 43 (cloud) / 22 (SSE) | ~3 |
| **Auth** | OAuth (integrated into MCP clients) | PAT or OAuth | PAT |
| **Write Access** | Yes (`use_figma`, free during beta) | Yes (via Desktop Bridge Plugin) | No (read-only) |
| **Code Connect** | Yes (native) | No | No |
| **Design Tokens** | Read via `get_variable_defs` | Full CRUD (create, update, rename, delete) | No |
| **Accessibility** | No | Yes (WCAG scanning, 13 lint rules, axe-core) | No |
| **FigJam** | Read + diagram generation | Full manipulation (stickies, flowcharts, tables) | No |
| **Plugin Debug** | No | Yes (console log capture) | No |
| **AI Token Efficiency** | Medium (full API responses) | Medium | High (strips irrelevant data) |
| **Best For** | Production design-to-code, Code Connect, canvas writing | Accessibility, token management, plugin dev | Quick prototyping, one-shot generation |

## When to Use Each

### Official Figma MCP (recommended default)

**Always use for:**
- Fetching design context (`get_design_context`) — the primary Figma→SwiftUI input
- Writing to canvas (`use_figma`) — the primary SwiftUI→Figma output
- Code Connect setup and management
- Design system rules generation
- Screenshot capture for validation
- Searching design system libraries

**Rate limits:**
- Dev/Full seats: per-minute (Tier 1 API)
- Starter/View/Collab: 6 calls/month
- Write operations: exempt during beta

**Endpoint:** `https://mcp.figma.com/mcp` (remote, recommended) or `http://127.0.0.1:3845/mcp` (desktop)

### Figma Console MCP (southleft)

**Use for:**
- **Accessibility scanning** after translating Figma→SwiftUI — validates WCAG compliance with 13 design-side lint rules, component scorecards, and color-blind simulation
- **Design token management** — create, update, rename, and delete variables on Free and Pro plans (official MCP only reads tokens)
- **Plugin debugging** — capture console logs when building Figma plugins
- **FigJam automation** — create stickies, flowcharts, tables programmatically
- **Real-time monitoring** — track selection changes and document updates (NPX mode only)

**Setup (NPX — full capabilities):**
```json
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "figd_YOUR_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
```

Requires importing the Desktop Bridge Plugin in Figma Desktop for write access.

**Setup (Cloud — no Node.js needed):**
Add MCP endpoint `https://figma-console-mcp.southleft.com/mcp` with Bearer token auth. Open the Desktop Bridge plugin in Figma Desktop, then tell the AI to "Connect to my Figma plugin" to receive a pairing code.

**Setup (SSE — read-only, quick evaluation):**
URL: `https://figma-console-mcp.southleft.com/sse` — OAuth authenticates automatically on first use.

### Figma-Context-MCP (GLips)

**Use for:**
- **Quick prototyping** when AI token budget is tight — strips irrelevant Figma API data and provides only layout/styling info
- **One-shot code generation** — optimized context produces better single-attempt results than raw Figma API responses
- **Framework-agnostic workflows** — works with any framework, not tied to Code Connect

**Setup:**
```json
{
  "mcpServers": {
    "figma-context": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/figma-context-mcp@latest", "--stdio"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "figd_YOUR_TOKEN"
      }
    }
  }
}
```

**Limitations:** Read-only, no write access, no Code Connect support, no design token extraction.

## Complementary Workflows

### Workflow 1: Full iOS 26 Design-to-Code Pipeline

```
Official Figma MCP                          This Skill
──────────────────                          ──────────
get_design_context(clientFrameworks: "SwiftUI")
  → Code Connect hints or React+Tailwind
                                            → Translate to SwiftUI using reference tables
                                            → Apply iOS 26 glass effects
get_screenshot → visual reference
                                            → Validate visual parity
get_variable_defs → design tokens
                                            → Map to project's AppTheme tokens
add_code_connect_map
  → Codify mapping for future reuse
```

### Workflow 2: Accessibility Validation

```
Official Figma MCP                          Figma Console MCP
──────────────────                          ─────────────────
get_design_context → SwiftUI translation
                                            → Scan design for WCAG violations
                                            → Check color contrast ratios
                                            → Run color-blind simulation
                                            → Verify component accessibility scores
                                            → Map findings to SwiftUI:
                                              .accessibilityLabel()
                                              .accessibilityHint()
                                              .accessibilityAddTraits()
```

### Workflow 3: Design Token Sync

```
Official Figma MCP                          Figma Console MCP
──────────────────                          ─────────────────
get_variable_defs → read current tokens
                                            → Create/update/rename tokens
                                            → Sync with SwiftUI AppTheme
                                            → Works on Free/Pro plans
```

### Workflow 4: Quick Prototyping

```
Figma-Context-MCP                           This Skill
─────────────────                           ──────────
Simplified design context (token-efficient)
                                            → One-shot SwiftUI translation
                                            → Fast iteration, less token usage
                                            → Trade-off: no Code Connect, no write
```

## Running Multiple MCP Servers

Claude Code supports multiple MCP servers simultaneously. Add all servers to your MCP configuration:

```json
{
  "mcpServers": {
    "figma": {
      "type": "streamableHttp",
      "url": "https://mcp.figma.com/mcp"
    },
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "figd_YOUR_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
```

When tools have similar names across servers, prefix with the server name in your prompts (e.g., "use the official Figma MCP's `get_design_context`").

## Decision Matrix

| Task | Server to Use |
|------|--------------|
| Fetch design for SwiftUI translation | Official Figma MCP |
| Write SwiftUI component back to Figma | Official Figma MCP (`use_figma`) |
| Set up Code Connect mappings | Official Figma MCP |
| Check accessibility compliance | Figma Console MCP |
| Create/update design tokens | Figma Console MCP |
| Quick one-shot prototype | Figma-Context-MCP |
| Debug a Figma plugin | Figma Console MCP |
| Generate FigJam diagrams | Official Figma MCP (`generate_diagram`) |
| Automate FigJam stickies/tables | Figma Console MCP |
| Generate design system rules | Official Figma MCP (`create_design_system_rules`) |
