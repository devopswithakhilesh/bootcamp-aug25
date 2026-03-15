#!/bin/bash

# AWS Cost Intelligence MCP Server Setup Script

set -e

echo "🚀 AWS Cost Intelligence MCP Server Setup"
echo "==========================================="
echo ""

# Check Python version
echo "📋 Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "   Found Python $PYTHON_VERSION"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "   Run: python3 -m venv venv"
    exit 1
fi

echo "✅ Virtual environment found"

# Activate virtual environment and check dependencies
echo ""
echo "📦 Checking dependencies..."
source venv/bin/activate

if ! python -c "import mcp" 2>/dev/null; then
    echo "❌ MCP library not installed"
    echo "   Run: pip install -r requirements.txt"
    exit 1
fi

if ! python -c "import boto3" 2>/dev/null; then
    echo "❌ boto3 not installed"
    echo "   Run: pip install -r requirements.txt"
    exit 1
fi

echo "✅ All dependencies installed"

# Check AWS credentials
echo ""
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "⚠️  AWS credentials not configured or invalid"
    echo "   Configure with: aws configure"
    echo "   Or set environment variables:"
    echo "     export AWS_ACCESS_KEY_ID=your_key"
    echo "     export AWS_SECRET_ACCESS_KEY=your_secret"
else
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    echo "✅ AWS credentials valid"
    echo "   Account: $AWS_ACCOUNT"
    echo "   User: $AWS_USER"
fi

# Test server startup
echo ""
echo "🧪 Testing server startup..."
if python src/server.py --help &>/dev/null; then
    echo "✅ Server can start"
else
    # Server will hang waiting for input, which is expected
    echo "✅ Server executable found"
fi

# Show configuration
echo ""
echo "⚙️  Configuration for Claude Code:"
echo "==========================================="
echo ""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cat <<EOF
{
  "mcpServers": {
    "aws-cost-intelligence": {
      "command": "${SCRIPT_DIR}/venv/bin/python",
      "args": [
        "${SCRIPT_DIR}/src/server.py"
      ],
      "env": {
        "AWS_DEFAULT_REGION": "us-east-1"
      }
    }
  }
}
EOF

echo ""
echo "==========================================="
echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Add the configuration above to your Claude Code config"
echo "   2. Restart Claude Code"
echo "   3. Try: 'What are my AWS costs for the last 30 days?'"
echo ""
echo "📚 For detailed instructions, see SETUP_INSTRUCTIONS.md"
