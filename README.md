# Omasaver

Omasaver is a personalization plugin and CLI utility for Omarchy that customizes the idle screensaver text and animations.

## Highlights

- **Custom Text Engine**: Render any name or text using Omarchy's signature 8-row block typography with tightened 3-space letter kerning.
- **Animation Effects**: Supports 24 animation styles powered by `ttfx` (Matrix rain, Decryption, Fireworks, Rain, Laser Etch, Black Hole, etc.) or random cycling.
- **Omarchy Shell Panel**: Manage settings directly from the top bar with a live ASCII art preview.
- **One-Click Revert**: Revert back to the stock Omarchy screensaver logo at any time.
- **Interactive CLI**: Preview animations in a floating terminal window before applying them.

## Command Line Usage

```bash
# Set screensaver text
omasaver set "NIHAL"

# Preview an animation in a floating window
omasaver test matrix
omasaver test fireworks

# List all 24 supported animation effects
omasaver list

# View current screensaver status
omasaver status

# Launch screensaver immediately
omasaver run

# Revert to default Omarchy logo
omasaver reset
```

## Plugin Architecture

- `manifest.json`: Quattro plugin manifest adhering to schemaVersion 1.
- `BarWidget.qml`: Shell bar item with toggle and quick launch actions.
- `Panel.qml`: Popup interface with live ASCII preview and effect selector.
- `Model.js`: Glyph dictionary, text rendering engine, and animation effect definitions.
- `bin/omasaver`: Portable shell script CLI tool.

## License

MIT License - Copyright (c) Nihal
