# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a VitePress documentation project for kiri-check, a property-based testing library for Dart/Flutter. The documentation covers property-based testing concepts, arbitraries, generation, shrinking, and stateful testing.

## Architecture

- **docs/**: Contains all VitePress documentation source files
  - `.vitepress/config.js`: VitePress configuration with navigation and theme settings
  - `index.md`: Home page with hero section and feature cards
  - `properties/`: Property-based testing basics (write-properties.md, configure-tests.md)
  - `stateful/`: Stateful testing documentation (index.md, quickstart.md, properties.md, commands.md)
  - Individual topic files: `arbitraries.md`, `generation.md`, `shrinking.md`, `statistics.md`, `quickstart.md`
- **GitHub Pages**: Documentation is automatically built and deployed via GitHub Actions

## Common Commands

### Local Development
```bash
npm run docs:dev    # Start development server
npm run docs:build  # Build documentation
npm run docs:preview # Preview built documentation
```

### Building Documentation
The documentation is built automatically via GitHub Actions when pushing to the `develop` branch. The build uses VitePress static site generator.

### Deployment
- Documentation builds automatically on push to `develop` branch
- Uses GitHub Actions workflow in `.github/workflows/deploy-docs.yml`
- Deploys to GitHub Pages after successful build

## Key Files Structure

- `docs/index.md`: Home page with hero section and feature navigation
- `docs/.vitepress/config.js`: Navigation structure, theme configuration, and site settings
- Topic files organized by category with clear naming (e.g., `quickstart.md`, `arbitraries.md`)
- Internal links use VitePress format: `/path/to/page#anchor`

## Documentation Content Areas

1. **Basic Usage**: Quickstart, writing properties, configuration
2. **Arbitraries**: Data generation for different types and custom data
3. **Advanced Features**: Generation control, shrinking, statistics, asynchronous support
4. **Stateful Testing**: Commands, properties, execution model

## Recent Updates

### v1.3.0
- New arbitraries: `duration`, `uri`
- New arbitrary manipulation: `nonEmpty` for ensuring collections are not empty
- New `cast()` method for type casting dynamic arbitraries
- Bug fix: Unexpected error during shrinking with nested `combine` arbitraries

### v1.2.0+
Key features that should be documented:
- `Arbitrary.example` method for generating values outside tests
- `build` arbitrary for callable objects
- Asynchronous support for both stateless and stateful testing
- Global setup/teardown functions: `setUpForAll`, `tearDownForAll`
- Enhanced setup/teardown with `setUpAll`, `tearDownAll` parameters

## Branch Strategy

- `develop`: Main development branch
- `gh-pages`: Documentation publishing branch
