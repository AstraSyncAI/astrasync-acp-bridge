# AstraSync ACP Bridge 🌉

Register IBM ACP (Agent Communication Protocol) agents with AstraSync's blockchain-based identity and compliance platform.

## Quick Start

```bash
# Install
npm install -g @astrasync/acp-bridge

# Register an ACP agent
astrasync-acp register my-agent.json

# Or with inline JSON
astrasync-acp register '{"name": "My Agent", "capabilities": ["chat"]}'
```

## What is this?

This bridge connects IBM's Agent Communication Protocol (ACP) with AstraSync's identity registry, providing:

- 🆔 **Unique Identity**: Blockchain-verified agent IDs
- 🔒 **Trust Scores**: Dynamic trust assessment
- 📜 **Compliance**: Immutable audit trail
- 🔗 **Interoperability**: Works with any ACP-compliant agent

## Installation

```bash
git clone https://github.com/AstraSyncAI/astrasync-acp-bridge
cd astrasync-acp-bridge
npm install
```

## Configuration

Set your developer email:
```bash
export DEVELOPER_EMAIL=your-email@example.com
```

## Usage

### Register an ACP Agent

```bash
# From file
node src/cli.js register agent-manifest.json

# With custom output
node src/cli.js register agent.json --output my-registration.json

# With different email
node src/cli.js register agent.json --email team@company.com
```

### Verify Registration

```bash
node src/cli.js verify TEMP-XXXXXX
```

## ACP Agent Format

The bridge accepts standard ACP agent manifests:

```json
{
  "id": "my-acp-agent",
  "name": "Customer Service Agent",
  "description": "Handles customer inquiries",
  "capabilities": ["chat", "task-execution"],
  "skills": [
    {
      "id": "customer-support",
      "name": "Customer Support Handler"
    }
  ],
  "authentication": {
    "schemes": ["oauth2.1"]
  }
}
```

## Developer Preview

During the preview phase:
- Agent IDs are prefixed with `TEMP-`
- No authentication required
- Blockchain registration is queued
- Email required for future account linking

## Links

- 🌐 [AstraSync Platform](https://astrasync.ai)
- 📚 [API Documentation](https://github.com/AstraSyncAI/astrasync-api)
- 💬 [Discord Community](https://discord.gg/E8wUgf2E)
- 🐛 [Report Issues](https://github.com/AstraSyncAI/astrasync-acp-bridge/issues)

## License

MIT © AstraSync 2025
