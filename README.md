# claude-conductor

🎼 **Claude Desktop Orchestrator** - A comprehensive system for orchestrating multiple Claude Code CLI agents with full session tracking, logging, and continuation capabilities.

## Overview

Claude Conductor transforms your Claude Desktop into a powerful multi-agent orchestration platform. It enables you to run multiple `agent -p` commands in parallel tmux sessions with complete logging, session tracking, and the ability to continue or resume work from previous sessions.

## Features

### 🎯 Core Capabilities
- **Multi-Agent Orchestration**: Run multiple Claude Code CLI agents simultaneously
- **Session Management**: Full tmux session management with unique session IDs
- **Comprehensive Logging**: Every agent execution is fully logged and tracked
- **Continuation Support**: Continue work from previous sessions with full context
- **Resume Functionality**: Resume interrupted or previous work sessions
- **Search & Analysis**: Search through session history and export data

### 🔧 Technical Features
- **Parallel Execution**: True parallel agent execution using tmux sessions
- **Session Isolation**: Each agent runs in its own isolated session
- **Context Preservation**: Full context passed between continuation sessions
- **Metadata Tracking**: Rich JSON metadata for every session
- **Export Capabilities**: Full session data export for analysis

## Quick Start

### Prerequisites

- macOS with Homebrew
- **iTerm2** (https://iterm2.com/) - Required terminal emulator
- **iTerm MCP Server** - For terminal control integration
- Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- tmux (`brew install tmux`)
- jq (`brew install jq`)

### Installation

#### Option 1: Automated Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lancejames221b/claude-conductor.git
   cd claude-conductor
   ```

2. **Run the installation script**:
   ```bash
   ./install.sh
   ```

   This script will:
   - Check and install prerequisites (tmux, jq, Claude Code CLI)
   - Set up the directory structure
   - Make scripts executable
   - Test basic functionality

#### Option 2: Manual Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lancejames221b/claude-conductor.git
   cd claude-conductor
   ```

2. **Install and configure iTerm2**:
   ```bash
   # Download and install iTerm2
   brew install --cask iterm2
   ```
   
   **Important**: You must configure the iTerm MCP server in your Claude Desktop MCP settings for terminal control functionality.

3. **Install prerequisites**:
   ```bash
   # Install Claude Code CLI
   npm install -g @anthropic-ai/claude-code
   
   # Install system dependencies
   brew install tmux jq
   ```

4. **Set up shell aliases**:
   Add to your `~/.zshrc` or `~/.bashrc`:
   ```bash
   alias agent="claude --permission-mode bypassPermissions"
   alias agentr="claude --permission-mode bypassPermissions -r"
   alias agentc="claude --permission-mode bypassPermissions -c"
   ```
   
   Then reload: `source ~/.zshrc`

5. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

6. **Test the system**:
   ```bash
   ./enhanced-tmux-manager.sh create test "What is today's date?"
   ./enhanced-tmux-manager.sh status
   ```

### Claude Desktop Integration

1. **Load the system prompt**: Use the content from `orchestrator-system-prompt.md` in your Claude Desktop
2. **Configure iTerm MCP server**: Add the iTerm MCP server to your Claude Desktop MCP settings for terminal control
3. **Start orchestrating**: Use `orchestrate:` or `🎼` to begin orchestrated workflows

#### MCP Server Configuration

The orchestrator requires the iTerm MCP server to control terminal sessions. Configure it in Claude Desktop:

1. Open Claude Desktop Settings
2. Navigate to MCP Servers section  
3. Add the iTerm MCP server configuration
4. Restart Claude Desktop

Without the iTerm MCP server, the orchestrator cannot automatically manage tmux sessions and agent execution.

## Usage

### Basic Commands

```bash
# Create a new tracked agent session
./tmux-manager.sh create "task-name" "your agent command"

# Check status of all sessions
./tmux-manager.sh status

# Get full results from a session
./tmux-manager.sh results "session-name"

# Continue from a previous session
./tmux-manager.sh continue "parent-session" "continuation prompt"

# Resume previous work
./tmux-manager.sh resume "session-id" "resume prompt"

# Search session history
./tmux-manager.sh search "search-term" [search-type]

# Export session data
./tmux-manager.sh export [output-file]

# Clean up completed sessions
./tmux-manager.sh cleanup
```

### Claude Desktop Usage

In Claude Desktop with the orchestrator system prompt loaded:

```
orchestrate: analyze this codebase and fix all linting issues in parallel
🎼 run comprehensive security audit across all systems
orchestrate: investigate performance issues then generate optimization report
```

## File Structure

```
claude-conductor/
├── tmux-manager.sh                  # Main orchestration manager
├── memory.sh                        # Memory management system
├── orchestrator-system-prompt.md    # System prompt for Claude Desktop
├── orchestrator-config.json         # Configuration template
├── tmux-utils.sh                    # Basic tmux utilities
├── activate.sh                      # Activation helper
├── install.sh                       # Installation script
├── LICENSE                          # MIT License
├── README.md                        # This file
├── examples/                        # Example workflows
│   └── ...
└── logs/                           # Session logs and metadata
    ├── task-*.log                  # Individual session logs
    ├── task-*.meta                 # Session metadata (JSON)
    ├── sessions.log                # Master session log
    ├── tasks.log                   # Master task log
    └── orchestrator.log            # Master orchestrator log
```

## Session Tracking & Logging

### Logging Structure
Every agent session generates:
- **Session Log**: Complete output from the agent (`task-*.log`)
- **Metadata**: JSON metadata with timing, status, commands (`task-*.meta`)
- **Master Logs**: Centralized logging for sessions, tasks, and orchestrator events

### Session Format
Sessions use the format: `task-[name]-[timestamp]`
- **Unique IDs**: Every session gets a unique identifier
- **Metadata Tracking**: Full JSON metadata for each session
- **Relationship Tracking**: Parent-child relationships between related sessions
- **Status Monitoring**: Real-time status updates (running, completed, failed)

## Workflows

### Continuation Workflow

```bash
# Create initial session
./tmux-manager.sh create "lint" "fix all Python linting issues"
# Session: task-lint-1754581200

# Continue with related work
./tmux-manager.sh continue "task-lint-1754581200" "now run tests on fixed code"
# Session: task-task-lint-1754581200-continue-1754581250

# Resume previous debugging session
./tmux-manager.sh resume "debug-session-123" "continue investigating database issue"
```

### Parallel Development Workflow
```bash
# Run multiple tasks simultaneously
./tmux-manager.sh create "lint" "fix all linting issues"
./tmux-manager.sh create "test" "run all unit tests"  
./tmux-manager.sh create "security" "run security scan"

# Monitor all sessions
./tmux-manager.sh status
```

### Sequential Analysis with Continuation
```bash
# Initial analysis
./tmux-manager.sh create "analyze" "analyze codebase structure"

# Continue based on results
./tmux-manager.sh continue "task-analyze-123" "generate documentation based on analysis"
```

## Advanced Usage

### Search and Resume Previous Work
```bash
# Search for previous linting sessions
./tmux-manager.sh search "linting" command

# Resume specific session
./tmux-manager.sh resume "task-lint-1754581200" "continue with additional fixes"
```

### Export and Analysis
```bash
# Export all session data
./tmux-manager.sh export session-analysis.json

# Search by status
./tmux-manager.sh search "completed" status
```

## Configuration

### Agent Aliases
The system expects these Claude Code CLI aliases in your shell:
```bash
alias agent="claude --permission-mode bypassPermissions"
alias agentr="claude --permission-mode bypassPermissions -r"
alias agentc="claude --permission-mode bypassPermissions -c"
```

### Environment
- **macOS**: Developed and tested on Apple Silicon Macs
- **Shell**: Designed for zsh/bash environments
- **Claude Code**: Requires authenticated Claude Code CLI installation

## Example Workflow with Logging

**User**: `orchestrate: fix Python linting then run tests`

**Orchestrator Response**:
```
🎼 **Task**: Fix Python linting then run tests
📋 **Plan**: Sequential execution with full logging

**Step 1**: Analyzing and fixing linting issues...
[Executing: ~/Desktop/claude-orchestrator/tmux-manager.sh create "lint" "analyze Python files and fix all linting issues"]
📊 Session: task-lint-1754581200
📄 Log: /Users/lj/Desktop/claude-orchestrator/logs/task-lint-1754581200.log

**Monitoring**: Session task-lint-1754581200 running...
**Results**: ✅ Fixed 15 linting issues in 8 files
[Session task-lint-1754581200 completed]

**Step 2**: Running tests on fixed code...
[Executing: ~/Desktop/claude-orchestrator/tmux-manager.sh continue "task-lint-1754581200" "run all Python unit tests on the files we just fixed"]
📊 Session: task-task-lint-1754581200-continue-1754581250
📄 Log: /Users/lj/Desktop/claude-orchestrator/logs/task-task-lint-1754581200-continue-1754581250.log

**Final Status**: ✅ All tasks completed
📄 **Session Summary**:
- task-lint-1754581200: Completed (linting fixed)
- task-task-lint-1754581200-continue-1754581250: Completed (tests passed)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- **Issues**: Report bugs via GitHub Issues
- **Examples**: Check the examples/ directory for workflow samples

---

**Transform your Claude Desktop into a powerful multi-agent orchestration platform! 🎼**