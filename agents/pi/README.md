# Pi and Swanbots

The shared `models.json` registers `swanbots/qwen3.8-27b` in Pi. Both portable
profiles link it to `~/.pi/agent/models.json`; Pi credentials and sessions are not
linked. If that file already contains other providers, merge them before adopting
the shared file. The `unused` API key is a placeholder, not a credential.

Install Pi using the [official instructions](https://pi.dev/docs/latest/quickstart).
The initial setup was tested with Pi 1.2.0 on macOS and Torvus.

With Tailscale connected:

```sh
pi --model swanbots/qwen3.8-27b
```

Or use `/model` and select **Qwen on Swanbots**. This configuration does not change
the default provider. Swanbots runs inference; each client executes its own tools.

The API base URL is `http://swanbots.dzo-alpha.ts.net:8083/v1`. Its HTTP traffic
travels over Tailscale. No SSH tunnel or separate API credential is needed with
the current server configuration. Torvus connects independently of the Mac.
Jay's adapter takes the same URL without `/v1`.

The configured context window is the server-reported 81,920 tokens; output is
capped at 8,192. If Swanbots changes its loaded model, check `/v1/models` and
`/props`, then update the model ID and context limit here.

Quick check (disables project context, extensions and tools):

```sh
pi --model swanbots/qwen3.8-27b --offline --no-session --no-approve \
  --no-context-files --no-extensions --no-mcp --no-skills \
  --no-prompt-templates --no-tools -p 'Reply with exactly: pong'
```
