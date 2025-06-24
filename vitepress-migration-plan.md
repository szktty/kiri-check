# VitePress Migration Plan

## Overview
Migration from JetBrains Writerside to VitePress for kiri-check documentation.

## Current Writerside Structure Analysis

### Content Files
- **Landing Page**: `Get-started.topic` (XML format) - needs conversion to Markdown
- **Documentation Files**: 11 Markdown files in `topics/` directory
- **Navigation**: Defined in `kiri-check-doc.tree` (XML format)
- **Configuration**: `writerside.cfg` and `buildprofiles.xml`

### Current Navigation Structure
```
Get-started (landing page)
├── Quickstart.md
├── Write-properties.md  
├── Configure-tests.md
├── Arbitraries.md
├── Generation.md
├── Shrinking.md
├── Stateful-testing.md
│   ├── Stateful-testing-quickstart.md
│   ├── Write-stateful-properties.md
│   └── Stateful-testing-commands.md
└── Statistics.md
```

### Current Theme Configuration
- Primary color: forest
- Download button enabled
- Download page: https://pub.dev/packages/kiri_check/
- Download title: "dart pub add dev:kiri_check"

## VitePress Migration Plan

### Phase 1: Project Setup
1. **Initialize VitePress project**
   - Run `npm init` and install VitePress dependencies
   - Create basic VitePress configuration
   - Set up directory structure

2. **Directory Structure**
   ```
   docs/
   ├── .vitepress/
   │   ├── config.js          # Main configuration
   │   └── theme/             # Custom theme (if needed)
   ├── index.md               # Home page (converted from Get-started.topic)
   ├── quickstart.md          # Direct copy from Writerside
   ├── properties/            # Group related topics
   │   ├── write-properties.md
   │   └── configure-tests.md
   ├── arbitraries.md
   ├── generation.md
   ├── shrinking.md
   ├── stateful/              # Stateful testing group
   │   ├── index.md           # Stateful-testing.md
   │   ├── quickstart.md      # Stateful-testing-quickstart.md
   │   ├── properties.md      # Write-stateful-properties.md
   │   └── commands.md        # Stateful-testing-commands.md
   └── statistics.md
   ```

### Phase 2: Content Migration
1. **Convert XML landing page to Markdown**
   - Transform `Get-started.topic` XML structure to VitePress home page format
   - Preserve spotlight, primary, secondary, and misc sections
   - Convert to VitePress hero and features sections

2. **Copy and adapt Markdown files**
   - Copy existing `.md` files from `Writerside/topics/`
   - Update internal links to match new structure
   - Ensure Markdown compatibility with VitePress

3. **Link updates**
   - Update cross-references between documents
   - Fix anchor links and section references
   - Ensure proper relative paths

### Phase 3: Configuration
1. **VitePress config.js setup**
   - Site title: "kiri-check"
   - Description: Property-based testing library for Dart/Flutter
   - Base URL configuration for GitHub Pages
   - Theme configuration matching current forest color scheme

2. **Navigation sidebar**
   - Recreate navigation structure from `kiri-check-doc.tree`
   - Group related topics (Properties, Stateful Testing)
   - Maintain logical flow for readers

3. **Theme customization**
   - Apply forest color scheme
   - Add download button/link to pub.dev
   - Customize layout to match branding

### Phase 4: Deployment Setup
1. **GitHub Actions workflow**
   - Create `.github/workflows/deploy-docs.yml`
   - Build VitePress documentation
   - Deploy to GitHub Pages on push to `develop` branch
   - Remove old Writerside workflow

2. **Package.json scripts**
   - `dev`: Local development server
   - `build`: Production build
   - `preview`: Preview built docs

### Phase 5: Testing and Validation
1. **Content verification**
   - Ensure all content is accessible
   - Verify internal links work correctly
   - Check code blocks and syntax highlighting

2. **Visual verification**
   - Compare with original Writerside output
   - Ensure branding consistency
   - Test responsive design

## Implementation Steps

### Step 1: VitePress Setup
- Initialize npm project
- Install VitePress and dependencies
- Create basic configuration

### Step 2: Content Structure
- Create `docs/` directory structure
- Copy Markdown files to appropriate locations
- Convert `Get-started.topic` to `index.md`

### Step 3: Configuration
- Configure VitePress with navigation
- Set up theme and styling
- Configure deployment settings

### Step 4: Link Migration
- Update all internal links
- Fix cross-references
- Test navigation flow

### Step 5: Deployment
- Set up GitHub Actions workflow
- Test deployment process
- Update branch strategy if needed

## File Mapping

| Writerside | VitePress | Notes |
|------------|-----------|-------|
| `Get-started.topic` | `docs/index.md` | Convert XML to Markdown hero page |
| `Quickstart.md` | `docs/quickstart.md` | Direct copy |
| `Write-properties.md` | `docs/properties/write-properties.md` | Move to properties group |
| `Configure-tests.md` | `docs/properties/configure-tests.md` | Move to properties group |
| `Arbitraries.md` | `docs/arbitraries.md` | Direct copy |
| `Generation.md` | `docs/generation.md` | Direct copy |
| `Shrinking.md` | `docs/shrinking.md` | Direct copy |
| `Stateful-testing.md` | `docs/stateful/index.md` | Rename as group index |
| `Stateful-testing-quickstart.md` | `docs/stateful/quickstart.md` | Move to stateful group |
| `Write-stateful-properties.md` | `docs/stateful/properties.md` | Move to stateful group |
| `Stateful-testing-commands.md` | `docs/stateful/commands.md` | Move to stateful group |
| `Statistics.md` | `docs/statistics.md` | Direct copy |

## Dependencies to Install
```json
{
  "devDependencies": {
    "vitepress": "^1.0.0"
  }
}
```

## Post-Migration Cleanup
- Remove `Writerside/` directory
- Update `README.md` with new development instructions
- Update `CLAUDE.md` with VitePress information
- Archive or remove Writerside-related GitHub Actions workflow

## Success Criteria
- [ ] All documentation content accessible in VitePress
- [ ] Navigation matches original structure
- [ ] Internal links work correctly
- [ ] GitHub Pages deployment functional
- [ ] Visual appearance consistent with branding
- [ ] Search functionality working
- [ ] Mobile-responsive design