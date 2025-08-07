#!/bin/bash
# MCP-Aware Claude Conductor Orchestrator
# Automatically integrates available MCP servers with agent commands

MCP_CONFIG="/Users/lj/Desktop/claude-orchestrator/mcp-configs/mcp-servers.json"

# Function to run agent with MCP server integration
run_agent_with_mcp() {
    local servers="$1"
    local prompt="$2"
    
    if [ ! -f "$MCP_CONFIG" ]; then
        echo "❌ MCP configuration not found. Run mcp-import.sh first."
        return 1
    fi
    
    # Enhanced prompt that mentions available MCP servers
    local available_servers=""
    if [ -n "$servers" ]; then
        available_servers="You have access to these MCP servers: $servers. Use them as needed to complete the task. "
    else
        # List all available servers
        available_servers="You have access to these MCP servers: $(jq -r '.servers | keys | join(", ")' "$MCP_CONFIG"). Use them as needed to complete the task. "
    fi
    
    local enhanced_prompt="${available_servers}${prompt}"
    
    # Run the enhanced agent command
    /Volumes/SeXternal/homebrew/bin/claude --permission-mode bypassPermissions -p "$enhanced_prompt"
}

# Main command handler
case "$1" in
    "run")
        run_agent_with_mcp "$2" "$3"
        ;;
    "help"|"")
        echo "MCP-Aware Claude Conductor Orchestrator"
        echo ""
        echo "Usage: $0 run [servers] <prompt>"
        echo ""
        echo "Examples:"
        echo "  $0 run 'filesystem,slack' 'analyze project files and post summary to team channel'"
        echo "  $0 run '' 'perform system analysis using all available MCP servers'"
        ;;
    *)
        echo "Unknown command. Use 'help' for usage."
        ;;
esac
