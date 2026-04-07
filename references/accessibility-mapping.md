# Accessibility Mapping: Figma ↔ SwiftUI

Mapping between Figma design annotations/properties and SwiftUI accessibility APIs. Use this when translating designs to ensure accessible implementations, or when validating existing SwiftUI code against Figma specifications.

## Figma Annotations → SwiftUI Modifiers

| Figma Annotation / Property | SwiftUI Modifier | Notes |
|---|---|---|
| Alt text / description on image | `.accessibilityLabel("Description")` | Screen reader text for images |
| Tooltip / hint text | `.accessibilityHint("Double tap to open")` | Action hint for VoiceOver |
| "Heading" role annotation | `.accessibilityAddTraits(.isHeader)` | Marks section headers for navigation |
| "Button" role annotation | `.accessibilityAddTraits(.isButton)` | Already automatic on `Button` views |
| "Link" role annotation | `.accessibilityAddTraits(.isLink)` | Marks navigable links |
| Decorative image (no alt text) | `.accessibilityHidden(true)` | Hides from screen readers |
| Reading order annotation | `.accessibilitySortPriority(N)` | Higher N = read first |
| Group annotation | `.accessibilityElement(children: .combine)` | Combines children into single element |
| Custom action annotation | `.accessibilityAction(named: "Action") { }` | Custom VoiceOver action |
| Value indicator (progress, slider) | `.accessibilityValue("50 percent")` | Current value description |

## Dynamic Type Mapping

Figma text styles should map to SwiftUI semantic fonts that scale with Dynamic Type:

| Figma Text Style | SwiftUI Font | Default Size | Scales With Dynamic Type |
|---|---|---|---|
| Large Title | `.largeTitle` | 34pt | Yes |
| Title 1 | `.title` | 28pt | Yes |
| Title 2 | `.title2` | 22pt | Yes |
| Title 3 | `.title3` | 20pt | Yes |
| Headline | `.headline` | 17pt semibold | Yes |
| Body | `.body` | 17pt | Yes |
| Callout | `.callout` | 16pt | Yes |
| Subheadline | `.subheadline` | 15pt | Yes |
| Footnote | `.footnote` | 13pt | Yes |
| Caption 1 | `.caption` | 12pt | Yes |
| Caption 2 | `.caption2` | 11pt | Yes |

**Always prefer semantic fonts** (`.font(.body)`) over fixed sizes (`.font(.system(size: 17))`). Fixed sizes don't scale with Dynamic Type accessibility settings.

```swift
// GOOD — scales with Dynamic Type
Text("Content").font(.body)

// BAD — fixed size, doesn't respond to accessibility settings
Text("Content").font(.system(size: 17))
```

## Color Contrast

### Figma Design → SwiftUI Validation

Ensure text on glass has sufficient contrast in both states:

| Context | WCAG AA Requirement | Check |
|---|---|---|
| Body text on glass | 4.5:1 contrast ratio | Test with glass AND reduced transparency mode |
| Large text on glass (≥18pt) | 3:1 contrast ratio | Test with glass AND reduced transparency mode |
| Icons / UI controls | 3:1 contrast ratio | Test with glass AND reduced transparency mode |

### System Colors for Accessibility

| Figma Color Token | SwiftUI | Accessibility Behavior |
|---|---|---|
| Labels/Primary | `.foregroundStyle(.primary)` | Adjusts for light/dark/contrast modes |
| Labels/Secondary | `.foregroundStyle(.secondary)` | Reduced opacity, adjusts automatically |
| Labels/Tertiary | `.foregroundStyle(.tertiary)` | Further reduced, adjusts automatically |
| Fills/SystemFill | `Color(.systemFill)` | Adapts to all appearance modes |

**Prefer system semantic colors** — they automatically handle light mode, dark mode, increased contrast, and reduced transparency.

## iOS 26 Glass Effect Accessibility

Glass effects automatically respond to system accessibility settings:

| Accessibility Setting | Glass Behavior | Code Impact |
|---|---|---|
| **Reduce Transparency** | Glass becomes fully opaque | Layout must work without see-through. Test this mode. |
| **Increase Contrast** | Glass tint intensifies | Text contrast improves automatically |
| **Reduce Motion** | Morph transitions → cross-dissolve | No code change needed |
| **Bold Text** | Text on glass becomes bold | Ensure layout handles bolder/wider text |
| **Larger Text** | Dynamic Type scales text on glass | Ensure glass containers expand with content |

### Testing Checklist

When translating Figma glass designs to SwiftUI:

1. Enable "Reduce Transparency" in Settings → test layout without glass see-through
2. Enable "Increase Contrast" → verify text remains readable
3. Enable "Bold Text" → verify text doesn't clip or overflow
4. Set Dynamic Type to largest size → verify glass containers expand
5. Run VoiceOver → verify all interactive glass elements are labeled and reachable

## Touch Target Sizes

Figma component sizes should meet minimum touch target requirements:

| Guideline | Minimum Size | SwiftUI Implementation |
|---|---|---|
| Apple HIG | 44×44pt | `.frame(minWidth: 44, minHeight: 44)` |
| WCAG 2.2 AAA | 44×44 CSS px | Same as Apple HIG |
| Glass buttons (iOS 26) | Automatic | `.buttonStyle(.glass)` handles minimum sizing |

If a Figma design shows a touch target smaller than 44×44pt:

```swift
// Extend the tappable area without changing visual size
Button { } label: {
    Image(systemName: "xmark")
        .frame(width: 24, height: 24)
}
.frame(minWidth: 44, minHeight: 44)  // Accessible touch target
```

## VoiceOver Navigation

### Figma Layer Order → SwiftUI Reading Order

Figma's layer order (top to bottom in layers panel) maps to VoiceOver reading order in SwiftUI. If the Figma design has a specific reading order annotation:

```swift
// Override default reading order
VStack {
    headerView
        .accessibilitySortPriority(3)  // Read first
    mainContent
        .accessibilitySortPriority(2)  // Read second
    footerActions
        .accessibilitySortPriority(1)  // Read last
}
```

### Grouping Related Elements

When Figma shows a card or group that should be read as one unit:

```swift
// Combine card elements into single VoiceOver element
HStack {
    Image(systemName: "star.fill")
    VStack(alignment: .leading) {
        Text(title)
        Text(subtitle)
    }
}
.accessibilityElement(children: .combine)  // Read as one unit
```

### Ignoring Decorative Elements

When Figma marks an element as decorative (no alt text):

```swift
Image("decorative-pattern")
    .accessibilityHidden(true)  // Skip in VoiceOver
```

## Accessibility Validation with Figma Console MCP

If using [Figma Console MCP](mcp-ecosystem-guide.md), leverage its accessibility scanning:

1. **Design-side scanning**: 13 lint rules check Figma designs for accessibility issues (color contrast, touch targets, missing labels)
2. **Component scorecards**: Accessibility scores with color-blind simulation
3. **Code-side scanning**: axe-core integration (104 rules) for web implementations
4. **Design-code parity**: Verify accessibility annotations match code implementation

### Workflow

```
1. Translate Figma → SwiftUI using this skill
   ↓
2. Scan Figma design with Figma Console MCP accessibility tools
   ↓
3. Map findings to SwiftUI accessibility modifiers
   ↓
4. Add .accessibilityLabel(), .accessibilityHint(), etc.
   ↓
5. Test with VoiceOver and accessibility settings
```
