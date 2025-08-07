# claude-conductor

🎼 **Enhanced Claude Desktop Orchestrator** - A comprehensive system for orchestrating multiple Claude Code CLI agents with full session tracking, logging, and continuation capabilities.

## Overview

Claude Conductor transforms your Claude Desktop into a powerful multi-agent orchestration platform. It enables you to run multiple `agent -p` commands in parallel tmux sessions with complete logging, session tracking, and the ability to continue or resume work from previous sessions.

## Features

### 🎯 **Core Capabilities**
- **Multi-Agent Orchestration**: Run multiple Claude Code CLI agents simultaneously
- **Session Management**: Full tmux session management with unique session IDs
- **Comprehensive Logging**: Every agent execution is fully logged and tracked
- **Continuation Support**: Continue work from previous sessions with full context
- **Resume Functionality**: Resume interrupted or previous work sessions
- **Search & Analysis**: Search through session history and export data

### 🔧 **Technical Features**
- **Parallel Execution**: True parallel agent execution using tmux sessions
- **Session Isolation**: Each agent runs in its own isolated session
- **Context Preservation**: Full context passed between continuation sessions
- **Metadata Tracking**: Rich JSON metadata for every session
- **Export Capabilities**: Full session data export for analysis

## Quick Start

### Prerequisites

- macOS with Homebrew
- Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- tmux (`brew install tmux`)
- jq (`brew install jq`)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lancejames221b/claude-conductor.git
   cd claude-conductor
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

3. **Test the system**:
   ```bash
   ./enhanced-tmux-manager.sh create test "What is today's date?"
   ./enhanced-tmux-manager.sh status
   ```

### Claude Desktop Integration

1. **Load the system prompt**: Use the content from `orchestrator-system-prompt.md` in your Claude Desktop
2. **Start orchestrating**: Use `orchestrate:` or `🎼` to begin orchestrated workflows

## Usage

### Basic Commands

```bash
# Create a new tracked agent session
./enhanced-tmux-manager.sh create "task-name" "your agent command"

# Check status of all sessions
./enhanced-tmux-manager.sh status

# Get full results from a session
./enhanced-tmux-manager.sh results "session-name"

# Continue from a previous session
./enhanced-tmux-manager.sh continue "parent-session" "continuation prompt"

# Resume previous work
./enhanced-tmux-manager.sh resume "session-id" "resume prompt"

# Search session history
./enhanced-tmux-manager.sh search "search-term" [search-type]

# Export session data
./enhanced-tmux-manager.sh export [output-file]

# Clean up completed sessions
./enhanced-tmux-manager.sh cleanup
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
├── enhanced-tmux-manager.sh          # Main orchestration manager
├── orchestrator-system-prompt.md     # System prompt for Claude Desktop
├── orchestrator-config.json          # Configuration template
├── tmux-utils.sh                     # Basic tmux utilities
├── activate.sh                       # Activation helper
├── logs/                             # Session logs and metadata
│   ├── task-*.log                   # Individual session logs
│   ├── task-*.meta                  # Session metadata (JSON)
│   ├── sessions.log                 # Master session log
│   ├── tasks.log                    # Master task log
│   └── orchestrator.log             # Master orchestrator log
├── README.md                         # This file
└── ENHANCED-README.md               # Detailed feature documentation
```

## Logging Structure

Every agent session generates:
- **Session Log**: Complete output from the agent (`task-*.log`)
- **Metadata**: JSON metadata with timing, status, commands (`task-*.meta`)
- **Master Logs**: Centralized logging for sessions, tasks, and orchestrator events

## Session Tracking

Sessions use the format: `task-[name]-[timestamp]`
- **Unique IDs**: Every session gets a unique identifier
- **Metadata Tracking**: Full JSON metadata for each session
- **Relationship Tracking**: Parent-child relationships between related sessions
- **Status Monitoring**: Real-time status updates (running, completed, failed)

## Continuation Workflow

```bash
# Create initial session
./enhanced-tmux-manager.sh create "lint" "fix all Python linting issues"
# Session: task-lint-1754581200

# Continue with related work
./enhanced-tmux-manager.sh continue "task-lint-1754581200" "now run tests on fixed code"
# Session: task-task-lint-1754581200-continue-1754581250

# Resume previous debugging session
./enhanced-tmux-manager.sh resume "debug-session-123" "continue investigating database issue"
```

## Examples

### Parallel Development Workflow
```bash
# Run multiple tasks simultaneously
./enhanced-tmux-manager.sh create "lint" "fix all linting issues"
./enhanced-tmux-manager.sh create "test" "run all unit tests"  
./enhanced-tmux-manager.sh create "security" "run security scan"

# Monitor all sessions
./enhanced-tmux-manager.sh status
```

### Sequential Analysis with Continuation
```bash
# Initial analysis
./enhanced-tmux-manager.sh create "analyze" "analyze codebase structure"

# Continue based on results
./enhanced-tmux-manager.sh continue "task-analyze-123" "generate documentation based on analysis"
```

## Advanced Usage

### Search and Resume Previous Work
```bash
# Search for previous linting sessions
./enhanced-tmux-manager.sh search "linting" command

# Resume specific session
./enhanced-tmux-manager.sh resume "task-lint-1754581200" "continue with additional fixes"
```

### Export and Analysis
```bash
# Export all session data
./enhanced-tmux-manager.sh export session-analysis.json

# Search by status
./enhanced-tmux-manager.sh search "completed" status
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
- **Documentation**: See ENHANCED-README.md for detailed features
- **Examples**: Check the examples/ directory for workflow samples

---

**Transform your Claude Desktop into a powerful multi-agent orchestration platform! 🎼**
