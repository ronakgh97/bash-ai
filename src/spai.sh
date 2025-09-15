#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# CONFIGURATION AND CONSTANTS
# ============================================================================

readonly SCRIPT_VERSION="1.0.2"
readonly BASE_URL="https://live.ronakratnadip.xyz/api/v1"
readonly SPAI_DATA_DIR="$HOME/.config/spai"
readonly TOKEN_FILE="$SPAI_DATA_DIR/token"
readonly SESSION_FILE="$SPAI_DATA_DIR/current_session"
readonly SESSIONS_DIR="$SPAI_DATA_DIR/sessions"

# Available models
readonly AVAILABLE_MODELS=(
    "qwen/qwen3-4b-thinking-2507"
    "qwen/qwen3-4b-2507"
    "deepseek/deepseek-chat-v3.1"
    "z-ai/glm-4.5-air"
    "qwen/qwen3-235b-a22b"
    "meta-llama/llama-3.3-70b-instruct"
)

readonly DEFAULT_MODEL="qwen/qwen3-4b-thinking-2507"

# Color definitions
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly GRAY='\033[0;37m'
    readonly NC='\033[0m'
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' GRAY='' NC=''
fi

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

check_dependencies() {
    for dep in curl jq; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Error: $dep is required but not installed." >&2
            exit 1
        fi
    done
}

setup_directories() {
    mkdir -p "$SPAI_DATA_DIR" "$SESSIONS_DIR"
    chmod 700 "$SPAI_DATA_DIR"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Simple prompt function
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local is_password="${3:-false}"
    local input=""

    if [[ "$is_password" == "true" ]]; then
        read -rsp "$prompt: " input
        echo >&2
    else
        read -rp "$prompt: " input
    fi

    printf -v "$var_name" '%s' "$input"
}

show_spinner() {
    local pid=$1
    local delay=0.05
    local spinstr='|/-~-~\|'

    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}


# ============================================================================
# TOKEN AND SESSION MANAGEMENT
# ============================================================================

save_token() {
    setup_directories
    echo "$1" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
}

get_token() {
    cat "$TOKEN_FILE" 2>/dev/null || echo ""
}

clear_token() {
    rm -f "$TOKEN_FILE"
}

save_current_session() {
    setup_directories
    echo "$1" > "$SESSION_FILE"
}

get_current_session() {
    cat "$SESSION_FILE" 2>/dev/null || echo ""
}

clear_current_session() {
    rm -f "$SESSION_FILE"
}

save_session_details() {
    local session_id="$1" name="$2" model="$3"
    local session_dir="$SESSIONS_DIR/$session_id"
    mkdir -p "$session_dir"
    cat > "$session_dir/info.json" <<EOF
{
    "sessionId": "$session_id",
    "nameSession": "$name",
    "model": "$model",
    "created": "$(date -Iseconds)"
}
EOF
}

# ============================================================================
# COMMAND HANDLERS
# ============================================================================

handle_user_command() {
    local sub_command="$1"; shift 2>/dev/null || true

    case "$sub_command" in
        create)
            local username="${1:-}" password="${2:-}" email="${3:-}"

            [[ -z "$username" ]] && prompt_input "Username" username
            [[ -z "$password" ]] && prompt_input "Password" password true
            [[ -z "$email" ]] && prompt_input "Email" email

            log_info "Creating user: $username"

            local response
            response=$(curl -s -X POST "$BASE_URL/users/register" \
                -H "Content-Type: application/json" \
                -d "{\"userName\":\"$username\",\"password\":\"$password\",\"gmail\":\"$email\"}")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                log_success "User created successfully!"
                echo -e "${CYAN}Username:${NC} $username"
                echo -e "${CYAN}Email:${NC} $email"

            else
                local error_msg
                error_msg=$(echo "$response" | jq -r '.message // "Unknown error"')
                log_error "User creation failed: $error_msg"
                exit 1
            fi
            ;;
        profile)
            local token
            token=$(get_token)
            [[ -z "$token" ]] && log_error "Not logged in! Use: $0 login" && exit 1

            log_info "Fetching user profile"

            local response
            response=$(curl -s -X GET "$BASE_URL/users/profile" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local user_data username email is_verified session_count
                user_data=$(echo "$response" | jq -r '.data')

                username=$(echo "$user_data" | jq -r '.userName')
                email=$(echo "$user_data" | jq -r '.gmail // "N/A"')
                session_count=$(echo "$user_data" | jq -r '.sessionCount // 0')
                is_verified=$(echo "$user_data" | jq -r '.verified // .isVerified // "Unknown"')

                echo "=== User Profile ==="
                echo -e "${CYAN}Username:${NC} $username"
                echo -e "${CYAN}Email:${NC} $email"
                echo -e "${CYAN}Verified:${NC} $is_verified"
                echo -e "${CYAN}Total Sessions:${NC} $session_count"
            else
                log_error "Failed to get user profile"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown user subcommand: $sub_command"
            echo "Available: create, profile"
            exit 1
            ;;
    esac
}

handle_login_command() {
    local username="${1:-}" password="${2:-}"

    [[ -z "$username" ]] && prompt_input "Username" username
    [[ -z "$password" ]] && prompt_input "Password" password true

    log_info "Logging in as: $username"

    local response
    response=$(curl -s -X POST "$BASE_URL/users/login" \
        -H "Content-Type: application/json" \
        -d "{\"userName\":\"$username\",\"password\":\"$password\"}")

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        local token
        token=$(echo "$response" | jq -r '.data.token')
        save_token "$token"
        log_success "Logged in successfully!"
    else
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // "Login failed"')
        log_error "$error_msg"
        exit 1
    fi
}

handle_logout_command() {
    clear_token
    clear_current_session
    log_success "Logged out successfully!"
}

handle_verify_command() {
    local sub_command="$1"; shift 2>/dev/null || true
    local token

    token=$(get_token)
    [[ -z "$token" ]] && log_error "Not logged in!" && exit 1

    case "$sub_command" in
        send)
            log_info "Sending verification email..."

            local response
            response=$(curl -s -X GET "$BASE_URL/verify" \
                -H "Authorization: Bearer $token")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local message
                message=$(echo "$response" | jq -r '.message')
                log_success "$message"
            else
                log_error "Failed to send verification email"
                exit 1
            fi
            ;;
        check)
            local code="${1:-}"
            [[ -z "$code" ]] && prompt_input "Verification code" code

            log_info "Verifying code: $code"
            local response
            response=$(curl -s -X POST "$BASE_URL/verify/$code" \
                -H "Authorization: Bearer $token")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local message
                message=$(echo "$response" | jq -r '.message')
                log_success "$message"
                echo
                log_info "Updated profile:"
                handle_user_command profile
            else
                log_error "Verification failed"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown verify subcommand: $sub_command"
            echo "Available: send, check"
            exit 1
            ;;
    esac
}

handle_session_command() {
    local sub_command="$1"; shift 2>/dev/null || true
    local token

    token=$(get_token)
    [[ -z "$token" ]] && log_error "Not logged in!" && exit 1

    case "$sub_command" in
        create)
            local session_name="${1:-}" model="${2:-}"

            [[ -z "$session_name" ]] && prompt_input "Session name" session_name
            [[ -z "$model" ]] && {
                echo "Available models:"
                printf "  - %s\n" "${AVAILABLE_MODELS[@]}"
                echo
                prompt_input "Model (press Enter for default: $DEFAULT_MODEL)" model
                [[ -z "$model" ]] && model="$DEFAULT_MODEL"
            }

            log_info "Creating session: $session_name with model: $model"

            local response
            response=$(curl -s -X POST "$BASE_URL/sessions/create" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                -d "{\"nameSession\":\"$session_name\",\"model\":\"$model\"}")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local session_data session_id datetime
                session_data=$(echo "$response" | jq -r '.data')
                session_id=$(echo "$session_data" | jq -r '.sessionId')
                datetime=$(echo "$session_data" | jq -r '.dateTime')

                save_session_details "$session_id" "$session_name" "$model"
                save_current_session "$session_id"

                log_success "Session created and activated!"
                echo -e "${CYAN}Session ID:${NC} $session_id"
                echo -e "${CYAN}Name:${NC} $session_name"
                echo -e "${CYAN}Model:${NC} $model"
                echo -e "${CYAN}Created:${NC} $datetime"
            else
                local error_msg
                error_msg=$(echo "$response" | jq -r '.message // "Session creation failed"')
                log_error "$error_msg"
                exit 1
            fi
            ;;
        list)
            log_info "Fetching sessions from server..."
            local response
            response=$(curl -s -X GET "$BASE_URL/sessions" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local current_session
                current_session=$(get_current_session)
                echo "=== Your Sessions ==="

                local sessions session_count
                sessions=$(echo "$response" | jq -r '.data')
                session_count=$(echo "$sessions" | jq length)

                if [[ "$session_count" -gt 0 ]]; then
                    echo "$sessions" | jq -r '.[] | @json' | while read -r session; do
                        local session_id session_name model datetime message_count
                        session_id=$(echo "$session" | jq -r '.sessionId')
                        session_name=$(echo "$session" | jq -r '.nameSession')
                        model=$(echo "$session" | jq -r '.model')
                        datetime=$(echo "$session" | jq -r '.dateTime')
                        message_count=$(echo "$session" | jq -r '.messageCount')

                        if [[ "$session_id" == "$current_session" ]]; then
                            echo -e "${GREEN}➡️  $session_name${NC} (${CYAN}$session_id${NC})"
                        else
                            echo -e "${GRAY}➡️  $session_name${NC} (${GRAY}$session_id${NC})"
                        fi
                        echo -e "    Model: $model | Messages: $message_count | Created: $datetime"
                    done
                else
                    log_warning "No sessions found"
                fi
            else
                log_error "Failed to fetch sessions"
                exit 1
            fi
            ;;
        switch)
            local session_id="${1:-}"
            [[ -z "$session_id" ]] && {
                log_error "Usage: $0 session switch <session_id>"
                exit 1
            }

            # Verify session exists on server
            local response
            response=$(curl -s -X GET "$BASE_URL/sessions" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json")

            if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                local session_exists session_name
                session_exists=$(echo "$response" | jq -r --arg sid "$session_id" '.data[] | select(.sessionId == $sid) | .sessionId')
                if [[ -n "$session_exists" ]]; then
                    session_name=$(echo "$response" | jq -r --arg sid "$session_id" '.data[] | select(.sessionId == $sid) | .nameSession')
                    save_current_session "$session_id"
                    log_success "Switched to session: $session_name ($session_id)"
                else
                    log_error "Session not found: $session_id"
                    exit 1
                fi
            else
                log_error "Failed to verify session"
                exit 1
            fi
            ;;
        current)
            local current_session
            current_session=$(get_current_session)
            if [[ -n "$current_session" ]]; then
                local response
                response=$(curl -s -X GET "$BASE_URL/sessions" \
                    -H "Authorization: Bearer $token" \
                    -H "Content-Type: application/json")

                if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
                    local session_data
                    session_data=$(echo "$response" | jq -r --arg sid "$current_session" '.data[] | select(.sessionId == $sid)')

                    if [[ -n "$session_data" && "$session_data" != "null" ]]; then
                        local session_name model message_count
                        session_name=$(echo "$session_data" | jq -r '.nameSession')
                        model=$(echo "$session_data" | jq -r '.model')
                        message_count=$(echo "$session_data" | jq -r '.messageCount')

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
                    exit 1
                fi
            else
                log_warning "No active session"
                echo "Use '$0 session list' to see available sessions"
                echo "Use '$0 session create [name] [model]' to create a new session"
            fi
            ;;
        models)
            echo "Available models:"
            echo
            local i=1
            for model in "${AVAILABLE_MODELS[@]}"; do
                if [[ "$model" == "$DEFAULT_MODEL" ]]; then
                    echo -e "  ${GREEN}$i. $model (default)${NC}"
                else
                    echo "  $i. $model"
                fi
                ((i++))
            done
            echo
            ;;
        *)
            log_error "Unknown session subcommand: $sub_command"
            echo "Available: create, list, switch, current, models"
            exit 1
            ;;
    esac
}

# ============================================================================
# CHAT COMMAND HANDLER
# ============================================================================

handle_chat_command() {
    local PROMPT="$*"

    [[ -z "$PROMPT" ]] && log_error "Usage: $0 chat \"message\"" && exit 1

    local TOKEN=$(get_token)
    local SESSION_ID=$(get_current_session)

    [[ -z "$TOKEN" ]] && log_error "Not logged in" && exit 1
    [[ -z "$SESSION_ID" ]] && log_error "No active session. Use: $0 session list" && exit 1

    # Get session name from server
    local RESPONSE=$(curl -s -X GET "$BASE_URL/sessions" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")

    local SESSION_NAME="Unknown"
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
                        echo -e "${CYAN}--- Thinking ---${NC}"
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
        }


handle_status_command() {
    local token

    echo "=== SPAI Status ==="
    echo

    # Check API health
    if curl -s --fail --max-time 10 "$BASE_URL/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ API Server:${NC} Online"
    else
        echo -e "${RED}❌ API Server:${NC} Offline"
    fi

    # Check login status
    token=$(get_token)
    if [[ -n "$token" ]]; then
        local response
        response=$(curl -s -X GET "$BASE_URL/users/profile" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json")

        if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
            local user_data username is_verified session_count
            user_data=$(echo "$response" | jq -r '.data')
            username=$(echo "$user_data" | jq -r '.userName')
            is_verified=$(echo "$user_data" | jq -r '.verified // .isVerified // "Unknown"')
            session_count=$(echo "$user_data" | jq -r '.sessionCount // 0')

            echo -e "${GREEN}✅ User:${NC} $username"
            echo -e "${CYAN}   Verified:${NC} $is_verified"
            echo -e "${CYAN}   Total Sessions:${NC} $session_count"
        else
            echo -e "${YELLOW}⚠️  User:${NC} Token may be invalid"
        fi
    else
        echo -e "${RED}❌ User:${NC} Not logged in"
    fi

    # Check current session
    local current_session
    current_session=$(get_current_session)
    if [[ -n "$current_session" ]]; then
        echo -e "${GREEN}✅ Active Session:${NC} $current_session"
    else
        echo -e "${YELLOW}⚠️  Active Session:${NC} None"
    fi
}

handle_health_command() {
    log_info "Checking API health..."
    
    {
        curl -s --fail --max-time 10 "$BASE_URL/health" >/dev/null 2>&1
    } &
    local curl_pid=$!
    show_spinner $curl_pid
    wait $curl_pid
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Server is up and running!"
    else
        log_error "Unable to connect to API"
        exit 1
    fi
}

handle_flush_command() {
    log_warning "This will clear all local SPAI data including:"
    echo "  - Authentication token"
    echo "  - Current session"
    echo "  - Session details"
    echo

    local confirmation=""
    prompt_input "Are you sure? (y/n)" confirmation

    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        rm -f "$TOKEN_FILE" "$SESSION_FILE" 2>/dev/null || true
        rm -rf "$SESSIONS_DIR" 2>/dev/null || true
        log_success "All local SPAI data has been cleared."
    else
        log_info "Operation cancelled."
    fi
}

show_help() {
    cat <<EOF

SPAI CLI v$SCRIPT_VERSION - Web Search AI Interface (Prototype)

USAGE:
    spai <command> [options]

USER MANAGEMENT:
    user create [username] [password] [email]    Create new user account
    user profile                                 Show user profile
    login [username] [password]                  Login to account
    logout                                       Logout from account

EMAIL VERIFICATION:
    verify send                                  Send verification email
    verify check <code>                          Verify with code

SESSION MANAGEMENT:
    session create [name] [model]               Create new chat session
    session list                                List all sessions
    session switch <session_id>                 Switch to session
    session current                             Show current session
    session models                              List available models

CHAT:
    chat "message"                              Send message to current session

UTILITIES:
    status                                      Show login and session status
    health                                      Check API server health
    flush                                       Clear all local data
    help                                        Show this help message

EXAMPLES:
    spai user create                                # Interactive user creation
    spai login                                      # Interactive login
    spai session create                             # Interactive session creation
    spai chat "what happened in recent sco summit?" # Send chat message
    spai chat "mail me the top stock changes"       # Send chat message

CONFIGURATION:
    Data Directory: $SPAI_DATA_DIR

github: https://github.com/ronakgh97/bash-ai

EOF
}

_spai_completion() {
    local cur prev commands
    cur="${COMP_WORDS[COMP_CWORD]}"     # Current word being completed
    prev="${COMP_WORDS[COMP_CWORD-1]}"  # Previous word
    
    case "$prev" in
        spai)
            commands="user login logout verify session chat status health flush help"
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            ;;
        session)
            COMPREPLY=($(compgen -W "create list switch current models delete" -- "$cur"))
            ;;
        user)
            COMPREPLY=($(compgen -W "create profile" -- "$cur"))
            ;;
    esac
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    # Check dependencies first
    check_dependencies

    # Initialize
    setup_directories

    # Check for help
    if [[ $# -eq 0 ]] || [[ "$1" =~ ^(help)$ ]]; then
        show_help
        exit 0
    fi

    # Check for version
    if [[ "$1" =~ ^(-v|--version|version)$ ]]; then
        echo "SPAI CLI v$SCRIPT_VERSION"
        exit 0
    fi

    local command="$1"; shift

    case "$command" in
        user)
            handle_user_command "$@"
            ;;
        login)
            handle_login_command "$@"
            ;;
        logout)
            handle_logout_command
            ;;
        verify)
            handle_verify_command "$@"
            ;;
        session)
            handle_session_command "$@"
            ;;
        chat)
            handle_chat_command "$@"
            ;;
        status)
            handle_status_command
            ;;
        health)
            handle_health_command
            ;;
        flush)
            handle_flush_command
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use 'spai help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    :
else
    complete -F _spai_completion spai
fi