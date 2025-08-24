# API CLI

A powerful command-line tool for API interaction featuring authentication, session management, and real-time chat with AI thinking visualization.

[![npm version](https://badge.fury.io/js/@yourusername%2Fapi-cli.svg)](https://www.npmjs.com/package/@ronakgh97/api-cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🔐 **Secure Authentication** with JWT tokens
- 📧 **Email Verification** support
- 💬 **Real-time Streaming Chat** with AI thinking process visualization
- 🎯 **Multiple Session Management**
- 🎨 **Colored Terminal Output** for better readability
- 📊 **Status Monitoring** and health checks
- 🌐 **Pre-configured** for instant use (no setup required!)

## 🚀 Installation

### Global Installation (Recommended)
npm install -g @ronakgh97/api-cli

text

### One-time Usage
npx @ronakgh97/api-cli help

text

## 📋 Requirements

The CLI requires these tools (usually pre-installed on Unix systems):

- **curl** - HTTP client for API requests
- **jq** - JSON processor for parsing responses
- **bash** - Shell environment (Linux/macOS/WSL)

### Installing Dependencies

**macOS (Homebrew):**
brew install curl jq

text

**Ubuntu/Debian:**
sudo apt update && sudo apt install curl jq

text

**CentOS/RHEL/Fedora:**
sudo yum install curl jq

or
sudo dnf install curl jq

text

**Windows:**
Use WSL (Windows Subsystem for Linux) or Git Bash

## ⚡ Quick Start

1. Register a new user
   api-cli user create myusername mypassword myemail@example.com

2. Login
   api-cli login myusername mypassword

3. Verify your account (check your email)
   api-cli verify send
   api-cli verify check 123456

4. Create a chat session
   api-cli session create "My First Chat"

5. Start chatting with AI
   api-cli chat "Hello! How are you today?"

6. Check your status
   api-cli status

text

## 📚 Commands Reference

### 👤 User Management
api-cli user create [username] [password] [email] # Register new user
api-cli user profile # View user profile
api-cli login [username] [password] # Login to account
api-cli logout # Logout and clear data

text

### 📧 Email Verification
api-cli verify send # Send verification code to email
api-cli verify check <code> # Verify account with received code

text

### 🗂️ Session Management
api-cli session create [name] [model] # Create new chat session
api-cli session list # List all your sessions
api-cli session switch <session_id> # Switch to different session
api-cli session current # Show current active session

text

### 💬 Chat
api-cli chat "your message here" # Send message to AI

text

### 🔧 Utilities
api-cli status # Show login and session status
api-cli health # Check API connectivity
api-cli help # Show help information
api-cli version # Show version number

text

## 🎮 Usage Examples

### Complete Workflow
Setup your account
api-cli user create alice mypassword alice@example.com
api-cli login alice mypassword
api-cli verify send
api-cli verify check 456789

Create different sessions for different purposes
api-cli session create "Work Assistant" "gpt-4"
api-cli session create "Code Helper" "claude-3"
api-cli session create "Creative Writing" "qwen/qwen3-4b-thinking-2507"

List and switch between sessions
api-cli session list
api-cli session switch 60d5f3f7e8a8d82e8c3e8e3f

Chat with AI (shows thinking process)
api-cli chat "Explain quantum computing in simple terms"
api-cli chat "Write a Python function to reverse a string"
api-cli chat "Help me plan a trip to Japan"

Check your setup
api-cli status
api-cli session current

text

### Advanced Usage
Use custom API server
export API_URL=https://your-api-server.com/api/v1
api-cli health

Temporary API override
API_URL=https://staging-api.com/api/v1 api-cli status

Check what's happening
api-cli user profile
api-cli session list

text

## ⚙️ Configuration

### API Endpoint

**Default**: The CLI connects to `https://servertest.ronakratnadip.xyz/api/v1`

**No configuration needed!** Just install and start using immediately.

**Custom API Server** (optional):
export API_URL=https://your-api-server.com/api/v1
api-cli health # Test connection

text

### Data Storage

The CLI stores data in your home directory:
- `~/.api-cli-token` - Your authentication token
- `~/.api-cli-session` - Current active session ID
- `~/.api-cli-sessions/` - Session metadata (JSON files)

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
api-cli session list
=== Your Sessions ===
▶ Work Assistant (60d5f3f7e8a8d82e8c3e8e3f)
Model: gpt-4 | Messages: 15 | Created: 2025-08-24T14:30:00
Code Helper (507f1f77bcf86cd799439011)
Model: claude-3 | Messages: 8 | Created: 2025-08-24T15:45:00

text

## 🔍 Troubleshooting

### Common Issues

**❓ "command not found: api-cli"**
Make sure you installed globally
npm install -g @yourusername/api-cli

Check if npm global bin is in PATH
npm config get prefix

text

**❓ "jq: command not found"**
Install jq (see Requirements section above)
brew install jq # macOS
sudo apt install jq # Ubuntu

text

**❓ "Not logged in"**
api-cli login username password

text

**❓ "No active session"**
api-cli session create "New Session"

or switch to existing session
api-cli session list
api-cli session switch <session_id>

text

**❓ "Connection refused" / "Unable to connect"**
Check API health
api-cli health

Try with custom API URL if you have one
export API_URL=https://your-server.com/api/v1
api-cli health

text

### Debug Mode
Enable verbose curl output for debugging
export API_DEBUG=1
api-cli health

text

## 🛠️ Development

### Local Development
git clone https://github.com/ronakgh97/bash-api-test.git
cd api-cli
chmod +x bin/cli.sh

Test the script directly
./bin/cli.sh help
./bin/cli.sh version

Link for global testing
npm link
api-cli help

text

### Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
