#!/bin/bash

# Memory System for Claude Orchestrator
# Provides persistent memory storage with tagging, search, and recall capabilities

# Configuration
MEMORY_DIR="/Users/lj/Desktop/claude-orchestrator/memories"
MEMORY_INDEX="$MEMORY_DIR/.index.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Initialize index if it doesn't exist
if [ ! -f "$MEMORY_INDEX" ]; then
    echo "[]" > "$MEMORY_INDEX"
fi

# Function to generate unique memory ID
generate_memory_id() {
    echo "memory-$(date +%s)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)"
}

# Function to store a memory
store_memory() {
    local content="$1"
    local tags="${2:-}"
    local context="${3:-}"
    local memory_type="${4:-general}"
    
    if [ -z "$content" ]; then
        echo -e "${RED}Error: Memory content cannot be empty${NC}"
        return 1
    fi
    
    # Generate memory ID and timestamp
    local memory_id=$(generate_memory_id)
    local timestamp=$(date -Iseconds)
    local memory_file="$MEMORY_DIR/${memory_id}.json"
    
    # Process tags into JSON array
    local tags_json="[]"
    if [ -n "$tags" ]; then
        tags_json=$(echo "$tags" | tr ',' '\n' | jq -R . | jq -s .)
    fi
    
    # Create memory JSON object
    cat > "$memory_file" << EOF
{
    "id": "$memory_id",
    "timestamp": "$timestamp",
    "content": $(echo "$content" | jq -Rs .),
    "tags": $tags_json,
    "context": $(echo "$context" | jq -Rs .),
    "type": "$memory_type",
    "access_count": 0,
    "last_accessed": null,
    "metadata": {
        "created_by": "$(whoami)",
        "hostname": "$(hostname)",
        "working_dir": "$(pwd)"
    }
}
EOF
    
    # Update index
    local index_entry=$(jq -n \
        --arg id "$memory_id" \
        --arg timestamp "$timestamp" \
        --arg content "$content" \
        --argjson tags "$tags_json" \
        --arg type "$memory_type" \
        '{id: $id, timestamp: $timestamp, summary: ($content | split("\n")[0] | .[0:100]), tags: $tags, type: $type}')
    
    jq ". += [$index_entry]" "$MEMORY_INDEX" > "${MEMORY_INDEX}.tmp" && mv "${MEMORY_INDEX}.tmp" "$MEMORY_INDEX"
    
    echo -e "${GREEN}✓ Memory stored: $memory_id${NC}"
    echo -e "${CYAN}  Tags: $tags${NC}"
    echo -e "${CYAN}  Type: $memory_type${NC}"
    
    echo "$memory_id"
}

# Function to recall a specific memory
recall_memory() {
    local memory_id="$1"
    local verbose="${2:-false}"
    
    local memory_file="$MEMORY_DIR/${memory_id}.json"
    
    if [ ! -f "$memory_file" ]; then
        echo -e "${RED}Error: Memory not found: $memory_id${NC}"
        return 1
    fi
    
    # Update access count and last accessed timestamp
    local access_count=$(jq -r '.access_count' "$memory_file")
    access_count=$((access_count + 1))
    
    jq --arg last_accessed "$(date -Iseconds)" \
       --argjson access_count "$access_count" \
       '.last_accessed = $last_accessed | .access_count = $access_count' \
       "$memory_file" > "${memory_file}.tmp" && mv "${memory_file}.tmp" "$memory_file"
    
    if [ "$verbose" = "true" ]; then
        # Display full memory details
        echo -e "${BLUE}📝 Memory: $memory_id${NC}"
        echo -e "${YELLOW}Timestamp:${NC} $(jq -r '.timestamp' "$memory_file")"
        echo -e "${YELLOW}Type:${NC} $(jq -r '.type' "$memory_file")"
        echo -e "${YELLOW}Tags:${NC} $(jq -r '.tags | join(", ")' "$memory_file")"
        echo -e "${YELLOW}Access Count:${NC} $access_count"
        echo -e "${YELLOW}Last Accessed:${NC} $(jq -r '.last_accessed' "$memory_file")"
        echo ""
        echo -e "${GREEN}Content:${NC}"
        jq -r '.content' "$memory_file"
        
        local context=$(jq -r '.context // empty' "$memory_file")
        if [ -n "$context" ] && [ "$context" != "null" ]; then
            echo ""
            echo -e "${PURPLE}Context:${NC}"
            echo "$context"
        fi
    else
        # Just return the content
        jq -r '.content' "$memory_file"
    fi
}

# Function to search memories
search_memory() {
    local search_term="$1"
    local search_type="${2:-all}"  # all, content, tags, context, type
    local max_results="${3:-20}"
    
    echo -e "${BLUE}🔍 Searching memories for: '$search_term' (type: $search_type)${NC}"
    echo ""
    
    local results=()
    local count=0
    
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        [ $count -ge $max_results ] && break
        
        local match=false
        
        case "$search_type" in
            "content")
                if jq -r '.content' "$memory_file" | grep -qi "$search_term"; then
                    match=true
                fi
                ;;
            "tags")
                if jq -r '.tags[]' "$memory_file" 2>/dev/null | grep -qi "$search_term"; then
                    match=true
                fi
                ;;
            "context")
                if jq -r '.context // empty' "$memory_file" | grep -qi "$search_term"; then
                    match=true
                fi
                ;;
            "type")
                if jq -r '.type' "$memory_file" | grep -qi "$search_term"; then
                    match=true
                fi
                ;;
            "all"|*)
                if jq -r '. | tostring' "$memory_file" | grep -qi "$search_term"; then
                    match=true
                fi
                ;;
        esac
        
        if [ "$match" = true ]; then
            local memory_id=$(jq -r '.id' "$memory_file")
            local timestamp=$(jq -r '.timestamp' "$memory_file")
            local content_preview=$(jq -r '.content' "$memory_file" | head -n 1 | cut -c1-80)
            local tags=$(jq -r '.tags | join(", ")' "$memory_file")
            local memory_type=$(jq -r '.type' "$memory_file")
            
            echo -e "${GREEN}✓ $memory_id${NC}"
            echo -e "  ${YELLOW}Time:${NC} $timestamp"
            echo -e "  ${YELLOW}Type:${NC} $memory_type"
            echo -e "  ${YELLOW}Tags:${NC} $tags"
            echo -e "  ${YELLOW}Preview:${NC} ${content_preview}..."
            echo ""
            
            results+=("$memory_id")
            count=$((count + 1))
        fi
    done
    
    if [ ${#results[@]} -eq 0 ]; then
        echo -e "${YELLOW}No memories found matching '$search_term'${NC}"
    else
        echo -e "${CYAN}Found ${#results[@]} matching memories${NC}"
    fi
}

# Function to list memories
list_memories() {
    local filter_type="${1:-all}"  # all, recent, tagged, type:X
    local limit="${2:-20}"
    
    echo -e "${BLUE}📚 Memory List (filter: $filter_type, limit: $limit)${NC}"
    echo ""
    
    local memories=()
    
    # Collect all memory files
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        memories+=("$memory_file")
    done
    
    # Sort by timestamp (most recent first)
    IFS=$'\n' sorted_memories=($(printf '%s\n' "${memories[@]}" | while read -r file; do
        timestamp=$(jq -r '.timestamp' "$file" 2>/dev/null || echo "0")
        echo "$timestamp|$file"
    done | sort -r | cut -d'|' -f2))
    
    local count=0
    for memory_file in "${sorted_memories[@]}"; do
        [ $count -ge $limit ] && break
        [ ! -f "$memory_file" ] && continue
        
        local show=true
        
        # Apply filter
        case "$filter_type" in
            "recent")
                # Already sorted by recent
                ;;
            "tagged")
                local tags=$(jq -r '.tags | length' "$memory_file")
                [ "$tags" -eq 0 ] && show=false
                ;;
            type:*)
                local type_filter="${filter_type#type:}"
                local memory_type=$(jq -r '.type' "$memory_file")
                [ "$memory_type" != "$type_filter" ] && show=false
                ;;
            "frequently-used")
                # Sort by access count instead
                show=true
                ;;
        esac
        
        if [ "$show" = true ]; then
            local memory_id=$(jq -r '.id' "$memory_file")
            local timestamp=$(jq -r '.timestamp' "$memory_file")
            local content_preview=$(jq -r '.content' "$memory_file" | head -n 1 | cut -c1-80)
            local tags=$(jq -r '.tags | join(", ")' "$memory_file")
            local memory_type=$(jq -r '.type' "$memory_file")
            local access_count=$(jq -r '.access_count' "$memory_file")
            
            echo -e "${GREEN}[$((count + 1))] $memory_id${NC}"
            echo -e "    ${YELLOW}Time:${NC} $timestamp"
            echo -e "    ${YELLOW}Type:${NC} $memory_type | ${YELLOW}Accessed:${NC} $access_count times"
            echo -e "    ${YELLOW}Tags:${NC} ${tags:-none}"
            echo -e "    ${YELLOW}Content:${NC} ${content_preview}..."
            echo ""
            
            count=$((count + 1))
        fi
    done
    
    echo -e "${CYAN}Showing $count of $(ls -1 "$MEMORY_DIR"/memory-*.json 2>/dev/null | wc -l) total memories${NC}"
}

# Function to delete a memory
delete_memory() {
    local memory_id="$1"
    local memory_file="$MEMORY_DIR/${memory_id}.json"
    
    if [ ! -f "$memory_file" ]; then
        echo -e "${RED}Error: Memory not found: $memory_id${NC}"
        return 1
    fi
    
    # Create backup before deletion
    local backup_dir="$MEMORY_DIR/.deleted"
    mkdir -p "$backup_dir"
    cp "$memory_file" "$backup_dir/${memory_id}_$(date +%s).json"
    
    # Remove from index
    jq "map(select(.id != \"$memory_id\"))" "$MEMORY_INDEX" > "${MEMORY_INDEX}.tmp" && \
        mv "${MEMORY_INDEX}.tmp" "$MEMORY_INDEX"
    
    # Delete the memory file
    rm "$memory_file"
    
    echo -e "${GREEN}✓ Memory deleted: $memory_id${NC}"
    echo -e "${CYAN}  Backup saved in: $backup_dir${NC}"
}

# Function to export memories
export_memories() {
    local output_file="${1:-$MEMORY_DIR/export_$(date +%Y%m%d_%H%M%S).json}"
    local filter="${2:-all}"
    
    echo -e "${BLUE}📤 Exporting memories to: $output_file${NC}"
    
    local memories=[]
    
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        
        local include=true
        
        if [ "$filter" != "all" ]; then
            # Apply filter logic here if needed
            case "$filter" in
                type:*)
                    local type_filter="${filter#type:}"
                    local memory_type=$(jq -r '.type' "$memory_file")
                    [ "$memory_type" != "$type_filter" ] && include=false
                    ;;
            esac
        fi
        
        if [ "$include" = true ]; then
            memories=$(echo "$memories" | jq ". += [$(cat "$memory_file")]")
        fi
    done
    
    echo "$memories" > "$output_file"
    
    local count=$(echo "$memories" | jq 'length')
    echo -e "${GREEN}✓ Exported $count memories${NC}"
}

# Function to analyze memory usage
analyze_memories() {
    echo -e "${BLUE}📊 Memory System Analysis${NC}"
    echo ""
    
    local total_memories=$(ls -1 "$MEMORY_DIR"/memory-*.json 2>/dev/null | wc -l)
    local total_size=$(du -sh "$MEMORY_DIR" 2>/dev/null | cut -f1)
    
    echo -e "${YELLOW}Total Memories:${NC} $total_memories"
    echo -e "${YELLOW}Storage Used:${NC} $total_size"
    echo ""
    
    # Type distribution
    echo -e "${CYAN}Memory Types:${NC}"
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        jq -r '.type' "$memory_file"
    done | sort | uniq -c | while read count type; do
        echo "  $type: $count"
    done
    echo ""
    
    # Most used tags
    echo -e "${CYAN}Top Tags:${NC}"
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        jq -r '.tags[]' "$memory_file" 2>/dev/null
    done | sort | uniq -c | sort -rn | head -10 | while read count tag; do
        echo "  $tag: $count"
    done
    echo ""
    
    # Most accessed memories
    echo -e "${CYAN}Most Accessed Memories:${NC}"
    for memory_file in "$MEMORY_DIR"/memory-*.json; do
        [ -f "$memory_file" ] || continue
        local memory_id=$(jq -r '.id' "$memory_file")
        local access_count=$(jq -r '.access_count' "$memory_file")
        local content_preview=$(jq -r '.content' "$memory_file" | head -n 1 | cut -c1-50)
        echo "$access_count|$memory_id|$content_preview"
    done | sort -rn | head -5 | while IFS='|' read count id preview; do
        echo "  $id ($count accesses): ${preview}..."
    done
}

# Main command handler
case "$1" in
    "store")
        shift
        store_memory "$@"
        ;;
    "recall")
        recall_memory "$2" "${3:-false}"
        ;;
    "search")
        search_memory "$2" "${3:-all}" "${4:-20}"
        ;;
    "list")
        list_memories "${2:-all}" "${3:-20}"
        ;;
    "delete")
        delete_memory "$2"
        ;;
    "export")
        export_memories "$2" "${3:-all}"
        ;;
    "analyze")
        analyze_memories
        ;;
    "help"|"")
        echo -e "${BLUE}Memory System for Claude Orchestrator${NC}"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo -e "${GREEN}Core Functions:${NC}"
        echo "  store <content> [tags] [context] [type]  - Store a new memory"
        echo "  recall <memory-id> [verbose]             - Recall a specific memory"
        echo "  search <term> [type] [limit]             - Search memories"
        echo "  list [filter] [limit]                    - List memories"
        echo ""
        echo -e "${GREEN}Management:${NC}"
        echo "  delete <memory-id>                       - Delete a memory"
        echo "  export [file] [filter]                   - Export memories to JSON"
        echo "  analyze                                  - Analyze memory usage"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  $0 store 'API endpoint is at /api/v1/data' 'api,endpoints,reference'"
        echo "  $0 search 'database' content"
        echo "  $0 list tagged 10"
        echo "  $0 recall memory-12345-abcd true"
        echo ""
        echo -e "${YELLOW}Search Types:${NC} all, content, tags, context, type"
        echo -e "${YELLOW}List Filters:${NC} all, recent, tagged, type:X, frequently-used"
        echo ""
        echo -e "${BLUE}Memory Storage:${NC} $MEMORY_DIR"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
        exit 1
        ;;
esac