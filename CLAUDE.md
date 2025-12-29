# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iTurnel is a macOS menu bar application for managing Cloudflare Tunnels. Built with SwiftUI, it runs as a menu bar extra (no dock icon).

## Build Commands

```bash
# Build the project (requires Xcode)
xcodebuild -scheme cloudflare-turnel -configuration Debug build

# Open in Xcode
open cloudflare-turnel.xcodeproj
```

## Architecture

### State Management
- **AppState** (`State/AppState.swift`): Central observable state using `@Observable` macro, marked `@MainActor`
- Single source of truth for tunnels, presets, history, settings, and UI state
- Views access via `@Environment(AppState.self)`

### Service Layer (Actor Pattern)
- **CloudflaredService**: Manages cloudflared subprocess lifecycle, parses output for URLs and status
- **ConfigFileService**: Generates YAML config files for ingress-based named tunnels
- **PersistenceService**: JSON persistence to `~/Library/Application Support/iTurnel/`
- **KeychainService**: Secure token storage

### Tunnel Types
1. **Quick Tunnel**: Temporary trycloudflare.com URLs, no auth needed
2. **Named Tunnel (Token)**: Uses `cloudflared tunnel run --token <token>`
3. **Named Tunnel (Config)**: Uses `cloudflared tunnel --config <file> run <name>` with ingress rules

### Key Models
- `Tunnel` / `TunnelConfiguration`: Core tunnel data with status, protocol, ingress rules
- `Preset`: Saved configurations with auto-start support
- `IngressRule`: Hostname-to-service routing for config-based tunnels

## Code Conventions

- Use `pnpm` for any Node.js tooling
- Services use actor pattern for thread safety
- Views follow SwiftUI patterns with extracted components in `Views/Components/`
- Custom Codable decoders handle backwards compatibility for persisted data

## External Dependency

Requires `cloudflared` binary installed (auto-detects from `/opt/homebrew/bin/`, `/usr/local/bin/`, `/usr/bin/`)
