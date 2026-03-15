# AWS Cost Intelligence MCP Server

An MCP (Model Context Protocol) server that provides intelligent AWS cost analysis through natural language queries. Talk to Claude Code to understand your AWS spending and identify expensive running resources.

## Features

### 1. Cost Summary
Get comprehensive cost breakdowns for any time period:
- Total costs across all services
- Per-service cost breakdown
- Daily or monthly granularity
- Percentage of total spend per service

### 2. Top Services Analysis
Identify your most expensive AWS services:
- Customizable time periods
- Top N services by cost
- Cost percentages and trends

### 3. Running Resources
Get real-time inventory of costly resources:
- EC2 instances (running/stopped)
- RDS databases
- Instance types, sizes, and configurations
- Launch times and IP addresses

### 4. Waste Analysis
Find underutilized resources to save money:
- Low CPU utilization detection
- Idle instance identification
- Optimization recommendations
- Customizable thresholds

## Installation

### Prerequisites
- Python 3.10 or higher
- AWS credentials configured
- Claude Code CLI installed

### Setup

1. **Clone or navigate to the project directory:**
```bash
cd aws-cost-mcp-server
```

2. **Create virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies:**
```bash
pip install -r requirements.txt
```

4. **Configure AWS credentials:**

Make sure your AWS credentials are configured. You can use:
- AWS CLI (`aws configure`)
- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- IAM role (if running on EC2)

Required AWS permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast",
        "ec2:DescribeInstances",
        "rds:DescribeDBInstances",
        "cloudwatch:GetMetricStatistics"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuration

### Add to Claude Code

Add the server to your Claude Code configuration file (`~/.claude/config.json` or `~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "aws-cost-intelligence": {
      "command": "/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/venv/bin/python",
      "args": [
        "/Users/akhilesh/Documents/client-projects/learning-stuff/mcpawspoc/aws-cost-mcp-server/src/server.py"
      ]
    }
  }
}
```

**Note:** Update the paths to match your actual installation directory.

### Test the Server (Optional)

You can test the server directly:
```bash
source venv/bin/activate
python src/server.py
```

The server communicates via stdio, so you won't see output unless connected to an MCP client.

## Usage Examples

Once configured in Claude Code, you can ask natural language questions:

### Cost Analysis
```
"What are my AWS costs for the last 30 days?"
"Show me the top 5 most expensive services this month"
"Break down my costs by service for the last week"
```

### Resource Discovery
```
"What EC2 instances are currently running?"
"Show me all RDS databases in us-west-2"
"List running resources in my account"
```

### Waste Detection
```
"Find underutilized EC2 instances"
"Show me instances with low CPU usage"
"What resources can I stop to save money?"
```

### Specific Queries
```
"Which service costs me the most money?"
"Are there any idle EC2 instances I should shut down?"
"Show me running resources that cost significant money"
```

## Available Tools

### 1. get_cost_summary
```json
{
  "days": 30,           // Number of days to analyze (max 90)
  "granularity": "DAILY" // DAILY or MONTHLY
}
```

### 2. get_top_services
```json
{
  "days": 30,    // Number of days to analyze
  "limit": 10    // Number of top services to return
}
```

### 3. get_running_resources
```json
{
  "region": "us-east-1",     // AWS region
  "include_stopped": false    // Include stopped instances
}
```

### 4. analyze_waste
```json
{
  "region": "us-east-1",  // AWS region
  "cpu_threshold": 10      // CPU % threshold for underutilization
}
```

## Architecture

```
┌─────────────────┐
│   Claude Code   │
│   (MCP Client)  │
└────────┬────────┘
         │
         │ MCP Protocol (stdio)
         │
┌────────▼────────┐
│   MCP Server    │
│  (Python/boto3) │
└────────┬────────┘
         │
         │ AWS SDK Calls
         │
┌────────▼────────────────────┐
│       AWS Services          │
├─────────────────────────────┤
│ • Cost Explorer             │
│ • EC2                       │
│ • RDS                       │
│ • CloudWatch                │
└─────────────────────────────┘
```

## Troubleshooting

### "No credentials found"
Make sure AWS credentials are configured:
```bash
aws configure
```

### "Access Denied" errors
Ensure your IAM user/role has the required permissions (see Installation section).

### Server not appearing in Claude Code
1. Check the config file path
2. Verify absolute paths in the configuration
3. Restart Claude Code
4. Check Claude Code logs for errors

### No cost data returned
- Cost Explorer requires 24 hours of usage before data appears
- New AWS accounts may not have Cost Explorer enabled
- Enable Cost Explorer in AWS Console: Billing Dashboard → Cost Explorer

## Extending the Server

Add new tools by:

1. Adding a new tool definition in `list_tools()`
2. Implementing the handler in `call_tool()`
3. Creating the async function for the tool logic

Example:
```python
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        # ... existing tools ...
        Tool(
            name="get_lambda_costs",
            description="Get Lambda function costs",
            inputSchema={...}
        )
    ]
```

## License

MIT

## Contributing

Contributions welcome! Feel free to:
- Add new AWS services
- Improve cost analysis algorithms
- Add more optimization recommendations
- Enhance error handling

## Support

For issues or questions:
- Check AWS credentials and permissions
- Review CloudWatch logs
- Verify MCP configuration in Claude Code
