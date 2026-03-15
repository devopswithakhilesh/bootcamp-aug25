# Setup Instructions

## Step 1: Verify Installation

The MCP server has been created with the following structure:

```
aws-cost-mcp-server/
├── src/
│   └── server.py           # Main MCP server
├── venv/                   # Python virtual environment
├── requirements.txt        # Dependencies
├── README.md              # Full documentation
├── claude-config.json     # Example configuration
└── .env.example           # Environment variables template
```

## Step 2: Configure AWS Credentials

Make sure you have AWS credentials configured. Choose one method:

### Option A: AWS CLI (Recommended)
```bash
aws configure
```

### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-east-1
```

### Option C: IAM Role
If running on EC2, use an IAM role with the required permissions.

## Step 3: Test the Server

Before configuring Claude Code, test that the server works:

```bash
cd /Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server
source venv/bin/activate
python src/server.py
```

The server should start without errors (it waits for MCP protocol input via stdin).

## Step 4: Configure Claude Code

### Find Your Claude Code Config File

The config file is usually located at one of these paths:
- `~/.claude/config.json`
- `~/Library/Application Support/Claude/claude_desktop_config.json`
- `%APPDATA%/Claude/config.json` (Windows)

### Add the MCP Server

Edit the config file and add this configuration:

```json
{
  "mcpServers": {
    "aws-cost-intelligence": {
      "command": "/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/venv/bin/python",
      "args": [
        "/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/src/server.py"
      ],
      "env": {
        "AWS_DEFAULT_REGION": "us-east-1"
      }
    }
  }
}
```

**Note:** If you already have other MCP servers configured, add this server to the existing `mcpServers` object.

### Alternative: Use Claude CLI

If using the Claude CLI, you can set the MCP server via environment or config:

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
export CLAUDE_MCP_SERVERS='{"aws-cost-intelligence":{"command":"/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/venv/bin/python","args":["/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/src/server.py"]}}'
```

## Step 5: Restart Claude Code

After adding the configuration:
1. Save the config file
2. Restart Claude Code completely
3. The server should now be available

## Step 6: Test with Queries

Try these example queries in Claude Code:

### Basic Cost Query
```
What are my AWS costs for the last 30 days?
```

### Top Services
```
Show me the top 5 most expensive AWS services
```

### Running Resources
```
What EC2 instances are currently running?
```

### Waste Analysis
```
Find underutilized resources that I can stop to save money
```

## Troubleshooting

### Server Not Appearing
1. Check the config file path is correct
2. Verify absolute paths in the configuration
3. Check Claude Code logs for errors
4. Ensure the Python virtual environment exists

### AWS Errors
1. Verify AWS credentials are configured: `aws sts get-caller-identity`
2. Check IAM permissions (see README.md for required permissions)
3. Ensure Cost Explorer is enabled in your AWS account

### No Cost Data
- Cost Explorer requires 24 hours after first use
- New accounts need to enable Cost Explorer in AWS Console
- Some services may not report costs immediately

## Next Steps

1. Try the example queries above
2. Explore the README.md for more advanced usage
3. Check the server code in `src/server.py` to understand the tools
4. Add more AWS services or custom tools as needed

## Support

If you encounter issues:
1. Check the README.md for detailed documentation
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Test the server standalone: `python src/server.py`
4. Check Claude Code logs for error messages
