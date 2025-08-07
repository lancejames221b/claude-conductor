#!/bin/bash
# Orchestrator Tmux Management Utilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display active agent sessions
show_sessions() {
    echo -e "${BLUE}📊 Active Agent Sessions:${NC}"
    sessions=$(tmux list-sessions 2>/dev/null | grep "task-")
    if [ -z "$sessions" ]; then
        echo -e "${YELLOW}No active agent tasks${NC}"
    else
        echo "$sessions" | while read session; do
            session_name=$(echo "$session" | cut -d: -f1)
            echo -e "${GREEN}  ✓ $session_name${NC}"
        done
    fi
    echo ""
}

# Function to get results from a completed session
get_results() {
    local session_name=$1
    echo -e "${BLUE}📄 Results from $session_name:${NC}"
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}Session still running...${NC}"
    else
        # Try to capture from a detached session
        results=$(tmux capture-pane -t "$session_name" -p 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "$results"
        else
            echo -e "${RED}Session not found or already cleaned up${NC}"
        fi
    fi
    echo ""
}

# Function to clean up completed sessions
cleanup_sessions() {
    echo -e "${BLUE}🧹 Cleaning up completed agent sessions...${NC}"
    
    # Find all task sessions that are no longer running
    all_sessions=$(tmux list-sessions 2>/dev/null | grep "task-" | cut -d: -f1)
    
    if [ -z "$all_sessions" ]; then
        echo -e "${YELLOW}No agent sessions to clean up${NC}"
        return
    fi
    
    for session in $all_sessions; do
        # Check if session exists and get its status
        if ! tmux has-session -t "$session" 2>/dev/null; then
            echo -e "${YELLOW}  Session $session already gone${NC}"
            continue
        fi
        
        # Kill the session
        if tmux kill-session -t "$session" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Cleaned up $session${NC}"
        else
            echo -e "${RED}  ✗ Failed to clean up $session${NC}"
        fi
    done
    echo ""
}

# Function to monitor all active sessions
monitor_sessions() {
    echo -e "${BLUE}🔍 Monitoring active agent sessions...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    echo ""
    
    while true; do
        active_sessions=$(tmux list-sessions 2>/dev/null | grep "task-" | wc -l)
        if [ "$active_sessions" -eq 0 ]; then
            echo -e "${GREEN}✅ All agent tasks completed${NC}"
            break
        fi
        
        echo -e "${BLUE}📊 Active tasks: $active_sessions${NC}"
        tmux list-sessions 2>/dev/null | grep "task-" | while read session; do
            session_name=$(echo "$session" | cut -d: -f1)
            echo -e "${YELLOW}  ⏳ $session_name${NC}"
        done
        
        sleep 3
        echo "" # Clear line for next update
    done
}

# Function to launch a new agent task
launch_task() {
    local task_name=$1
    local agent_command=$2
    
    if [ -z "$task_name" ] || [ -z "$agent_command" ]; then
        echo -e "${RED}Usage: launch_task <task-name> <agent-command>${NC}"
        echo -e "${YELLOW}Example: launch_task lint 'fix all Python linting issues'${NC}"
        return 1
    fi
    
    local session_name="task-$task_name"
    echo -e "${BLUE}🚀 Launching: $session_name${NC}"
    echo -e "${YELLOW}Command: agent -p \"$agent_command\"${NC}"
    
    if tmux new-session -d -s "$session_name" "agent -p '$agent_command'"; then
        echo -e "${GREEN}✓ Session $session_name started${NC}"
    else
        echo -e "${RED}✗ Failed to start session $session_name${NC}"
    fi
    echo ""
}

# Main command handler
case "$1" in
    "status"|"show")
        show_sessions
        ;;
    "results")
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: $0 results <session-name>${NC}"
            exit 1
        fi
        get_results "$2"
        ;;
    "cleanup"|"clean")
        cleanup_sessions
        ;;
    "monitor")
        monitor_sessions
        ;;
    "launch")
        launch_task "$2" "$3"
        ;;
    "help"|"")
        echo -e "${BLUE}Orchestrator Tmux Management Utilities${NC}"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo -e "${GREEN}Commands:${NC}"
        echo "  status/show           - Show active agent sessions"
        echo "  results <session>     - Get results from a session"
        echo "  cleanup/clean         - Clean up completed sessions"
        echo "  monitor               - Monitor active sessions (Ctrl+C to stop)"
        echo "  launch <name> <cmd>   - Launch new agent task"
        echo "  help                  - Show this help"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  $0 status"
        echo "  $0 launch lint 'fix all Python files'"
        echo "  $0 results task-lint"
        echo "  $0 monitor"
        echo "  $0 cleanup"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
        exit 1
        ;;
esac
