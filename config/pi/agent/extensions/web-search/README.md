# Web search

Expose the `web_search` tool using Exa's hosted MCP endpoint at `https://mcp.exa.ai/mcp`. The extension sends an HTTP JSON-RPC request directly; it does not start an MCP process or read an API key. There is no slash command.

## Tool input

```json
{
  "query": "Jujutsu revset documentation",
  "limit": 5
}
```

`query` is required. `limit` is an optional integer from 1 to 10, defaulting to 5. Requests call `web_search_exa` with automatic search, live crawling as a fallback, and a 3,000-character context target.

Results are formatted as titles, URLs, and snippets. The model receives guidance to use targeted queries and summarize results rather than paste raw output. The endpoint can return fewer results than requested.

## Requirements and output

Pi needs outbound HTTPS access to Exa. Search queries are sent to that service, so avoid including secrets or private source text. HTTP, RPC, and service errors become tool errors. Requests honor cancellation, but the extension sets no additional request timeout.

Output is truncated at 2,000 lines or 50 KiB. When truncated, the complete formatted result is retained in a mode-0600 temporary `pi-web-search-*/results.txt` file, and the tool returns its path. These files are not automatically removed.

See [extension loading](../README.md#activation).
