# TealKit MCP Server

[![MCP Protocol](https://img.shields.io/badge/MCP-2024--11--05-blue.svg)](https://modelcontextprotocol.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg?logo=dart)](https://dart.dev)
[![Glama](https://img.shields.io/badge/Glama-Compatible-5B45FF.svg)](https://glama.ai)
[![Smithery](https://img.shields.io/badge/Smithery-Certified-black.svg)](https://smithery.ai)

A specialized **Model Context Protocol (MCP) Server** that bridges **Claude Desktop**, **Claude Code**, and **Cursor IDE** to persistent NAS/Server task scheduling, deep recursive web documentation crawlers, offline document RAG knowledge bases, and smartphone push alerts with human-in-the-loop approvals.

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
* `tealkit_run_background`: Dispatches asynchronous long-running jobs (fire-and-forget) to your server worker pool.
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
* `tealkit_send_mobile_alert`: Sends instant push notifications with configurable priority to the user's TealKit Android / iOS app.
* `tealkit_request_mobile_approval`: Presents an interactive confirmation card on the user's smartphone with **Approve** / **Reject** buttons and waits for human authorization before high-risk actions (e.g. database migrations, cloud deployments).

---

## Quickstart

### Prerequisites
* [Dart SDK](https://dart.dev/get-dart) 3.0 or later installed on your system.

### Installation

Clone the repository:
```bash
git clone https://github.com/lschaffer/tealkit-mcp.git
cd tealkit-mcp
dart pub get
```

Compile a standalone native binary (optional, for maximum speed):
```bash
dart compile exe bin/tealkit_mcp.dart -o tealkit-mcp.exe
```

---

## Client Configuration

### Claude Desktop (`claude_desktop_config.json`)

On Windows (`%APPDATA%\Claude\claude_desktop_config.json`) or macOS (`~/Library/Application Support/Claude/claude_desktop_config.json`):

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
        "TEALKIT_SERVER_URL": "https://tealkit.dev",
        "TEALKIT_SERVER_KEY": "YOUR_OPTIONAL_API_KEY"
      }
    }
  }
}
```

Or if using the compiled executable:
```json
{
  "mcpServers": {
    "tealkit": {
      "command": "C:/projects/ls/tealkit-mcp/tealkit-mcp.exe",
      "args": []
    }
  }
}
```

### Cursor IDE (`.cursor/mcp.json`)

Add to your Cursor project or global settings:
```json
{
  "mcpServers": {
    "tealkit": {
      "command": "dart",
      "args": [
        "run",
        "C:/projects/ls/tealkit-mcp/bin/tealkit_mcp.dart"
      ]
    }
  }
}
```

---

## Configuration Options

TealKit MCP can be configured via environment variables or a local `config.yaml` file located in `~/.tealkit_mcp/config.yaml` or `./config.yaml`:

```yaml
server:
  url: "https://tealkit.dev"   # Or local NAS: http://192.168.1.50:8080
  api_key: ""

rag:
  database_path: "~/.tealkit_mcp/knowledge.db"

push:
  endpoint: ""
  auth_token: ""
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

TealKit MCP is built with **100% pure Dart**, ensuring instant startup, zero native C++ driver dependencies, and cross-platform compatibility across Windows, Linux, and macOS.

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
    TealKit Server/NAS  Local SQLite DB   TealKit Mobile App
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
