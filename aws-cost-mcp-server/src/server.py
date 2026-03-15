#!/usr/bin/env python3
"""
AWS Cost Intelligence MCP Server

This MCP server provides tools to analyze AWS costs and identify expensive running resources.
"""

import asyncio
import json
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Any

import boto3
from mcp.server import Server
from mcp.types import Tool, TextContent
from pydantic import BaseModel, Field


# Custom JSON encoder for AWS Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


# Initialize the MCP server
server = Server("aws-cost-intelligence")

# AWS clients (will be initialized lazily)
cost_explorer_client = None
ec2_client = None
rds_client = None
cloudwatch_client = None


def get_cost_explorer_client():
    """Get or create Cost Explorer client"""
    global cost_explorer_client
    if cost_explorer_client is None:
        cost_explorer_client = boto3.client('ce', region_name='us-east-1')
    return cost_explorer_client


def get_ec2_client(region='us-east-1'):
    """Get or create EC2 client"""
    global ec2_client
    if ec2_client is None:
        ec2_client = boto3.client('ec2', region_name=region)
    return ec2_client


def get_rds_client(region='us-east-1'):
    """Get or create RDS client"""
    global rds_client
    if rds_client is None:
        rds_client = boto3.client('rds', region_name=region)
    return rds_client


def get_cloudwatch_client(region='us-east-1'):
    """Get or create CloudWatch client"""
    global cloudwatch_client
    if cloudwatch_client is None:
        cloudwatch_client = boto3.client('cloudwatch', region_name=region)
    return cloudwatch_client


@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available AWS cost analysis tools"""
    return [
        Tool(
            name="get_cost_summary",
            description="Get AWS cost summary for the last 30 days, broken down by service. Shows total costs and daily breakdown.",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "integer",
                        "description": "Number of days to analyze (default: 30, max: 90)",
                        "default": 30
                    },
                    "granularity": {
                        "type": "string",
                        "description": "Time granularity: DAILY or MONTHLY",
                        "enum": ["DAILY", "MONTHLY"],
                        "default": "DAILY"
                    }
                }
            }
        ),
        Tool(
            name="get_top_services",
            description="Get the top N most expensive AWS services in the specified time period",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "integer",
                        "description": "Number of days to analyze (default: 30)",
                        "default": 30
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Number of top services to return (default: 10)",
                        "default": 10
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="get_running_resources",
            description="Get currently running EC2 instances and RDS databases with their estimated costs",
            inputSchema={
                "type": "object",
                "properties": {
                    "region": {
                        "type": "string",
                        "description": "AWS region to check (default: us-east-1)",
                        "default": "us-east-1"
                    },
                    "include_stopped": {
                        "type": "boolean",
                        "description": "Include stopped instances (default: false)",
                        "default": False
                    }
                }
            }
        ),
        Tool(
            name="analyze_waste",
            description="Analyze potential cost waste from idle or underutilized resources (low CPU usage EC2 instances)",
            inputSchema={
                "type": "object",
                "properties": {
                    "region": {
                        "type": "string",
                        "description": "AWS region to check (default: us-east-1)",
                        "default": "us-east-1"
                    },
                    "cpu_threshold": {
                        "type": "number",
                        "description": "CPU utilization threshold percentage (default: 10)",
                        "default": 10
                    }
                }
            }
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""

    try:
        if name == "get_cost_summary":
            result = await get_cost_summary(
                days=arguments.get("days", 30),
                granularity=arguments.get("granularity", "DAILY")
            )

        elif name == "get_top_services":
            result = await get_top_services(
                days=arguments.get("days", 30),
                limit=arguments.get("limit", 10)
            )

        elif name == "get_running_resources":
            result = await get_running_resources(
                region=arguments.get("region", "us-east-1"),
                include_stopped=arguments.get("include_stopped", False)
            )

        elif name == "analyze_waste":
            result = await analyze_waste(
                region=arguments.get("region", "us-east-1"),
                cpu_threshold=arguments.get("cpu_threshold", 10)
            )
        else:
            raise ValueError(f"Unknown tool: {name}")

        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2, cls=DecimalEncoder)
        )]

    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "tool": name
            }, indent=2)
        )]


async def get_cost_summary(days: int = 30, granularity: str = "DAILY") -> dict:
    """Get AWS cost summary for the specified period"""

    ce = get_cost_explorer_client()

    # Calculate date range
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=days)

    # Get cost and usage data
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity=granularity,
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )

    # Process results
    total_cost = 0
    service_costs = {}

    for result in response['ResultsByTime']:
        period = result['TimePeriod']['Start']

        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])

            if service not in service_costs:
                service_costs[service] = {'total': 0, 'daily': []}

            service_costs[service]['total'] += cost
            service_costs[service]['daily'].append({
                'date': period,
                'cost': cost
            })
            total_cost += cost

    # Sort services by cost
    sorted_services = sorted(
        service_costs.items(),
        key=lambda x: x[1]['total'],
        reverse=True
    )

    return {
        'period': {
            'start': start_date.strftime('%Y-%m-%d'),
            'end': end_date.strftime('%Y-%m-%d'),
            'days': days
        },
        'total_cost': round(total_cost, 2),
        'services': [
            {
                'name': name,
                'total_cost': round(data['total'], 2),
                'percentage': round((data['total'] / total_cost * 100), 2) if total_cost > 0 else 0
            }
            for name, data in sorted_services[:15]  # Top 15 services
        ],
        'granularity': granularity
    }


async def get_top_services(days: int = 30, limit: int = 10) -> dict:
    """Get the top N most expensive services"""

    ce = get_cost_explorer_client()

    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=days)

    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )

    # Aggregate costs by service
    service_costs = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            service_costs[service] = service_costs.get(service, 0) + cost

    # Sort and get top N
    top_services = sorted(
        service_costs.items(),
        key=lambda x: x[1],
        reverse=True
    )[:limit]

    total_cost = sum(service_costs.values())

    return {
        'period': {
            'start': start_date.strftime('%Y-%m-%d'),
            'end': end_date.strftime('%Y-%m-%d'),
            'days': days
        },
        'total_cost': round(total_cost, 2),
        'top_services': [
            {
                'service': service,
                'cost': round(cost, 2),
                'percentage': round((cost / total_cost * 100), 2) if total_cost > 0 else 0
            }
            for service, cost in top_services
        ]
    }


async def get_running_resources(region: str = 'us-east-1', include_stopped: bool = False) -> dict:
    """Get running EC2 instances and RDS databases"""

    ec2 = get_ec2_client(region)
    rds = get_rds_client(region)

    resources = {
        'region': region,
        'ec2_instances': [],
        'rds_instances': [],
        'summary': {
            'total_ec2_instances': 0,
            'total_rds_instances': 0
        }
    }

    # Get EC2 instances
    filters = [] if include_stopped else [
        {'Name': 'instance-state-name', 'Values': ['running']}
    ]

    ec2_response = ec2.describe_instances(Filters=filters)

    for reservation in ec2_response['Reservations']:
        for instance in reservation['Instances']:
            instance_name = ''
            for tag in instance.get('Tags', []):
                if tag['Key'] == 'Name':
                    instance_name = tag['Value']
                    break

            resources['ec2_instances'].append({
                'instance_id': instance['InstanceId'],
                'name': instance_name,
                'instance_type': instance['InstanceType'],
                'state': instance['State']['Name'],
                'launch_time': instance['LaunchTime'].isoformat(),
                'private_ip': instance.get('PrivateIpAddress', 'N/A'),
                'public_ip': instance.get('PublicIpAddress', 'N/A')
            })

    resources['summary']['total_ec2_instances'] = len(resources['ec2_instances'])

    # Get RDS instances
    try:
        rds_response = rds.describe_db_instances()

        for db_instance in rds_response['DBInstances']:
            resources['rds_instances'].append({
                'db_instance_id': db_instance['DBInstanceIdentifier'],
                'db_instance_class': db_instance['DBInstanceClass'],
                'engine': db_instance['Engine'],
                'engine_version': db_instance['EngineVersion'],
                'status': db_instance['DBInstanceStatus'],
                'storage_gb': db_instance['AllocatedStorage'],
                'multi_az': db_instance['MultiAZ']
            })

        resources['summary']['total_rds_instances'] = len(resources['rds_instances'])
    except Exception as e:
        resources['rds_error'] = str(e)

    return resources


async def analyze_waste(region: str = 'us-east-1', cpu_threshold: float = 10) -> dict:
    """Analyze potential cost waste from underutilized resources"""

    ec2 = get_ec2_client(region)
    cloudwatch = get_cloudwatch_client(region)

    waste_analysis = {
        'region': region,
        'cpu_threshold': cpu_threshold,
        'underutilized_instances': [],
        'recommendations': []
    }

    # Get running instances
    response = ec2.describe_instances(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
    )

    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=7)  # Last 7 days

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_type = instance['InstanceType']

            # Get CPU utilization from CloudWatch
            try:
                cpu_stats = cloudwatch.get_metric_statistics(
                    Namespace='AWS/EC2',
                    MetricName='CPUUtilization',
                    Dimensions=[
                        {'Name': 'InstanceId', 'Value': instance_id}
                    ],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=86400,  # Daily
                    Statistics=['Average']
                )

                if cpu_stats['Datapoints']:
                    avg_cpu = sum(d['Average'] for d in cpu_stats['Datapoints']) / len(cpu_stats['Datapoints'])

                    if avg_cpu < cpu_threshold:
                        instance_name = ''
                        for tag in instance.get('Tags', []):
                            if tag['Key'] == 'Name':
                                instance_name = tag['Value']
                                break

                        waste_analysis['underutilized_instances'].append({
                            'instance_id': instance_id,
                            'name': instance_name,
                            'instance_type': instance_type,
                            'avg_cpu_last_7_days': round(avg_cpu, 2),
                            'launch_time': instance['LaunchTime'].isoformat(),
                            'recommendation': f'Consider stopping or downsizing - CPU usage is {round(avg_cpu, 2)}%'
                        })
            except Exception as e:
                # Skip instances where we can't get metrics
                pass

    # Generate recommendations
    if waste_analysis['underutilized_instances']:
        waste_analysis['recommendations'].append(
            f"Found {len(waste_analysis['underutilized_instances'])} underutilized instances with CPU < {cpu_threshold}%"
        )
        waste_analysis['recommendations'].append(
            "Consider stopping instances during non-business hours or downsizing instance types"
        )
    else:
        waste_analysis['recommendations'].append(
            f"No significantly underutilized instances found (CPU threshold: {cpu_threshold}%)"
        )

    return waste_analysis


async def main():
    """Run the MCP server"""
    from mcp.server.stdio import stdio_server

    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
