#!/bin/bash
# Enhanced Orchestrator with Comprehensive Logging and Session Tracking

# Logging configuration
LOG_DIR="/Users/lj/Desktop/claude-orchestrator/logs"
SESSION_LOG="$LOG_DIR/sessions.log"
TASK_LOG="$LOG_DIR/tasks.log"
ORCHESTRATOR_LOG="$LOG_DIR/orchestrator.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log_event() {
    local level=$1
    local message=$2
    local logfile=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$logfile"
    echo "[$timestamp] [$level] $message" >> "$ORCHESTRATOR_LOG"
}

# Function to create a unique task session with logging
create_task_session() {
    local task_name=$1
    local agent_command=$2
    local session_type=${3:-"basic"}  # basic, continue, resume
    local parent_session=${4:-""}
    
    # Generate unique session ID
    local session_id="${task_name}-$(date +%s)"
    local session_name="task-${session_id}"
    
    log_event "INFO" "Creating task session: $session_name" "$SESSION_LOG"
    log_event "INFO" "Command: claude --permission-mode bypassPermissions -p '$agent_command'" "$TASK_LOG"
    log_event "INFO" "Type: $session_type" "$TASK_LOG"
    
    if [ -n "$parent_session" ]; then
        log_event "INFO" "Parent session: $parent_session" "$TASK_LOG"
    fi
    
    # Create session metadata file
    local metadata_file="$LOG_DIR/${session_name}.meta"
    cat > "$metadata_file" << EOF
{
    "session_name": "$session_name",
    "task_name": "$task_name",
    "command": "claude --permission-mode bypassPermissions -p '$agent_command'",
    "type": "$session_type",
    "parent_session": "$parent_session",
    "created_at": "$(date -Iseconds)",
    "status": "starting",
    "pid": null
}
EOF

    # Launch tmux session with logging wrapper
    local log_file="$LOG_DIR/${session_name}.log"
    echo -e "${BLUE}🚀 Starting: $session_name${NC}"
    echo -e "${YELLOW}Command: claude --permission-mode bypassPermissions -p \"$agent_command\"${NC}"
    echo -e "${PURPLE}Log: $log_file${NC}"
    
    # Create tmux session that logs everything
    tmux new-session -d -s "$session_name" bash -c "
        echo 'Session started: $(date)' >> '$log_file';
        echo 'Command: /Volumes/SeXternal/homebrew/bin/claude --permission-mode bypassPermissions -p \"$agent_command\"' >> '$log_file';
        echo '--- OUTPUT START ---' >> '$log_file';
/Volumes/SeXternal/homebrew/bin/claude --permission-mode bypassPermissions -p '$agent_command' 2>&1 | tee -a '$log_file';
        echo '--- OUTPUT END ---' >> '$log_file';
        echo 'Session completed: $(date)' >> '$log_file';
        echo 'Exit code: \$?' >> '$log_file'
    "
    
    # Update metadata with session start
    local tmux_pid=$(tmux list-sessions -F '#{session_name} #{pane_pid}' | grep "$session_name" | cut -d' ' -f2)
    jq --arg pid "$tmux_pid" --arg status "running" --arg started "$(date -Iseconds)" \
        '.pid = $pid | .status = $status | .started_at = $started' \
        "$metadata_file" > "${metadata_file}.tmp" && mv "${metadata_file}.tmp" "$metadata_file"
    
    log_event "INFO" "Session $session_name started with PID: $tmux_pid" "$SESSION_LOG"
    
    echo "$session_name"  # Return session name for tracking
}

# Function to monitor and update session status
update_session_status() {
    local session_name=$1
    local metadata_file="$LOG_DIR/${session_name}.meta"
    
    if [ ! -f "$metadata_file" ]; then
        log_event "ERROR" "Metadata file not found: $metadata_file" "$SESSION_LOG"
        return 1
    fi
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        jq --arg status "running" --arg updated "$(date -Iseconds)" \
            '.status = $status | .updated_at = $updated' \
            "$metadata_file" > "${metadata_file}.tmp" && mv "${metadata_file}.tmp" "$metadata_file"
    else
        jq --arg status "completed" --arg completed "$(date -Iseconds)" \
            '.status = $status | .completed_at = $completed' \
            "$metadata_file" > "${metadata_file}.tmp" && mv "${metadata_file}.tmp" "$metadata_file"
        
        log_event "INFO" "Session $session_name completed" "$SESSION_LOG"
    fi
}

# Function to get session results with full logging
get_session_results() {
    local session_name=$1
    local metadata_file="$LOG_DIR/${session_name}.meta"
    local log_file="$LOG_DIR/${session_name}.log"
    
    echo -e "${BLUE}📄 Results from $session_name:${NC}"
    
    if [ -f "$metadata_file" ]; then
        local status=$(jq -r '.status' "$metadata_file")
        local created=$(jq -r '.created_at' "$metadata_file")
        local command=$(jq -r '.command' "$metadata_file")
        
        echo -e "${YELLOW}Status: $status${NC}"
        echo -e "${YELLOW}Created: $created${NC}"
        echo -e "${YELLOW}Command: $command${NC}"
        echo ""
    fi
    
    if [ -f "$log_file" ]; then
        echo -e "${GREEN}=== FULL LOG ===${NC}"
        cat "$log_file"
        echo -e "${GREEN}=== END LOG ===${NC}"
    else
        echo -e "${RED}Log file not found: $log_file${NC}"
    fi
}

# Function to create continuation task
create_continuation_task() {
    local parent_session=$1
    local continuation_prompt=$2
    local task_name="${parent_session}-continue"
    
    echo -e "${PURPLE}🔗 Creating continuation from: $parent_session${NC}"
    
    # Build continuation command using -c flag and session context
    local continuation_command="$continuation_prompt. Context from previous session $parent_session: $(get_session_summary $parent_session)"
    
    create_task_session "$task_name" "$continuation_command" "continue" "$parent_session"
}

# Function to create resume task  
create_resume_task() {
    local session_id_to_resume=$1
    local resume_prompt=$2
    local task_name="resume-${session_id_to_resume}"
    
    echo -e "${PURPLE}⏰ Creating resume task for session: $session_id_to_resume${NC}"
    
    # Build resume command using -r flag
    local resume_command="$resume_prompt"
    
    create_task_session "$task_name" "$resume_command" "resume" "$session_id_to_resume"
}

# Function to get session summary for continuation
get_session_summary() {
    local session_name=$1
    local log_file="$LOG_DIR/${session_name}.log"
    
    if [ -f "$log_file" ]; then
        # Get last 10 lines of output as summary
        tail -n 10 "$log_file" | head -n 5
    else
        echo "No log available"
    fi
}

# Function to list all sessions with detailed info
list_sessions_detailed() {
    echo -e "${BLUE}📊 All Agent Sessions (Detailed):${NC}"
    echo ""
    
    for metadata_file in "$LOG_DIR"/*.meta; do
        [ -f "$metadata_file" ] || continue
            local session_name=$(jq -r '.session_name' "$metadata_file")
            local status=$(jq -r '.status' "$metadata_file")
            local task_name=$(jq -r '.task_name' "$metadata_file")
            local created=$(jq -r '.created_at' "$metadata_file")
            local session_type=$(jq -r '.type' "$metadata_file")
            
            # Color code by status
            local status_color=$YELLOW
            case $status in
                "completed") status_color=$GREEN ;;
                "running") status_color=$BLUE ;;
                "failed") status_color=$RED ;;
            esac
            
            echo -e "${status_color}● $session_name${NC} (${session_type})"
            echo -e "  Task: $task_name"
            echo -e "  Status: ${status_color}$status${NC}"
            echo -e "  Created: $created"
            echo -e "  Log: $LOG_DIR/${session_name}.log"
            echo ""
            done
}

# Function to search sessions by criteria
search_sessions() {
    local search_term=$1
    local search_type=${2:-"all"}  # all, task_name, command, status
    
    echo -e "${BLUE}🔍 Searching sessions for: '$search_term' (type: $search_type)${NC}"
    echo ""
    
    for metadata_file in "$LOG_DIR"/*.meta; do
        [ -f "$metadata_file" ] || continue
            local match=false
            
            case $search_type in
                "task_name")
                    if jq -r '.task_name' "$metadata_file" | grep -qi "$search_term"; then
                        match=true
                    fi
                    ;;
                "command")
                    if jq -r '.command' "$metadata_file" | grep -qi "$search_term"; then
                        match=true
                    fi
                    ;;
                "status")
                    if jq -r '.status' "$metadata_file" | grep -qi "$search_term"; then
                        match=true
                    fi
                    ;;
                "all"|*)
                    if jq -r '. | tostring' "$metadata_file" | grep -qi "$search_term"; then
                        match=true
                    fi
                    ;;
            esac
            
            if [ "$match" = true ]; then
                local session_name=$(jq -r '.session_name' "$metadata_file")
                local status=$(jq -r '.status' "$metadata_file")
                local task_name=$(jq -r '.task_name' "$metadata_file")
                local command=$(jq -r '.command' "$metadata_file")
                
                echo -e "${GREEN}✓ $session_name${NC}"
                echo -e "  Task: $task_name"
                echo -e "  Status: $status"
                echo -e "  Command: $command"
                echo ""
            fi
        done
}

# Function to export session data for analysis
export_session_data() {
    local output_file=${1:-"$LOG_DIR/session_export_$(date +%Y%m%d_%H%M%S).json"}
    
    echo -e "${BLUE}📤 Exporting all session data to: $output_file${NC}"
    
    echo "[" > "$output_file"
    local first=true
    
    for metadata_file in "$LOG_DIR"/*.meta; do
        [ -f "$metadata_file" ] || continue
            if [ "$first" = false ]; then
                echo "," >> "$output_file"
            fi
            cat "$metadata_file" >> "$output_file"
            first=false
        done
    
    echo "]" >> "$output_file"
    
    echo -e "${GREEN}✓ Export complete: $output_file${NC}"
}

# Main command handler
case "$1" in
    "create")
        create_task_session "$2" "$3" "${4:-basic}" "$5"
        ;;
    "continue")
        create_continuation_task "$2" "$3"
        ;;
    "resume")
        create_resume_task "$2" "$3"
        ;;
    "status")
        list_sessions_detailed
        ;;
    "results")
        get_session_results "$2"
        ;;
    "search")
        search_sessions "$2" "$3"
        ;;
    "export")
        export_session_data "$2"
        ;;
    "update")
        if [ -n "$2" ]; then
            update_session_status "$2"
        else
            # Update all sessions
            for metadata_file in "$LOG_DIR"/*.meta; do
                [ -f "$metadata_file" ] || continue
                    session_name=$(jq -r '.session_name' "$metadata_file")
                    update_session_status "$session_name"
                done
        fi
        ;;
    "cleanup")
        echo -e "${BLUE}🧹 Cleaning up completed sessions...${NC}"
        for metadata_file in "$LOG_DIR"/*.meta; do
            [ -f "$metadata_file" ] || continue
                session_name=$(jq -r '.session_name' "$metadata_file")
                status=$(jq -r '.status' "$metadata_file")
                
                if [ "$status" = "completed" ]; then
                    if tmux has-session -t "$session_name" 2>/dev/null; then
                        tmux kill-session -t "$session_name"
                        echo -e "${GREEN}  ✓ Cleaned up $session_name${NC}"
                    fi
                fi
            done
        ;;
    "mcp")
        # MCP integration commands
        MCP_SCRIPT="./mcp-import.sh"
        if [ -f "$MCP_SCRIPT" ]; then
            shift
            "$MCP_SCRIPT" "$@"
        else
            echo -e "${RED}Error: MCP integration script not found at $MCP_SCRIPT${NC}"
            exit 1
        fi
        ;;
    "memory")
        # Memory system integration
        MEMORY_SCRIPT="./memory.sh"
        if [ -f "$MEMORY_SCRIPT" ]; then
            shift
            "$MEMORY_SCRIPT" "$@"
        else
            echo -e "${RED}Error: Memory system not found at $MEMORY_SCRIPT${NC}"
            exit 1
        fi
        ;;
    "help"|"")
        echo -e "${BLUE}Enhanced Orchestrator with Logging and Session Tracking${NC}"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo -e "${GREEN}Session Management:${NC}"
        echo "  create <n> <cmd> [type] [parent]  - Create new task session"
        echo "  continue <parent> <prompt>           - Create continuation task"
        echo "  resume <session> <prompt>            - Create resume task"
        echo "  status                               - Show all sessions with details"
        echo "  results <session>                    - Get full results and logs"
        echo "  update [session]                     - Update session status"
        echo "  cleanup                              - Clean up completed sessions"
        echo ""
        echo -e "${GREEN}Search and Analysis:${NC}"
        echo "  search <term> [type]                 - Search sessions (type: all,task_name,command,status)"
        echo "  export [file]                        - Export all session data to JSON"
        echo ""
        echo -e "${GREEN}MCP Integration:${NC}"
        echo "  mcp import                           - Import MCP servers from Claude Desktop"
        echo "  mcp list                             - List available MCP servers"
        echo "  mcp status                           - Show MCP integration status"
        echo "  mcp test <server>                    - Test MCP server availability"
        echo ""
        echo -e "${GREEN}Memory System:${NC}"
        echo "  memory store <content> [tags]        - Store a memory"
        echo "  memory recall <id>                   - Recall a memory"
        echo "  memory search <term>                 - Search memories"
        echo "  memory list                          - List all memories"
        echo "  memory help                          - Memory system help"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  $0 create lint 'fix Python linting issues'"
        echo "  $0 continue task-lint-123 'now run tests on the fixed code'"
        echo "  $0 resume session-456 'continue where we left off'"
        echo "  $0 search 'linting' command"
        echo "  $0 export /tmp/my_sessions.json"
        echo "  $0 memory store 'Database password is in .env file' 'security,database'"
        echo "  $0 memory search 'api'"
        echo ""
        echo -e "${BLUE}Logs stored in:${NC} $LOG_DIR"
        echo -e "${BLUE}Memories stored in:${NC} /Users/lj/Desktop/claude-orchestrator/memories"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
        exit 1
        ;;
esac
