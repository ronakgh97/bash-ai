#!/bin/bash

for cmd in curl jq; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is not installed."; exit 1; }
done

set -euo pipefail
IFS=$'\n\t'

BASE_URL="https://live.ronakratnadip.xyz/api/v1"
TOKEN_FILE="$HOME/.spai-token"
SESSION_FILE="$HOME/.spai-session"
SESSIONS_DIR="$HOME/.spai-sessions"
VERSION="0.1.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

log_info() { echo -e "${BLUE} $1${NC}"; }
log_success() { echo -e "${GREEN}👍 $1${NC}"; }
log_warning() { echo -e "${YELLOW}🙌 $1${NC}"; }
log_error() { echo -e "${RED}👎 $1${NC}"; }

get_token() { [[ -f "$TOKEN_FILE" ]] && cat "$TOKEN_FILE" || echo ""; }
save_token() { echo -n "$1" > "$TOKEN_FILE"; chmod 600 "$TOKEN_FILE" 2>/dev/null || true; }
clear_token() { rm -f "$TOKEN_FILE"; }

get_current_session() { [[ -f "$SESSION_FILE" ]] && cat "$SESSION_FILE" || echo ""; }
save_current_session() { echo -n "$1" > "$SESSION_FILE"; chmod 600 "$SESSION_FILE" 2>/dev/null || true; }
clear_current_session() { rm -f "$SESSION_FILE"; }

# Initialize sessions directory
init_sessions_dir() {
    [[ ! -d "$SESSIONS_DIR" ]] && mkdir -p "$SESSIONS_DIR" && chmod 700 "$SESSIONS_DIR"
}

# Save session details locally
save_session_details() {
    local session_id="$1"
    local session_name="$2"
    local model="$3"
    init_sessions_dir
    echo "{\"sessionId\":\"$session_id\",\"name\":\"$session_name\",\"model\":\"$model\",\"created\":\"$(date -Iseconds)\"}" > "$SESSIONS_DIR/$session_id.json"
    chmod 600 "$SESSIONS_DIR/$session_id.json"
}

CMD=$1; shift

case "$CMD" in
    version)
        echo "spai version $VERSION"
        ;;

    user)
        SUB=$1; shift
        case "$SUB" in
            create)
                USERNAME=${1:-demo}
                PASSWORD=${2:-123456}
                GMAIL=${3:-demo@example.com}
                
                log_info "Registering user: $USERNAME <$GMAIL>"
                RESPONSE=$(curl -s -X POST "$BASE_URL/users/register" \
                    -H "Content-Type: application/json" \
                    -d "{\"userName\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"gmail\":\"$GMAIL\"}")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    USER_DATA=$(echo "$RESPONSE" | jq -r '.data')
                    USER_ID=$(echo "$USER_DATA" | jq -r '.userId')
                    SESSION_COUNT=$(echo "$USER_DATA" | jq -r '.sessionCount')
                    IS_VERIFIED=$(echo "$USER_DATA" | jq -r '.isVerified')
                    
                    log_success "User created successfully!"
                    echo -e "${CYAN}User ID:${NC} $USER_ID"
                    echo -e "${CYAN}Sessions:${NC} $SESSION_COUNT"
                    echo -e "${CYAN}Verified:${NC} $IS_VERIFIED"
                    
                    if [[ "$IS_VERIFIED" == "false" ]]; then
                        log_warning "Account not verified. Use: $0 verify send"
                    fi
                else
                    log_error "Registration failed"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                    exit 1
                fi
                ;;
                
            profile)
                TOKEN=$(get_token)
                [[ -z "$TOKEN" ]] && log_error "Not logged in!" && exit 1
                
                log_info "Getting user profile..."
                RESPONSE=$(curl -s -X GET "$BASE_URL/users/profile" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    USER_DATA=$(echo "$RESPONSE" | jq -r '.data')
                    USERNAME=$(echo "$USER_DATA" | jq -r '.userName')
                    GMAIL=$(echo "$USER_DATA" | jq -r '.gmail')
                    USER_ID=$(echo "$USER_DATA" | jq -r '.userId')
                    SESSION_COUNT=$(echo "$USER_DATA" | jq -r '.sessionCount')
                    IS_VERIFIED=$(echo "$USER_DATA" | jq -r '.isVerified')
                    ROLES=$(echo "$USER_DATA" | jq -r '.roles | join(", ")')
                    
                    echo "=== User Profile ==="
                    echo -e "${CYAN}Username:${NC} $USERNAME"
                    echo -e "${CYAN}Email:${NC} $GMAIL"
                    echo -e "${CYAN}User ID:${NC} $USER_ID"
                    echo -e "${CYAN}Sessions:${NC} $SESSION_COUNT"
                    echo -e "${CYAN}Verified:${NC} $IS_VERIFIED"
                    echo -e "${CYAN}Roles:${NC} $ROLES"
                else
                    log_error "Failed to get profile"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                    exit 1
                fi
                ;;
                
            *)
                log_error "Unknown user subcommand: $SUB"
                echo "Available: create, profile"
                exit 1
                ;;
        esac
        ;;

    login)
        USERNAME=${1:-demo}
        PASSWORD=${2:-123456}
        
        log_info "Logging in as $USERNAME"
        RESPONSE=$(curl -s -X POST "$BASE_URL/users/login" \
            -H "Content-Type: application/json" \
            -d "{\"userName\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")
        
        if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
            TOKEN=$(echo "$RESPONSE" | jq -r '.data.token')
            USER_DATA=$(echo "$RESPONSE" | jq -r '.data.user')
            USERNAME=$(echo "$USER_DATA" | jq -r '.userName')
            SESSION_COUNT=$(echo "$USER_DATA" | jq -r '.sessionCount')
            IS_VERIFIED=$(echo "$USER_DATA" | jq -r '.isVerified')
            
            save_token "$TOKEN"
            log_success "Login successful"
            echo -e "${CYAN}Welcome:${NC} $USERNAME"
            echo -e "${CYAN}Sessions:${NC} $SESSION_COUNT"
            echo -e "${CYAN}Verified:${NC} $IS_VERIFIED"
            
            if [[ "$IS_VERIFIED" == "false" ]]; then
                log_warning "Account not verified. Use: $0 verify send"
            fi
        else
            log_error "Login failed"
            #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
            exit 1
        fi
        ;;

    logout)
        clear_token
        clear_current_session
        rm -rf "$SESSIONS_DIR" 2>/dev/null
        log_success "Logged out and cleared all local data"
        ;;

    verify)
        SUB=$1; shift
        TOKEN=$(get_token)
        [[ -z "$TOKEN" ]] && log_error "Not logged in!" && exit 1
        
        case "$SUB" in
            send)
                log_info "Sending verification code..."
                RESPONSE=$(curl -s -X GET "$BASE_URL/verify/send" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
                    log_success "$MESSAGE"
                else
                    log_error "Failed to send verification code"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                    exit 1
                fi
                ;;
                
            check)
                CODE="$1"
                [[ -z "$CODE" ]] && log_error "Usage: $0 verify check <code>" && exit 1
                
                log_info "Verifying code: $CODE"
                RESPONSE=$(curl -s -X POST "$BASE_URL/verify/check/$CODE" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
                    log_success "$MESSAGE"
                else
                    log_error "Verification failed"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                    exit 1
                fi
                ;;
                
            *)
                log_error "Unknown verify subcommand: $SUB"
                echo "Available: send, check"
                exit 1
                ;;
        esac
        ;;

    session)
        SUB=$1; shift
        TOKEN=$(get_token)
        [[ -z "$TOKEN" ]] && log_error "Not logged in!" && exit 1
        
        case "$SUB" in
            create)
                SESSION_NAME=${1:-"session-$(date +%H%M%S)"}
                MODEL=${2:-"qwen/qwen3-4b-thinking-2507"}
                
                log_info "Creating session: $SESSION_NAME with model: $MODEL"
                RESPONSE=$(curl -s -X POST "$BASE_URL/sessions/create" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "{\"nameSession\":\"$SESSION_NAME\",\"model\":\"$MODEL\"}")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    SESSION_DATA=$(echo "$RESPONSE" | jq -r '.data')
                    SESSION_ID=$(echo "$SESSION_DATA" | jq -r '.sessionId')
                    SESSION_NAME=$(echo "$SESSION_DATA" | jq -r '.nameSession')
                    MODEL=$(echo "$SESSION_DATA" | jq -r '.model')
                    DATETIME=$(echo "$SESSION_DATA" | jq -r '.dateTime')
                    
                    save_session_details "$SESSION_ID" "$SESSION_NAME" "$MODEL"
                    save_current_session "$SESSION_ID"
                    
                    log_success "Session created and activated!"
                    echo -e "${CYAN}Session ID:${NC} $SESSION_ID"
                    echo -e "${CYAN}Name:${NC} $SESSION_NAME"
                    echo -e "${CYAN}Model:${NC} $MODEL"
                    echo -e "${CYAN}Created:${NC} $DATETIME"
                else
                    log_error "Session creation failed"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                    exit 1
                fi
                ;;
            
            list)
                log_info "Fetching sessions from server..."
                RESPONSE=$(curl -s -X GET "$BASE_URL/sessions" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    current_session=$(get_current_session)
                    echo "=== Your Sessions ==="
                    
                    SESSIONS=$(echo "$RESPONSE" | jq -r '.data')
                    SESSION_COUNT=$(echo "$SESSIONS" | jq length)
                    
                    if [[ "$SESSION_COUNT" -gt 0 ]]; then
                        echo "$SESSIONS" | jq -r '.[] | @json' | while read -r session; do
                            session_id=$(echo "$session" | jq -r '.sessionId')
                            session_name=$(echo "$session" | jq -r '.nameSession')
                            model=$(echo "$session" | jq -r '.model')
                            datetime=$(echo "$session" | jq -r '.dateTime')
                            message_count=$(echo "$session" | jq -r '.messageCount')
                            
                            if [[ "$session_id" == "$current_session" ]]; then
                                echo -e "${GREEN}▶ $session_name${NC} (${CYAN}$session_id${NC})"
                            else
                                echo -e "  $session_name (${GRAY}$session_id${NC})"
                            fi
                            echo -e "    Model: $model | Messages: $message_count | Created: $datetime"
                        done
                    else
                        log_warning "No sessions found"
                    fi
                else
                    log_error "Failed to fetch sessions"
                    #echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
                fi
                ;;
            
            switch)
                SESSION_ID="$1"
                [[ -z "$SESSION_ID" ]] && log_error "Usage: $0 session switch <session_id>" && exit 1
                
                # Verify session exists on server
                RESPONSE=$(curl -s -X GET "$BASE_URL/sessions" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")
                
                if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                    SESSION_EXISTS=$(echo "$RESPONSE" | jq -r --arg sid "$SESSION_ID" '.data[] | select(.sessionId == $sid) | .sessionId')
                    
                    if [[ -n "$SESSION_EXISTS" ]]; then
                        SESSION_NAME=$(echo "$RESPONSE" | jq -r --arg sid "$SESSION_ID" '.data[] | select(.sessionId == $sid) | .nameSession')
                        save_current_session "$SESSION_ID"
                        log_success "Switched to session: $SESSION_NAME ($SESSION_ID)"
                    else
                        log_error "Session not found: $SESSION_ID"
                        exit 1
                    fi
                else
                    log_error "Failed to verify session"
                    exit 1
                fi
                ;;
            
            current)
                current_session=$(get_current_session)
                if [[ -n "$current_session" ]]; then
                    # Get session details from server
                    RESPONSE=$(curl -s -X GET "$BASE_URL/sessions" \
                        -H "Authorization: Bearer $TOKEN" \
                        -H "Content-Type: application/json")
                    
                    if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                        SESSION_DATA=$(echo "$RESPONSE" | jq -r --arg sid "$current_session" '.data[] | select(.sessionId == $sid)')
                        
                        if [[ -n "$SESSION_DATA" && "$SESSION_DATA" != "null" ]]; then
                            session_name=$(echo "$SESSION_DATA" | jq -r '.nameSession')
                            model=$(echo "$SESSION_DATA" | jq -r '.model')
                            message_count=$(echo "$SESSION_DATA" | jq -r '.messageCount')
                            
                            echo -e "${GREEN}Current Session:${NC}"
                            echo -e "  ${CYAN}Name:${NC} $session_name"
                            echo -e "  ${CYAN}ID:${NC} $current_session"
                            echo -e "  ${CYAN}Model:${NC} $model"
                            echo -e "  ${CYAN}Messages:${NC} $message_count"
                        else
                            log_warning "Current session not found on server"
                            clear_current_session
                        fi
                    else
                        log_error "Failed to get session details"
                    fi
                else
                    log_warning "No active session"
                fi
                ;;
            
            *)
                log_error "Unknown session subcommand: $SUB"
                echo "Available: create, list, switch, current"
                exit 1
                ;;
        esac
        ;;

    chat)
        PROMPT="$*"
        [[ -z "$PROMPT" ]] && log_error "Usage: $0 chat \"message\"" && exit 1

        TOKEN=$(get_token)
        SESSION_ID=$(get_current_session)
        [[ -z "$TOKEN" ]] && log_error "Not logged in" && exit 1
        [[ -z "$SESSION_ID" ]] && log_error "No active session. Use: $0 session list" && exit 1

        # Get session name from server
        RESPONSE=$(curl -s -X GET "$BASE_URL/sessions" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json")
        
        SESSION_NAME="Unknown"
        if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
            SESSION_NAME=$(echo "$RESPONSE" | jq -r --arg sid "$SESSION_ID" '.data[] | select(.sessionId == $sid) | .nameSession // "Unknown"')
        fi

        echo -e "${BLUE}Session:${NC} $SESSION_NAME (${GRAY}$SESSION_ID${NC})"
        echo -e "${BLUE}You:${NC} $PROMPT"
        echo -e "${BLUE}Assistant:${NC}"
        echo "--------------------------------"

        buffer=""
        thinking_mode=false
        think_started=false
        
        curl -sN --no-buffer -X POST "$BASE_URL/chat/$SESSION_ID" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: text/event-stream" \
            -d "{\"prompt\":\"$PROMPT\"}" \
        | while IFS= read -r line; do
            if [[ "$line" =~ ^data:(.*)$ ]]; then
                content="${BASH_REMATCH[1]}"
                [[ -z "$content" ]] && continue
                
                case "$content" in
                    "<think>")
                        [[ -n "$buffer" ]] && printf "%s" "$buffer"
                        buffer=""
                        thinking_mode=true
                        think_started=false
                        continue
                        ;;
                    "</think>")
                        [[ -n "$buffer" ]] && printf "${GRAY}%s${NC}" "$buffer"
                        buffer=""
                        thinking_mode=false
                        echo -e "\n${CYAN}--- End Thinking ---${NC}"
                        continue
                        ;;
                esac
                
                if [[ "$thinking_mode" == true ]]; then
                    if [[ "$think_started" == false ]]; then
                        echo -e "\n${CYAN}--- Thinking ---${NC}"
                        think_started=true
                    fi
                    buffer+="$content"
                    if [[ ${#buffer} -ge 4 ]] || [[ "$content" == " " ]]; then
                        printf "${GRAY}%s${NC}" "$buffer"
                        buffer=""
                    fi
                else
                    buffer+="$content"
                    if [[ ${#buffer} -ge 4 ]] || [[ "$content" == " " ]]; then
                        printf "%s" "$buffer"
                        buffer=""
                    fi
                fi
            fi
        done
        
        if [[ -n "$buffer" ]]; then
            if [[ "$thinking_mode" == true ]]; then
                printf "${GRAY}%s${NC}" "$buffer"
                echo -e "\n${CYAN}--- End Thinking ---${NC}"
            else
                printf "%s" "$buffer"
            fi
        fi
        
        echo
        echo "--------------------------------"
        ;;

    status)
        TOKEN=$(get_token)
        echo "=== Status ==="
        
        if [[ -n "$TOKEN" ]]; then
            RESPONSE=$(curl -s -X GET "$BASE_URL/users/profile" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json")
                
            if echo "$RESPONSE" | jq -e '.success == true' >/dev/null 2>&1; then
                USER_DATA=$(echo "$RESPONSE" | jq -r '.data')
                USERNAME=$(echo "$USER_DATA" | jq -r '.userName')
                IS_VERIFIED=$(echo "$USER_DATA" | jq -r '.isVerified')
                SESSION_COUNT=$(echo "$USER_DATA" | jq -r '.sessionCount')
                
                log_success "Logged in as: $USERNAME"
                echo -e "${CYAN}Verified:${NC} $IS_VERIFIED"
                echo -e "${CYAN}Total Sessions:${NC} $SESSION_COUNT"
            else
                log_warning "Token may be invalid"
            fi
        else
            log_warning "Not logged in"
        fi
        
        SESSION_ID=$(get_current_session)
        [[ -n "$SESSION_ID" ]] && log_success "Active session: $SESSION_ID" || log_warning "No active session"
        ;;

    health)
        log_info "Checking API health..."
        if curl -s --fail "$BASE_URL/health" > /dev/null 2>&1; then
            echo "✅ Server's up and running!!"
        else
            log_error "❌ Unable to connect to API"
            exit 1
        fi
        ;;

    flush)
        log_info "Flushing all local data..."
        rm -f "$TOKEN_FILE" "$SESSION_FILE" 2>/dev/null || true
        rm -rf "$SESSIONS_DIR" 2>/dev/null || true
        log_success "All local SPAI data has been cleared."
        ;;

    *)
        log_error "Unknown command: $CMD"
        echo "Usage:"
        echo ""
        echo "User Management:"
        echo "  $0 user create [username] [password] [email]"
        echo "  $0 user profile"
        echo "  $0 login [username] [password]"
        echo "  $0 logout"
        echo ""
        echo "Email Verification:"
        echo "  $0 verify send"
        echo "  $0 verify check <code>"
        echo ""
        echo "Session Management:"
        echo "  $0 session create [name] [model]"
        echo "  $0 session list"
        echo "  $0 session switch <session_id>"
        echo "  $0 session current"
        echo ""
        echo "Chat:"
        echo "  $0 chat \"message\""
        echo ""
        echo "Utilities:"
        echo "  $0 status"
        echo "  $0 health"
        exit 1
        ;;
esac