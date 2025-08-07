#!/bin/bash
# Claude Conductor Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎼 Claude Conductor Installation${NC}"
echo "=================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script is designed for macOS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check for Homebrew
if ! command_exists brew; then
    echo -e "${RED}❌ Homebrew not found${NC}"
    echo "Install Homebrew first: https://brew.sh/"
    exit 1
else
    echo -e "${GREEN}✅ Homebrew found${NC}"
fi

# Check for iTerm2
if [ ! -d "/Applications/iTerm.app" ]; then
    echo -e "${YELLOW}⚠️  iTerm2 not found${NC}"
    echo "Installing iTerm2..."
    brew install --cask iterm2
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ iTerm2 installed${NC}"
        echo -e "${YELLOW}📋 Note: You'll need to configure the iTerm MCP server in Claude Desktop${NC}"
    else
        echo -e "${RED}❌ Failed to install iTerm2${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ iTerm2 found${NC}"
fi
if ! command_exists claude; then
    echo -e "${YELLOW}⚠️  Claude Code CLI not found${NC}"
    echo "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Claude Code CLI installed${NC}"
    else
        echo -e "${RED}❌ Failed to install Claude Code CLI${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Claude Code CLI found${NC}"
fi

# Check for tmux
if ! command_exists tmux; then
    echo -e "${YELLOW}⚠️  tmux not found${NC}"
    echo "Installing tmux..."
    brew install tmux
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ tmux installed${NC}"
    else
        echo -e "${RED}❌ Failed to install tmux${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ tmux found${NC}"
fi

# Check for jq
if ! command_exists jq; then
    echo -e "${YELLOW}⚠️  jq not found${NC}"
    echo "Installing jq..."
    brew install jq
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ jq installed${NC}"
    else
        echo -e "${RED}❌ Failed to install jq${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ jq found${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Setting up Claude Conductor...${NC}"

# Make scripts executable
chmod +x tmux-manager.sh
chmod +x tmux-utils.sh
chmod +x activate.sh

echo -e "${GREEN}✅ Scripts made executable${NC}"

# Create logs directory if it doesn't exist
if [ ! -d "logs" ]; then
    mkdir -p logs
    touch logs/.gitkeep
    echo -e "${GREEN}✅ Logs directory created${NC}"
else
    echo -e "${GREEN}✅ Logs directory exists${NC}"
fi

# Check for agent aliases in shell
echo ""
echo -e "${BLUE}🔍 Checking shell aliases...${NC}"

if grep -q "alias agent=" ~/.zshrc 2>/dev/null || grep -q "alias agent=" ~/.bashrc 2>/dev/null; then
    echo -e "${GREEN}✅ Agent aliases found in shell configuration${NC}"
else
    echo -e "${YELLOW}⚠️  Agent aliases not found${NC}"
    echo ""
    echo "Add these aliases to your shell configuration (~/.zshrc or ~/.bashrc):"
    echo ""
    echo 'alias agent="claude --permission-mode bypassPermissions"'
    echo 'alias agentr="claude --permission-mode bypassPermissions -r"'
    echo 'alias agentc="claude --permission-mode bypassPermissions -c"'
    echo ""
    echo "Then reload your shell: source ~/.zshrc"
    echo ""
fi

# Test basic functionality
echo -e "${BLUE}🧪 Testing basic functionality...${NC}"

# Test tmux manager help
if ./tmux-manager.sh help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Tmux manager working${NC}"
else
    echo -e "${RED}❌ Tmux manager has issues${NC}"
fi

# Test basic tmux utils
if ./tmux-utils.sh help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Basic tmux utils working${NC}"
else
    echo -e "${RED}❌ Basic tmux utils has issues${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""
echo -e "${BLUE}🚀 Quick Start:${NC}"
echo "1. Test the system:"
echo "   ./tmux-manager.sh create test \"What is today's date?\""
echo ""
echo "2. Check status:"
echo "   ./tmux-manager.sh status"
echo ""
echo "3. View help:"
echo "   ./tmux-manager.sh help"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "- README.md - Main documentation"
echo "- examples/workflows.md - Usage examples"
echo "- orchestrator-system-prompt.md - Claude Desktop integration"
echo ""
echo -e "${BLUE}🔧 MCP Server Configuration:${NC}"
echo "To enable full functionality, configure the iTerm MCP server in Claude Desktop:"
echo ""
echo "1. Open Claude Desktop Settings"
echo "2. Go to MCP Servers section"
echo "3. Add the iTerm MCP server configuration"
echo "4. Restart Claude Desktop"
echo ""
echo "Without the iTerm MCP server, the orchestrator will not be able to"
echo "control terminal sessions automatically."
echo ""
