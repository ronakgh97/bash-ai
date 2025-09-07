# BASH CLI

A simple command-line tool for API interaction featuring authentication, session management, and real-time live search chatbot with AI thinking visualization.

![bash](https://img.shields.io/badge/shell-bash-blue?logo=gnu-bash)

## 🚀 Installation

### Global Installation (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/ronakgh97/bash-ai/master/install.sh | bash
```

## 📋 Requirements

The CLI requires these tools (usually pre-installed on Unix systems):

- **curl** - HTTP client for API requests
- **jq** - JSON processor for parsing responses
- **bash** - Shell environment (Linux/macOS/WSL)

### Installing Dependencies

**macOS (Homebrew):**
```bash
brew install curl jq
```

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install curl jq
```

**Windows:**
Use WSL (Windows Subsystem for Linux) or Git Bash

## ⚡ Quick Start

1. Register a new user
   spai user create myusername mypassword myemail@example.com

2. Login
   spai login myusername mypassword

3. Verify your account (check your email)
   spai verify send
   spai verify check 123456

4. Create a chat session
   spai session create "My First Chat"

5. Start chatting with AI
   spai chat "Hello! How are you today?"

6. Check your status
   spai status

## 📚 Commands Reference

### 👤 User Management
spai user create [username] [password] [email] # Register new user
spai user profile # View user profile
spai login [username] [password] # Login to account
spai logout # Logout and clear data


### 📧 Email Verification
spai verify send # Send verification code to email
spai verify check <code> # Verify account with received code


### 🗂️ Session Management
spai session create [name] [model] # Create new chat session
spai session list # List all your sessions
spai session switch <session_id> # Switch to different session
spai session current # Show current active session


### 💬 Chat
spai chat "your message here"


### 🔧 Utilities
spai status # Show login and session status
spai health # Check API connectivity
spai help # Show help information
spai version # Show version number


## 🎮 Usage Examples

### Complete Workflow
-> Setup your account
spai user create alice mypassword alice@example.com
spai login alice mypassword
spai verify send
spai verify check 456789

-> Create different sessions for different purposes
spai session create "Work Assistant" "gpt-4"
spai session create "Code Helper" "claude-3"
spai session create "Creative Writing" "qwen/qwen3-4b-thinking-2507"

-> List and switch between sessions
spai session list
spai session switch 60d5f3f7e8a8d82e8c3e8e3f

-> Chat with AI (shows thinking process)
spai chat "Explain quantum computing in simple terms"
spai chat "Write a Python function to reverse a string"
spai chat "Help me plan a trip to Japan"

-> Check your setup
spai status
spai session current

### Data Storage

The CLI stores data in your home directory:
- `~/.spai-token` - Your authentication token
- `~/.spai-session` - Current active session ID
- `~/.spai-sessions/` - Session metadata (JSON files)

## 🎨 Features Showcase

### Real-time Chat with Thinking
The CLI shows the AI's thinking process in gray text before the final response:

You: Explain how recursion works
Assistant:
--- Thinking ---
The user is asking about recursion, which is a fundamental programming concept...
--- End Thinking ---

Recursion is a programming technique where a function calls itself...
text

### Session Management
Switch seamlessly between different AI conversations:
spai session list
=== Your Sessions ===
▶ Work Assistant (60d5f3f7e8a8d82e8c3e8e3f)
Model: gpt-4 | Messages: 15 | Created: 2025-08-24T14:30:00
Code Helper (507f1f77bcf86cd799439011)
Model: claude-3 | Messages: 8 | Created: 2025-08-24T15:45:00

## 🔍 Troubleshooting

### Common Issues

**❓ "jq: command not found"**
Install jq (see Requirements section above)
brew install jq # macOS
sudo apt install jq # Ubuntu

**❓ "Not logged in"**
spai login username password

**❓ "No active session"**
spai session create "New Session"

or switch to existing session
spai session list
spai session switch <session_id>

**❓ "Connection refused" / "Unable to connect"**
Check API health
spai health


### Debug Mode
Enable verbose curl output for debugging
export API_DEBUG=1
spai health

## 🛠️ Development

### Local Development
```bash
git clone https://github.com/ronakgh97/bash-ai.git
cd spai
chmod +x bin/spai.sh
```

Test the script directly
./bin/spai.sh help
./bin/spai.sh version