# iTurnel

A native macOS menu bar app for managing Cloudflare Tunnels. Quickly create, manage, and monitor tunnels without touching the command line.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Quick Tunnels** - Create temporary public URLs instantly (trycloudflare.com)
- **Named Tunnels** - Connect persistent tunnels with token authentication
- **Custom Ingress Rules** - Route multiple hostnames to different local services
- **Presets** - Save tunnel configurations for one-click access
- **Auto-start** - Launch specific tunnels when the app starts
- **Real-time Logs** - View tunnel output in a dedicated window
- **History** - Track past tunnel connections with easy recreation
- **Secure Storage** - Tunnel tokens stored in macOS Keychain
- **Notifications** - Get notified when tunnels connect or disconnect

## Requirements

- macOS 13.0 or later
- [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) CLI tool

## Installation

### 1. Install cloudflared

```bash
brew install cloudflared
```

### 2. Install iTurnel

Download the latest release from the [Releases](https://github.com/user/iturnel/releases) page, or build from source.

## Build from Source

```bash
# Clone the repository
git clone https://github.com/user/iturnel.git
cd iturnel

# Open in Xcode
open cloudflare-turnel.xcodeproj

# Build and run (Cmd+R)
```

## Usage

### Quick Tunnel

1. Click the iTurnel icon in your menu bar
2. Click "New Tunnel"
3. Enter a name and your local service details (e.g., `localhost:3000`)
4. Select "Quick Tunnel" type
5. Click "Create Tunnel"

You'll get a temporary public URL like `https://random-words.trycloudflare.com`

### Named Tunnel (Token Mode)

1. Create a tunnel in the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Copy the tunnel token
3. In iTurnel Settings > Tokens, paste and save your token
4. Create a new tunnel with "Named Tunnel" type
5. Ingress rules are configured in the Cloudflare Dashboard

### Named Tunnel (Config Mode)

For local ingress rules routing multiple hostnames:

1. Run `cloudflared tunnel login` to create credentials
2. Create a new tunnel with "Named Tunnel" type
3. Select "Config File" mode
4. Enter your tunnel UUID and credentials file path
5. Add ingress rules (e.g., `api.example.com` → `http://localhost:3000`)

### Presets

Save any tunnel configuration as a preset for quick access:

1. When creating a tunnel, check "Save as Preset"
2. Optionally enable "Auto-start on Launch"
3. Access presets from the Presets tab

## Configuration

Settings are available in the menu bar dropdown or via `Cmd+,`:

| Setting | Description |
|---------|-------------|
| Launch at Login | Start iTurnel when you log in |
| Auto-start Presets | Launch marked presets on app start |
| Show Notifications | Notify on tunnel connect/disconnect |
| Copy URL on Connect | Auto-copy public URL to clipboard |
| Default Protocol | HTTP, HTTPS, TCP, or SSH |
| Default Host | Default local host (e.g., localhost) |
| Default Port | Default local port (e.g., 8080) |

## Data Storage

- **Presets & History**: `~/Library/Application Support/iTurnel/`
- **Tunnel Tokens**: macOS Keychain
- **Settings**: UserDefaults

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) for the underlying tunnel technology
- Built with SwiftUI for macOS
