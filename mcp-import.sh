#!/bin/bash
# MCP Configuration Import and Integration Script for Claude Conductor
# Imports MCP server configurations from Claude Desktop and makes them available to orchestrated agents

# Configuration paths
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
CONDUCTOR_CONFIG_DIR="/Users/lj/Desktop/claude-orchestrator/mcp-configs"
CONDUCTOR_MCP_CONFIG="$CONDUCTOR_CONFIG_DIR/mcp-servers.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure MCP config directory exists
mkdir -p "$CONDUCTOR_CONFIG_DIR"

# Function to check if Claude Desktop config exists
check_claude_desktop_config() {
    if [ ! -f "$CLAUDE_DESKTOP_CONFIG" ]; then
        echo -e "${RED}❌ Claude Desktop config not found at: $CLAUDE_DESKTOP_CONFIG${NC}"
        echo -e "${YELLOW}Make sure Claude Desktop is installed and configured with MCP servers${NC}"
        return 1
    fi
    return 0
}

# Function to validate JSON file
validate_json() {
    local file="$1"
    if ! jq . "$file" >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid JSON in $file${NC}"
        return 1
    fi
    return 0
}

# Function to import MCP servers from Claude Desktop
import_mcp_servers() {
    echo -e "${BLUE}📥 Importing MCP servers from Claude Desktop...${NC}"
    
    if ! check_claude_desktop_config; then
        return 1
    fi
    
    if ! validate_json "$CLAUDE_DESKTOP_CONFIG"; then
        return 1
    fi
    
    # Extract MCP servers configuration
    local mcp_servers=$(jq '.mcpServers // {}' "$CLAUDE_DESKTOP_CONFIG")
    
    if [ "$mcp_servers" = "{}" ]; then
        echo -e "${YELLOW}⚠️  No MCP servers found in Claude Desktop configuration${NC}"
        return 1
    fi
    
    # Create conductor MCP configuration with metadata
    cat > "$CONDUCTOR_MCP_CONFIG" << EOF
{
    "imported_from": "$CLAUDE_DESKTOP_CONFIG",
    "imported_at": "$(date -Iseconds)",
    "servers": $mcp_servers
}
EOF
    
    local server_count=$(echo "$mcp_servers" | jq 'length')
    echo -e "${GREEN}✅ Imported $server_count MCP servers${NC}"
    
    # List imported servers
    echo -e "${CYAN}📋 Imported MCP Servers:${NC}"
    echo "$mcp_servers" | jq -r 'keys[]' | while read server_name; do
        local command=$(echo "$mcp_servers" | jq -r ".[\"$server_name\"].command // \"unknown\"")
        echo -e "  ${GREEN}● $server_name${NC} - $command"
    done
    
    return 0
}

# Function to list available MCP servers
list_mcp_servers() {
    echo -e "${BLUE}📊 Available MCP Servers:${NC}"
    
    if [ ! -f "$CONDUCTOR_MCP_CONFIG" ]; then
        echo -e "${YELLOW}⚠️  No MCP servers imported. Run 'import' command first.${NC}"
        return 1
    fi
    
    local servers=$(jq '.servers' "$CONDUCTOR_MCP_CONFIG")
    local server_count=$(echo "$servers" | jq 'length')
    
    echo -e "${CYAN}Total servers: $server_count${NC}"
    echo ""
    
    echo "$servers" | jq -r 'to_entries[] | "\(.key)|\(.value.command)|\(.value.args // [] | join(" "))"' | while IFS='|' read name command args; do
        echo -e "${GREEN}🔧 $name${NC}"
        echo -e "  ${YELLOW}Command:${NC} $command"
        if [ -n "$args" ] && [ "$args" != "null" ]; then
            echo -e "  ${YELLOW}Args:${NC} $args"
        fi
        
        # Check if server has environment variables
        local env_vars=$(echo "$servers" | jq -r ".[\"$name\"].env // {} | keys | length")
        if [ "$env_vars" -gt 0 ]; then
            echo -e "  ${YELLOW}Environment:${NC} $env_vars variables configured"
        fi
        echo ""
    done
}

# Function to test MCP server availability
test_mcp_server() {
    local server_name="$1"
    
    if [ -z "$server_name" ]; then
        echo -e "${RED}❌ Server name required${NC}"
        return 1
    fi
    
    if [ ! -f "$CONDUCTOR_MCP_CONFIG" ]; then
        echo -e "${RED}❌ MCP configuration not found. Run 'import' first.${NC}"
        return 1
    fi
    
    local server_config=$(jq -r ".servers[\"$server_name\"] // null" "$CONDUCTOR_MCP_CONFIG")
    
    if [ "$server_config" = "null" ]; then
        echo -e "${RED}❌ Server '$server_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🧪 Testing MCP server: $server_name${NC}"
    
    local command=$(echo "$server_config" | jq -r '.command')
    local args=$(echo "$server_config" | jq -r '.args // [] | join(" ")')
    
    echo -e "${YELLOW}Command:${NC} $command $args"
    
    # Test if command exists
    if ! command -v "$command" >/dev/null 2>&1; then
        echo -e "${RED}❌ Command not found: $command${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Command found: $command${NC}"
    
    # TODO: Add actual MCP server connectivity test
    # This would involve starting the server and testing the MCP protocol
    
    return 0
}

# Function to generate agent command with MCP server access
generate_mcp_agent_command() {
    local server_name="$1"
    local agent_prompt="$2"
    
    if [ -z "$server_name" ] || [ -z "$agent_prompt" ]; then
        echo -e "${RED}❌ Server name and agent prompt required${NC}"
        echo "Usage: $0 agent <server-name> <prompt>"
        return 1
    fi
    
    if [ ! -f "$CONDUCTOR_MCP_CONFIG" ]; then
        echo -e "${RED}❌ MCP configuration not found. Run 'import' first.${NC}"
        return 1
    fi
    
    local server_config=$(jq -r ".servers[\"$server_name\"] // null" "$CONDUCTOR_MCP_CONFIG")
    
    if [ "$server_config" = "null" ]; then
        echo -e "${RED}❌ Server '$server_name' not found${NC}"
        echo -e "${CYAN}Available servers:${NC}"
        jq -r '.servers | keys[]' "$CONDUCTOR_MCP_CONFIG" | sed 's/^/  - /'
        return 1
    fi
    
    echo -e "${BLUE}🚀 Generating agent command with MCP server: $server_name${NC}"
    
    # Create enhanced agent command that includes MCP server context
    local enhanced_prompt="You have access to the '$server_name' MCP server. Use this server's capabilities to: $agent_prompt"
    
    echo -e "${GREEN}Enhanced prompt:${NC} $enhanced_prompt"
    
    # For now, return standard agent command - future enhancement would integrate MCP directly
    echo "/Volumes/SeXternal/homebrew/bin/claude --permission-mode bypassPermissions -p \"$enhanced_prompt\""
}

# Function to create MCP-aware orchestration script
create_mcp_orchestrator() {
    local script_name="mcp-orchestrator.sh"
    
    echo -e "${BLUE}📝 Creating MCP-aware orchestrator script: $script_name${NC}"
    
    cat > "$script_name" << 'EOF'
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
EOF
    
    chmod +x "$script_name"
    echo -e "${GREEN}✅ Created: $script_name${NC}"
}

# Function to show MCP integration status
show_status() {
    echo -e "${BLUE}📊 MCP Integration Status${NC}"
    echo ""
    
    # Check Claude Desktop config
    if check_claude_desktop_config; then
        echo -e "${GREEN}✅ Claude Desktop config found${NC}"
        local desktop_servers=$(jq '.mcpServers | length' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null || echo "0")
        echo -e "  ${CYAN}Desktop servers: $desktop_servers${NC}"
    else
        echo -e "${RED}❌ Claude Desktop config not found${NC}"
    fi
    
    # Check conductor config
    if [ -f "$CONDUCTOR_MCP_CONFIG" ]; then
        echo -e "${GREEN}✅ Conductor MCP config found${NC}"
        local conductor_servers=$(jq '.servers | length' "$CONDUCTOR_MCP_CONFIG" 2>/dev/null || echo "0")
        local imported_at=$(jq -r '.imported_at' "$CONDUCTOR_MCP_CONFIG" 2>/dev/null || echo "unknown")
        echo -e "  ${CYAN}Imported servers: $conductor_servers${NC}"
        echo -e "  ${CYAN}Last import: $imported_at${NC}"
    else
        echo -e "${YELLOW}⚠️  Conductor MCP config not found${NC}"
        echo -e "  ${CYAN}Run 'import' to import MCP servers${NC}"
    fi
    
    # Check for MCP orchestrator script
    if [ -f "mcp-orchestrator.sh" ]; then
        echo -e "${GREEN}✅ MCP orchestrator script available${NC}"
    else
        echo -e "${YELLOW}⚠️  MCP orchestrator script not found${NC}"
        echo -e "  ${CYAN}Run 'create-orchestrator' to generate it${NC}"
    fi
    
    echo ""
}

# Main command handler
case "$1" in
    "import")
        import_mcp_servers
        ;;
    "list")
        list_mcp_servers
        ;;
    "test")
        test_mcp_server "$2"
        ;;
    "agent")
        generate_mcp_agent_command "$2" "$3"
        ;;
    "create-orchestrator")
        create_mcp_orchestrator
        ;;
    "status")
        show_status
        ;;
    "help"|"")
        echo -e "${BLUE}MCP Configuration Import and Integration${NC}"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo -e "${GREEN}Configuration Management:${NC}"
        echo "  import                           - Import MCP servers from Claude Desktop"
        echo "  list                            - List available MCP servers"
        echo "  status                          - Show MCP integration status"
        echo ""
        echo -e "${GREEN}Server Management:${NC}"
        echo "  test <server-name>              - Test MCP server availability"
        echo "  agent <server-name> <prompt>    - Generate agent command with MCP access"
        echo ""
        echo -e "${GREEN}Orchestration:${NC}"
        echo "  create-orchestrator             - Create MCP-aware orchestrator script"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  $0 import"
        echo "  $0 list"
        echo "  $0 test filesystem-manager"
        echo "  $0 agent slack 'post summary to team channel'"
        echo "  $0 create-orchestrator"
        echo ""
        echo -e "${BLUE}Config files:${NC}"
        echo "  Claude Desktop: $CLAUDE_DESKTOP_CONFIG"
        echo "  Conductor: $CONDUCTOR_MCP_CONFIG"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
        exit 1
        ;;
esac
