#!/bin/bash

echo "🚀 Setting up AstraSync ACP Bridge..."

# Create directories
mkdir -p src

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create .env from example
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 Created .env file - please update DEVELOPER_EMAIL"
fi

# Make CLI executable
chmod +x src/cli.js

# Run health check
echo "🏥 Running health check..."
node src/healthcheck.js

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env and set your DEVELOPER_EMAIL"
echo "2. Test with: node src/cli.js register test-agent.json"
echo ""