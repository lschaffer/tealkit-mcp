# Changelog

All notable changes to the TealKit MCP Server project will be documented in this file.

## [1.0.0] - 2026-10-18

### Initial Release
- **Lightweight Standalone MCP Server**: Pure Dart implementation compliant with Model Context Protocol specification `2024-11-05`.
- **Pillar 1: Persistent Background Tasks & NAS Scheduling**:
  - `tealkit_schedule_job`: Recurring cron task scheduling on TealKit Server / NAS.
  - `tealkit_run_background`: Asynchronous long-running task dispatch with automatic name resolution (e.g. `"tcloud disk space"`).
  - `tealkit_get_job_status`: Real-time status inspection and live log retrieval.
  - `tealkit_list_jobs`: List active, scheduled, and configured server jobs.
- **Pillar 2: Deep Recursive Web Crawler & Offline Document RAG**:
  - `tealkit_crawl_and_index`: Pure Dart recursive website documentation crawler with breadth-first traversal and noise filtering.
  - `tealkit_index_local_docs`: Directory document ingestion supporting PDF, Word (`.docx`), Markdown, and text.
  - `tealkit_search_knowledge`: Hybrid Reciprocal Rank Fusion (BM25 FTS5 + cosine similarity) with exact line number citations.
  - `tealkit_get_source_doc`: Complete original document inspection.
- **Pillar 3: Mobile Push Alerts & Human-in-the-Loop Approvals**:
  - `tealkit_send_mobile_alert`: Push notifications to developer smartphones via ntfy.sh, TealKit SSE, or FCM.
  - `tealkit_request_mobile_approval`: Interactive mobile approval prompt with timeout.
- **Registries & Documentation**:
  - Smithery certification (`smithery.yaml`).
  - Glama compatibility and client integration guides for Claude Desktop and Cursor IDE.
