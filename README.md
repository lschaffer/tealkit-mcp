# TealKit MCP Server

[![MCP Protocol](https://img.shields.io/badge/MCP-2024--11--05-blue.svg)](https://modelcontextprotocol.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg?logo=dart)](https://dart.dev)
[![Glama](https://img.shields.io/badge/Glama-Listed-5B45FF.svg)](https://glama.ai/mcp/servers/lschaffer/tealkit-mcp)
[![Smithery](https://img.shields.io/badge/Smithery-Certified-black.svg)](https://smithery.ai)

A specialized **Model Context Protocol (MCP) Server** that bridges **Claude Desktop**, **Claude Code**, and **Cursor IDE** to persistent NAS/Server task scheduling, deep recursive web documentation crawlers, offline document RAG knowledge bases, and smartphone push alerts with human-in-the-loop approvals.

---

## Table of Contents
- [Why TealKit MCP?](#why-tealkit-mcp)
- [3 Core Pillars & Tools](#3-core-pillars--tools)
- [Download & Setup](#download--setup)
  - [Option A: Standalone Pre-compiled Binary (Recommended - Zero Dependencies)](#option-a-standalone-pre-compiled-binary-recommended---zero-dependencies)
  - [Option B: Build from Source](#option-b-build-from-source)
  - [Option C: Run via Docker](#option-c-run-via-docker)
- [Client Configuration](#client-configuration)
  - [Claude Desktop](#claude-desktop-claude_desktop_configjson)
  - [Cursor IDE](#cursor-ide-cursormcpjson)
- [Mobile Push Notifications Setup](#mobile-push-notifications-setup)
- [Configuration Reference](#configuration-reference)
- [Architecture](#architecture)
- [License](#license)

---

## Why TealKit MCP?

State-of-the-art coding assistants like Claude Desktop and Cursor excel at writing and editing code within your local repository. However, they lack:
1. **Persistent Execution**: They cannot run long jobs in the background on your home server or NAS while your workstation is asleep.
2. **Deep Documentation Crawling**: Web crawlers in desktop LLMs are constrained; they cannot recursively crawl an entire documentation site (e.g. 50+ pages of Flutter or Kubernetes docs) and index it into a persistent local vector/FTS database for instant retrieval.
3. **Mobile Human-in-the-Loop**: When Claude finishes a 30-minute build, benchmark, or deployment script, it cannot notify your phone or ask you to tap **[Approve]** / **[Reject]** while you are away from your desk.

**TealKit MCP solves all three problems** by exposing 10 targeted tools across 3 core pillars.

---

## 3 Core Pillars & Tools

### 🌐 Pillar 1: Persistent Background Tasks & NAS Scheduling
Offload long-running tasks and cron schedules to your TealKit Server or NAS.
* `tealkit_schedule_job`: Schedules recurring background cron tasks (e.g. daily backups, nightly benchmark runs, continuous health checks).
* `tealkit_run_background`: Dispatches asynchronous long-running jobs (fire-and-forget) to your server worker pool. Supports exact task IDs or human-readable names (e.g. `"tcloud disk space"`).
* `tealkit_get_job_status`: Checks logs, exit status, and progress of any queued or running job.
* `tealkit_list_jobs`: Lists all active, scheduled, and configured jobs on your server.

### 📚 Pillar 2: Deep Recursive Web Crawler & Offline Document RAG
Turn any documentation website or directory into an offline SQLite knowledge base with citations.
* `tealkit_crawl_and_index`: Recursively crawls a website documentation tree (up to `max_pages`) and ingests chunks into your local offline knowledge base.
* `tealkit_index_local_docs`: Indexes local directories containing PDFs, Word (`.docx`), Markdown (`.md`), and text files.
* `tealkit_search_knowledge`: Performs hybrid Reciprocal Rank Fusion (BM25 FTS5 + vector similarity) searching with exact citations, file paths, and line ranges.
* `tealkit_get_source_doc`: Retrieves the complete stored content and metadata of any indexed document or web page.

### 📱 Pillar 3: Mobile Push Alerts & Human-in-the-Loop Approvals
Keep the developer informed and in control from anywhere.
* `tealkit_send_mobile_alert`: Sends instant push notifications with configurable priority to the user's smartphone.
* `tealkit_request_mobile_approval`: Presents an interactive confirmation card on the user's smartphone with **Approve** / **Reject** buttons and waits for human authorization before high-risk actions (e.g. database migrations, cloud deployments).

---

## Download & Setup

### Option A: Standalone Pre-compiled Binary (Recommended - Zero Dependencies)
You do **not** need Dart, Flutter, Python, or Node.js installed on your machine.

1. Download the latest binary for your operating system from **[GitHub Releases](https://github.com/lschaffer/tealkit-mcp/releases)**:
   - **Windows**: `tealkit-mcp.exe`
   - **Linux**: `tealkit-mcp-linux`
   - **macOS**: `tealkit-mcp-macos`
2. Place the executable in a directory of your choice (e.g., `C:\tools\tealkit-mcp.exe` or `/usr/local/bin/tealkit-mcp`).
3. Add it to your Claude Desktop or Cursor configuration (see [Client Configuration](#client-configuration) below).

---

### Option B: Build from Source
If you have the [Dart SDK](https://dart.dev/get-dart) (3.0+) installed:

```bash
# 1. Clone the repository
git clone https://github.com/lschaffer/tealkit-mcp.git
cd tealkit-mcp

# 2. Install dependencies
dart pub get

# 3. Compile standalone native executable
# On Windows:
dart compile exe bin/tealkit_mcp.dart -o tealkit-mcp.exe

# On Linux / macOS:
dart compile exe bin/tealkit_mcp.dart -o tealkit-mcp
chmod +x tealkit-mcp
```

Alternatively, run directly from source without compiling:
```bash
dart run bin/tealkit_mcp.dart
```

---

### Option C: Run via Docker
To run in an isolated container:

```bash
# 1. Build Docker image
docker build -t tealkit-mcp .

# 2. Test stdio container
docker run -i --rm tealkit-mcp
```

---

## Client Configuration

### Claude Desktop (`claude_desktop_config.json`)

Configuration file location:
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

#### Using Pre-compiled Binary:
```json
{
  "mcpServers": {
    "tealkit": {
      "command": "C:/tools/tealkit-mcp.exe",
      "args": [],
      "env": {
        "TEALKIT_SERVER_URL": "https://tealkit.dev/tealkitserver",
        "TEALKIT_SERVER_KEY": "YOUR_SERVER_API_KEY",
        "TEALKIT_PUSH_URL": "https://ntfy.sh/your-private-alert-topic"
      }
    }
  }
}
```

#### Using Dart Source:
```json
{
  "mcpServers": {
    "tealkit": {
      "command": "dart",
      "args": [
        "run",
        "C:/projects/ls/tealkit-mcp/bin/tealkit_mcp.dart"
      ],
      "env": {
        "TEALKIT_SERVER_URL": "https://tealkit.dev/tealkitserver",
        "TEALKIT_SERVER_KEY": "YOUR_SERVER_API_KEY",
        "TEALKIT_PUSH_URL": "https://ntfy.sh/your-private-alert-topic"
      }
    }
  }
}
```

#### Using Docker:
```json
{
  "mcpServers": {
    "tealkit": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "TEALKIT_SERVER_URL=https://tealkit.dev/tealkitserver",
        "-e", "TEALKIT_SERVER_KEY=YOUR_SERVER_API_KEY",
        "tealkit-mcp"
      ]
    }
  }
}
```

---

### Cursor IDE (`.cursor/mcp.json`)

Add to your Cursor project `.cursor/mcp.json` or global settings:

```json
{
  "mcpServers": {
    "tealkit": {
      "command": "C:/tools/tealkit-mcp.exe",
      "args": []
    }
  }
}
```

---

## Mobile Push Notifications Setup

TealKit MCP supports three flexible methods to deliver push notifications and human-in-the-loop approvals to your phone:

### Method 1: Instant Zero-Setup via ntfy.sh (Recommended)
[ntfy.sh](https://ntfy.sh) is a free, privacy-friendly, open-source HTTP push notification service:
1. Install the free **ntfy** app on your phone:
   - [ntfy for Android (Google Play)](https://play.google.com/store/apps/details?id=io.heckel.ntfy) or [F-Droid](https://f-droid.org/packages/io.heckel.ntfy/)
   - [ntfy for iOS (App Store)](https://apps.apple.com/app/ntfy/id1625396347)
2. Open the ntfy app and tap **+** to subscribe to your own private topic name (e.g. `tealkit-dev-alert-9823`).
3. Set the endpoint in your config:
   ```yaml
   push:
     endpoint: "https://ntfy.sh/tealkit-dev-alert-9823"
   ```
   or via environment variable `TEALKIT_PUSH_URL=https://ntfy.sh/tealkit-dev-alert-9823`.
4. Claude can now send alerts and approval prompts directly to your lock screen with zero infrastructure setup.

### Method 2: TealKit Mobile App via Server SSE Gateway
If you have the TealKit Flutter mobile app running:
1. The app connects to the event stream at `https://tealkit.dev/tealkitserver/api/v1/events`.
2. When `tealkit_send_mobile_alert` is executed, the server broadcasts an alert event to the mobile client.
3. The mobile app displays a system notification using `flutter_local_notifications` (`task_success`, `task_error` channels).

### Method 3: Firebase Cloud Messaging (FCM)
For enterprise or production deployments where notifications must wake up a fully closed mobile app:
1. Register your device token in the TealKit Server device registry (`/api/v1/devices`).
2. Configure `TEALKIT_PUSH_KEY` with your server's Firebase service credentials.
3. High-priority pushes are routed directly through Google/Apple APNs gateways.

---

## Configuration Reference

TealKit MCP can be configured via command-line flags, environment variables, or a local `config.yaml` file located in `~/.tealkit_mcp/config.yaml` or `./config.yaml`:

```yaml
server:
  url: "https://tealkit.dev/tealkitserver"   # Or local NAS: http://192.168.1.50:8080
  api_key: "your_api_key"

rag:
  database_path: "~/.tealkit_mcp/knowledge.db"

push:
  endpoint: "https://ntfy.sh/your-topic"
  auth_token: ""
```

### CLI Options
```
--config, -c       Path to custom config.yaml file
--server-url       TealKit NAS/Server URL (e.g. https://tealkit.dev/tealkitserver)
--server-key       TealKit Server API Key
--rag-db           Path to RAG SQLite database directory
--help, -h         Show help message
```

### Environment Variables
| Variable | Description | Default |
| :--- | :--- | :--- |
| `TEALKIT_SERVER_URL` | Base URL of TealKit Server / NAS instance | `https://tealkit.dev` |
| `TEALKIT_SERVER_KEY` | Bearer API token for server authentication | `""` |
| `TEALKIT_PUSH_URL` | Push gateway endpoint for mobile alerts | `""` |
| `TEALKIT_PUSH_KEY` | Push gateway authorization secret | `""` |

---

## Architecture

TealKit MCP is built with **100% pure Dart**, ensuring instant startup (<50ms), zero native C++ driver dependencies, and cross-platform compatibility across Windows, Linux, and macOS.

```
┌────────────────────────────────────────────────────────┐
│               Claude Desktop / Cursor IDE              │
└──────────────────────────┬─────────────────────────────┘
                           │ JSON-RPC 2.0 (stdio)
┌──────────────────────────▼─────────────────────────────┐
│                   TealKit MCP Server                   │
├───────────────────┬──────────────────┬─────────────────┤
│   Task Scheduler  │   RAG Pipeline   │  Mobile Bridge  │
│   (Server Bridge) │ (Crawler & FTS5) │  (Push Gateway) │
└─────────┬─────────┴────────┬─────────┴────────┬────────┘
          │                  │                  │
    TealKit Server/NAS  Local SQLite DB   Smartphone App (ntfy / TealKit)
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
