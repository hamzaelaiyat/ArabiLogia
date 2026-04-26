# Arabilogia - Design Tokens

## Overview

This document catalogs the design tokens used throughout the Arabilogia Flutter application.

---

## Colors

### Primary Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#EB8A00` | Primary actions, Amber Gold |
| `primaryTo` | `#C26F00` | Gradient end for primary |
| `accentLight` | `#EB5833` | Accent/highlights, Sunset Glow |

### Background Colors

| Token | Hex | OKLCH | Usage |
|-------|-----|-------|-------|
| `bgLight` | `#F7FCFF` | oklch(0.99 0.01 250) | Light mode background |
| `bgDark` | `#191B1D` | oklch(0.22 0.005 248) | Dark mode background |

### Foreground/Text Colors

| Token | Hex | OKLCH | Usage |
|-------|-----|-------|-------|
| `fgLight` | `#1A222B` | oklch(0.25 0.02 250) | Light mode text |
| `fgDark` | `#EAEFF5` | oklch(0.95 0.01 250) | Dark mode text |
| `muted` | `#4D5660` | - | Muted text |
| `mutedLight` | `#4D5660` | - | Light mode muted |
| `mutedDark` | `#91A0B1` | - | Dark mode muted |

### Secondary/Surface Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `secondaryLight` | `#EDF2F8` | Light mode surface |
| `secondaryDark` | `#282F35` | Dark mode surface |

### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `error` | `#FF3B30` | Error states |
| `success` | `#34C759` | Success states |
| `emerald` | `#30D158` | Success (alt) |
| `warning` | `#FFCC00` | Warning states |

### Glassmorphism (Premium UI)

| Token | Hex (Alpha) | Usage |
|-------|-------------|-------|
| `surfaceGlass` | `#33FFFFFF` | Glass effect light |
| `surfaceGlassDark` | `#1AFFFFFF` | Glass effect dark |
| `glowPrimary` | `#40EB8A00` | Amber glow effect |

### Container Colors (Light Mode)

| Token | Hex | Usage |
|-------|-----|-------|
| `primaryContainerLight` | `#F5E6D3` | Primary container |
| `secondaryContainerLight` | `#FFE8E0` | Secondary container |
| `tertiaryContainerLight` | `#E8F5E9` | Tertiary container |

### Chart Colors

Located in `app_chart_palette.dart`:

- **Categorical Palette:** Amber, Orange-Red, Green, Blue, Purple, Teal, Pink
- **Semantic:** Status indicators for charts
- **Grid/Axis:** Light and dark mode variants

---

## Typography

### Font Families

| Token | Font | Usage |
|-------|------|-------|
| `fontFamilyDisplay` | `ReadexPro` | Headings, display text |
| `fontFamilyBody` | `Rubik` | Body text, labels |

### Font Sizes (11-step scale)

| Token | Size | Usage |
|-------|------|-------|
| `fontSizeXs` | 11px | Extra small text |
| `fontSizeSm` | 12px | Labels, captions |
| `fontSizeMd` | 14px | Body text (secondary) |
| `fontSizeLg` | 16px | Body text (primary) |
| `fontSizeXl` | 18px | Title (small) |
| `fontSize2xl` | 22px | Title (medium) |
| `fontSize3xl` | 24px | Title (large) |
| `fontSize4xl` | 28px | Headline |
| `fontSize5xl` | 32px | Display (small) |
| `fontSize6xl` | 45px | Display (medium) |
| `fontSize7xl` | 57px | Hero/Display (large) |

### Text Theme Mapping

| Style | Font Family | Size Token | Font Weight |
|-------|-------------|------------|-------------|
| `displayLarge` | ReadexPro | fontSize5xl (32px) | bold |
| `displayMedium` | ReadexPro | fontSize6xl (45px) | bold |
| `displaySmall` | ReadexPro | fontSize4xl (28px) | w600 |
| `headlineLarge` | ReadexPro | fontSize5xl (32px) | w700 |
| `headlineMedium` | ReadexPro | fontSize4xl (28px) | bold |
| `headlineSmall` | ReadexPro | fontSize3xl (24px) | w600 |
| `titleLarge` | ReadexPro | fontSize2xl (22px) | w600 |
| `titleMedium` | ReadexPro | fontSizeXl (18px) | w600 |
| `titleSmall` | Rubik | fontSizeSm (12px) | w600 |
| `bodyLarge` | Rubik | fontSizeLg (16px) | normal |
| `bodyMedium` | Rubik | fontSizeMd (14px) | normal |
| `bodySmall` | Rubik | fontSizeXs (11px) | normal |
| `labelLarge` | Rubik | fontSizeMd (14px) | w500 |
| `labelMedium` | Rubik | fontSizeSm (12px) | w500 |
| `labelSmall` | Rubik | fontSizeXs (11px) | w500 |

---

## Spacing

### Base Unit: 4px

| Token | Value | Usage |
|-------|-------|-------|
| `spacing2` | 4px | Extra small spacing |
| `spacing4` | 8px | Small spacing |
| `spacing6` | 12px | Medium-small spacing |
| `spacing8` | 16px | Medium spacing (default) |
| `spacing10` | 20px | Medium-large spacing |
| `spacing12` | 24px | Large spacing |
| `spacing16` | 32px | Extra large spacing |
| `spacing20` | 40px | Section spacing |
| `spacing24` | 48px | Large section spacing |
| `spacing32` | 64px | Hero section spacing |

---

## Layout & Breakpoints

| Token | Value | Description |
|-------|-------|-------------|
| `breakpointMobile` | 768px | Mobile breakpoint |
| `breakpointTablet` | 1024px | Tablet breakpoint |
| `breakpointDesktop` | 1280px | Desktop breakpoint |
| `contentMaxWidth` | 1280px | Max content width |
| `dashboardPadding` | 24px | Desktop dashboard padding |
| `dashboardPaddingMobile` | 16px | Mobile dashboard padding |
| `sidebarWidth` | 280px | Sidebar/Drawer width |

---

## Sizing

### Touch Targets

| Token | Value | Usage |
|-------|-------|-------|
| `touchTargetMin` | 44px | WCAG minimum |

### Icon Sizes

| Token | Value | Usage |
|-------|-------|-------|
| `iconSizeXs` | 16px | Small icon |
| `iconSizeMd` | 24px | Default icon |
| `iconSizeLg` | 32px | Large icon |
| `iconSizeXl` | 48px | Extra large icon |
| `iconSize2xl` | 64px | Hero icon |

### Button Heights

| Token | Value | Usage |
|-------|-------|-------|
| `buttonHeightSm` | 40px | Small button |
| `buttonHeightMd` | 48px | Medium button |
| `buttonHeightLg` | 56px | Large button |

### Other Sizing

| Token | Value | Usage |
|-------|-------|-------|
| `inputHeight` | 52px | Input field height |
| `avatarSm` | 32px | Small avatar |
| `avatarMd` | 48px | Medium avatar |
| `avatarLg` | 64px | Large avatar |
| `avatarXl` | 96px | Extra large avatar |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radiusXs` | 4px | Extra small radius |
| `radiusSm` | 8px | Small radius |
| `radiusMd` | 12px | Medium radius |
| `radiusLg` | 16px | Buttons |
| `radiusXl` | 20px | Input fields |
| `radius2xl` | 24px | Cards and containers |
| `radius3xl` | 32px | Large cards/sections |
| `radiusFull` | 999px | Pills, FABs |

### Pre-defined BorderRadius

- `radiusSmAll` - All corners radiusSm
- `radiusMdAll` - All corners radiusMd
- `radiusLgAll` - All corners radiusLg
- `radiusXlAll` - All corners radiusXl
- `radius2xlAll` - All corners radius2xl
- `radius3xlAll` - All corners radius3xl

---

## Elevation

| Token | Value | Usage |
|-------|-------|-------|
| `elevationNone` | 0.0 | No shadow |
| `elevationSm` | 1.0 | Cards, inputs |
| `elevationMd` | 2.0 | Default |
| `elevationLg` | 4.0 | Buttons, FABs |
| `elevationXl` | 8.0 | Modals |

---

## Animation

| Token | Value | Usage |
|-------|-------|-------|
| `durationFast` | 150ms | Quick animations |
| `durationMd` | 300ms | Default duration |
| `durationSlow` | 500ms | Slower animations |

---

## File Structure

```
lib/core/theme/
├── app_colors.dart           # Color palette definitions
├── app_chart_palette.dart    # Chart-specific colors
├── app_tokens.dart           # Spacing, sizing, typography, elevation
├── app_theme.dart            # Entry point (lightTheme, darkTheme)
├── light_theme.dart          # Light ThemeData
├── dark_theme.dart           # Dark ThemeData
└── theme_factory.dart        # Component theme factories
```

---

## Usage

```dart
// Colors
AppColors.primary
AppColors.bgLight
AppColors.error

// Spacing
AppTokens.spacing8
AppTokens.spacing12

// Typography
AppTokens.fontSizeLg
Theme.of(context).textTheme.headlineMedium

// Sizing
AppTokens.buttonHeightMd
AppTokens.iconSizeMd

// Radius
AppTokens.radiusLg
AppTokens.radiusFull

// Elevation
AppTokens.elevationMd
```

---

*Document Version: 1.0*
*Created: April 1, 2026*
