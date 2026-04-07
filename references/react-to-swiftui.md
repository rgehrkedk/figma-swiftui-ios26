# React + Tailwind → SwiftUI Translation

The Figma MCP `get_design_context` tool outputs **React + Tailwind** by default. This is a structured representation of the design, not final code. This reference provides systematic translation rules.

## Core Principle

React + Tailwind output describes **layout intent and visual properties**. SwiftUI implements the same intent through a fundamentally different paradigm (declarative views with modifiers). Translate the *intent*, don't transliterate the syntax.

## Layout Translation

### Flexbox → Stacks

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `<div className="flex flex-col">` | `VStack { }` | Vertical stack |
| `<div className="flex flex-row">` | `HStack { }` | Horizontal stack |
| `<div className="flex flex-col items-center">` | `VStack { }.frame(maxWidth: .infinity)` | Centered children |
| `<div className="flex flex-row justify-between">` | `HStack { Spacer() /* between items */ }` | Space-between layout |
| `<div className="flex flex-row justify-center">` | `HStack { }.frame(maxWidth: .infinity)` | Centered horizontal |
| `<div className="flex flex-wrap">` | `LazyVGrid(columns: [...]) { }` or custom `FlowLayout` | Wrapping grid |
| `<div className="flex-1">` | `.frame(maxWidth: .infinity)` or `.layoutPriority(1)` | Flexible growth |
| `<div className="grid grid-cols-3">` | `LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3))` | CSS Grid → LazyVGrid |
| `<div style={{ position: 'absolute' }}>` | `ZStack { }.overlay { }` or `.position(x:y:)` | Absolute positioning → ZStack/overlay |
| `<div className="relative">` | `ZStack { }` | Positioning context |

### Gap & Spacing

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `gap-2` (8px) | `VStack(spacing: 8)` or `HStack(spacing: 8)` | Stack spacing |
| `gap-x-4 gap-y-2` | `LazyVGrid(columns: [...], spacing: 8) { }` with `.padding(.horizontal, 16)` | Asymmetric grid spacing |
| `space-x-4` | `HStack(spacing: 16) { }` | Horizontal spacing between children |

### Sizing

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `w-full` | `.frame(maxWidth: .infinity)` | Full width |
| `h-full` | `.frame(maxHeight: .infinity)` | Full height |
| `w-[200px]` | `.frame(width: 200)` | Fixed width |
| `h-[44px]` | `.frame(height: 44)` | Fixed height |
| `min-w-[100px]` | `.frame(minWidth: 100)` | Minimum width |
| `max-w-[400px]` | `.frame(maxWidth: 400)` | Maximum width |
| `aspect-square` | `.aspectRatio(1, contentMode: .fit)` | 1:1 aspect ratio |
| `aspect-video` | `.aspectRatio(16/9, contentMode: .fit)` | 16:9 aspect ratio |
| `overflow-hidden` | `.clipped()` | Clip overflow |
| `overflow-scroll` | `ScrollView { }` | Scrollable container |

### Padding

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `p-4` (16px) | `.padding(16)` | All sides |
| `px-4` | `.padding(.horizontal, 16)` | Horizontal only |
| `py-2` | `.padding(.vertical, 8)` | Vertical only |
| `pt-4` | `.padding(.top, 16)` | Top only |
| `pb-2 px-4` | `.padding(.bottom, 8).padding(.horizontal, 16)` | Mixed padding |

**Tailwind spacing scale**: `1` = 4px, `2` = 8px, `3` = 12px, `4` = 16px, `5` = 20px, `6` = 24px, `8` = 32px

## Visual Properties

### Colors

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `text-white` | `.foregroundStyle(.white)` | White text |
| `text-gray-500` | `.foregroundStyle(.secondary)` | System secondary |
| `text-black/60` | `.foregroundStyle(.primary.opacity(0.6))` | Semi-transparent |
| `bg-white` | `.background(.white)` | White background |
| `bg-black/20` | `.background(.black.opacity(0.2))` | Semi-transparent black |
| `bg-blue-500` | `.background(.blue)` | System blue |
| `bg-gradient-to-b from-X to-Y` | `.background(LinearGradient(colors: [X, Y], startPoint: .top, endPoint: .bottom))` | Vertical gradient |
| `rgba(R, G, B, A)` | `Color(red: R/255, green: G/255, blue: B/255).opacity(A)` | Custom RGBA color |

**Prefer project tokens** over literal colors: `AppTheme.primary` over `Color(red: 0.4, ...)`.

### Typography

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `text-xs` (12px) | `.font(.caption2)` | Extra small |
| `text-sm` (14px) | `.font(.caption)` | Small |
| `text-base` (16px) | `.font(.body)` | Base/body |
| `text-lg` (18px) | `.font(.headline)` | Large |
| `text-xl` (20px) | `.font(.title3)` | Extra large |
| `text-2xl` (24px) | `.font(.title2)` | 2X large |
| `text-3xl` (30px) | `.font(.title)` | 3X large |
| `text-4xl` (36px) | `.font(.largeTitle)` | 4X large |
| `font-bold` | `.fontWeight(.bold)` | Bold weight |
| `font-semibold` | `.fontWeight(.semibold)` | Semibold weight |
| `font-medium` | `.fontWeight(.medium)` | Medium weight |
| `text-center` | `.multilineTextAlignment(.center)` | Centered text |
| `line-clamp-2` | `.lineLimit(2)` | Max 2 lines |
| `truncate` | `.lineLimit(1).truncationMode(.tail)` | Single line truncation |
| `uppercase` | `.textCase(.uppercase)` | Uppercase transform |

**Prefer Dynamic Type**: Use `.font(.body)` over `.font(.system(size: 16))` unless exact sizing is critical.

### Borders & Shapes

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `rounded-lg` (8px) | `.clipShape(RoundedRectangle(cornerRadius: 8))` | Rounded corners |
| `rounded-xl` (12px) | `.clipShape(RoundedRectangle(cornerRadius: 12))` | Larger radius |
| `rounded-2xl` (16px) | `.clipShape(RoundedRectangle(cornerRadius: 16))` | 16pt radius |
| `rounded-full` | `.clipShape(Capsule())` or `.clipShape(Circle())` | Pill or circle |
| `border border-gray-200` | `.overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))` | Border stroke |
| `border-b` | `Divider()` below the element | Bottom border → Divider |
| `ring-2 ring-blue-500` | `.overlay(RoundedRectangle(cornerRadius: 8).stroke(.blue, lineWidth: 2))` | Focus ring |

### Shadows & Effects

| React/Tailwind | SwiftUI | Notes |
|---|---|---|
| `shadow-sm` | `.shadow(color: .black.opacity(0.05), radius: 2, y: 1)` | Small shadow |
| `shadow-md` | `.shadow(color: .black.opacity(0.1), radius: 4, y: 2)` | Medium shadow |
| `shadow-lg` | `.shadow(color: .black.opacity(0.1), radius: 8, y: 4)` | Large shadow |
| `opacity-50` | `.opacity(0.5)` | Half opacity |
| `backdrop-blur-sm` | `.background(.ultraThinMaterial)` | Light blur |
| `backdrop-blur-md` | `.background(.thinMaterial)` | Medium blur |
| `backdrop-blur-lg` | `.background(.regularMaterial)` | Strong blur |
| `backdrop-blur-xl` | `.background(.thickMaterial)` | Heavy blur / **may indicate `.glassEffect()` on iOS 26** |

### iOS 26 Indicators in React Output

When the React output contains these patterns, they likely represent iOS 26 Liquid Glass components:

| React/Tailwind Pattern | Likely iOS 26 SwiftUI |
|---|---|
| `backdrop-blur-*` + semi-transparent background on navigation/toolbar | `.glassEffect()` or automatic glass on `NavigationStack`/`TabView` |
| Semi-transparent pill-shaped element | `.buttonStyle(.glass)` or `.glassEffect(in: .capsule)` |
| Grouped toolbar buttons with visible separation | `ToolbarSpacer(.fixed)` between groups |
| Floating tab bar with translucent background | `TabView` with iOS 26 glass (automatic) |
| Blurred background behind sheet | `.sheet { }` — iOS 26 applies glass automatically |
| "Empty state" with icon + title + description | `ContentUnavailableView` |

## React Components → SwiftUI Views

| React Pattern | SwiftUI Equivalent |
|---|---|
| `<button onClick={}>` | `Button("Label") { action() }` |
| `<input type="text">` | `TextField("Placeholder", text: $text)` |
| `<input type="password">` | `SecureField("Password", text: $password)` |
| `<textarea>` | `TextEditor(text: $text)` |
| `<select>` | `Picker("Label", selection: $value) { }` |
| `<input type="checkbox">` | `Toggle("Label", isOn: $isOn)` |
| `<input type="range">` | `Slider(value: $value, in: range)` |
| `<img src={}>` | `Image("name")` or `AsyncImage(url:)` |
| `<a href={}>` | `Link("Label", destination: url)` or `NavigationLink` |
| `<ul><li>` | `List { ForEach { } }` |
| `<nav>` | `NavigationStack { }` or `TabView { }` |
| Conditional rendering `{show && <View/>}` | `if show { View() }` |
| `.map(item => <View/>)` | `ForEach(items) { item in View() }` |
| `useState` | `@State private var` |
| `useEffect` | `.task { }` or `.onAppear { }` |
| `onClick` | `Button` or `.onTapGesture { }` |

## Animation & Transitions

| React/Tailwind/CSS | SwiftUI | Notes |
|---|---|---|
| `transition-all duration-300` | `.animation(.easeInOut(duration: 0.3), value: trigger)` | Implicit animation |
| `transition-opacity` | `withAnimation { opacity = newValue }` | Explicit animation on state change |
| `transform scale-110` | `.scaleEffect(1.1)` | Scale transform |
| `transform rotate-45` | `.rotationEffect(.degrees(45))` | Rotation transform |
| `animate-spin` | `.rotationEffect(angle).animation(.linear.repeatForever, value: angle)` | Continuous rotation |
| `animate-pulse` | `.opacity(pulsing ? 0.5 : 1).animation(.easeInOut.repeatForever())` | Pulsing opacity |
| CSS keyframe animation | `PhaseAnimator` or `KeyframeAnimator` | Complex multi-step animation |
| React transition group | `.transition(.opacity)` / `.transition(.slide)` | View insert/remove transitions |
| Framer Motion `layoutId` | `.matchedGeometryEffect(id:in:)` | Shared element transition |
| Page transition | `.navigationTransition(.zoom)` or `.navigationTransition(.slide)` | iOS 18+ navigation transitions |

## Responsive & Adaptive Layout

| React/Tailwind/CSS | SwiftUI | Notes |
|---|---|---|
| `@media (min-width: 768px)` | `@Environment(\.horizontalSizeClass) var sizeClass` | Size class for adaptive layout |
| `md:flex-row sm:flex-col` | `ViewThatFits { HStack { } VStack { } }` | Auto-adapting stack direction |
| `hidden md:block` | `if sizeClass == .regular { View() }` | Show/hide based on size class |
| `container mx-auto` | `.frame(maxWidth: 600)` or `ContainerRelativeFrame(.horizontal)` | Constrained content width |
| CSS `@container` queries | `ContainerRelativeFrame(.horizontal) { length, axis in }` | iOS 17+ container-relative sizing |
| `grid-cols-2 md:grid-cols-4` | `LazyVGrid(columns: adaptiveColumns)` with `.adaptive(minimum:)` | Adaptive grid columns |

```swift
// Adaptive grid that adjusts column count based on available width
let columns = [GridItem(.adaptive(minimum: 160))]
LazyVGrid(columns: columns) { /* items */ }

// Size-class adaptive layout
@Environment(\.horizontalSizeClass) var sizeClass
var body: some View {
    if sizeClass == .compact {
        VStack { content }
    } else {
        HStack { content }
    }
}
```

## Scroll Behavior

| React/Tailwind/CSS | SwiftUI | Notes |
|---|---|---|
| `scroll-snap-type: x mandatory` | `ScrollView(.horizontal) { }.scrollTargetBehavior(.paging)` | iOS 17+ paging scroll |
| `scroll-snap-align: center` | `.scrollTargetLayout()` on inner content | Snap to items |
| `scroll-behavior: smooth` | `.scrollPosition(id: $position)` | Programmatic smooth scroll |
| `overscroll-behavior: none` | `.scrollBounceBehavior(.basedOnSize)` | Conditional bounce |
| `position: sticky` | `.safeAreaBar(edge:)` or Section headers in List | Sticky headers |
| Infinite scroll / lazy loading | `LazyVStack { }` + `.onAppear { loadMore() }` on last item | Lazy loading pattern |

## Translation Workflow

1. **Parse structure first** — Identify the layout hierarchy (stacks, grids, scroll views)
2. **Map components** — Replace React elements with SwiftUI views
3. **Convert layout** — Flexbox → stacks, grid → LazyVGrid, absolute → ZStack
4. **Apply styling** — Colors, fonts, spacing as modifiers (not inline styles)
5. **Handle iOS 26** — Identify blur/glass patterns and map to `.glassEffect()` APIs
6. **Handle animations** — Map CSS transitions/animations to SwiftUI animation modifiers
7. **Make adaptive** — Convert media queries to size classes and `ViewThatFits`
8. **Use project tokens** — Replace literal values with project design system tokens
9. **Add interactivity** — Convert event handlers to SwiftUI actions and state
