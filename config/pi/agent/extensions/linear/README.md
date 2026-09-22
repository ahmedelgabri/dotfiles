# Linear GraphQL

Expose the `linear_graphql` tool for read-only queries against `https://api.linear.app/graphql`. The model can inspect issues, projects, and schema types without a fixed set of prewritten queries. There is no slash command.

## Credentials

Store a Linear API key with Read permission only in the macOS login keychain using the repository's [`secret` helper](../../../../zsh.d/zsh/bin/secret):

```sh
secret set linear-api-token
```

The helper prompts for the value; do not put the token in the command line. The extension reads it for each request by executing `${XDG_CONFIG_HOME:-$HOME/.config}/zsh/bin/secret get linear-api-token`, not by searching PATH or reading an API-key environment variable. Keychain access has a 60-second timeout, so respond to any macOS access dialog before retrying.

## Tool input

```json
{
  "query": "query InspectQuery { __type(name: \"Query\") { name } }",
  "variables": {}
}
```

`query` is required; `variables` is an optional JSON object. Use targeted `__type` introspection when the schema is uncertain, pass dynamic values through variables, and request only needed fields. Paginate explicitly with cursors and `pageInfo`, normally using `first: 50` or less. The extension does not fetch subsequent pages automatically.

Mutation and subscription operation definitions are rejected before credentials are read or a request is sent. Keep the API key read-only as a separate restriction. GraphQL errors in successful HTTP responses are returned to the model so it can correct the query; transport and HTTP failures are reported as tool errors.

## Limits and output

- Query text and serialized variables are each limited to 64 KiB.
- API requests time out after 30 seconds and honor cancellation.
- Responses larger than 5 MiB are rejected; narrow or paginate the query.
- Tool output is truncated at 2,000 lines or 50 KiB. When truncated, the complete response is retained in a mode-0600 temporary `pi-linear-*/response.json` file, with its path included in the result.

Response details include GraphQL error presence and available request/complexity rate-limit headers. Retained response files can contain private workspace data; remove them when no longer needed.

See [extension loading](../README.md#activation).
