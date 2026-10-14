# EDUNEXUS AI Runtime — deployment and verification

## What this slice implements

- A Neon Function using the web-standard `fetch(Request) -> Response` contract.
- `GET /health` reports whether authentication and inference configuration exist; it never exposes secret values.
- `POST /chat` requires a Bearer JWT whose RS256 signature is checked against Neon Auth JWKS, checks expiry, applies an in-memory per-user request cap, validates request size, and allows only the EDUNEXUS Pages origin by default.
- A small specialist registry routes a request to at most two bounded specialists in parallel.
- The model provider is OpenAI-compatible and configured only through server-side environment variables.
- Fail-closed behavior: absent model configuration returns HTTP 503; no fabricated answer is produced.
- The response explicitly warns that this first slice has no RAG citations yet.

## Required server-side environment

- `NEON_AUTH_JWKS_URL`: exact JWKS URL from the active Neon Auth configuration.
- `NEON_AUTH_ISSUER`: optional exact issuer claim, only set after verifying a real JWT's `iss`.
- `MODEL_API_BASE_URL`: provider's OpenAI-compatible API base URL.
- `MODEL_API_KEY`: secret key; never add it to GitHub, frontend JavaScript, a commit, or a public issue.
- `MODEL_ID`: exact model identifier supported by the chosen provider.
- `APP_ORIGIN`: optional origin override. Default is `https://akvisomr-eng.github.io`.

Do not set `NEON_AUTH_ISSUER` by guessing. Verify it against a legitimate session token and the provider's official docs first. The browser must send the current Neon Auth JWT in the Authorization header.

## Deploy

1. Review `neon.ts` and confirm the linked project/branch before any deployment.
2. Configure the server-side secrets in a private local environment file ignored by Git.
3. Use the current Neon CLI version and deploy the `edunexusai` function to a non-production branch first.
4. Test `GET /health`, invalid/no-token rejection, real signed-in request, provider failure, origin rejection, and usage caps.
5. Only after tests pass and the exact target is confirmed, deploy to the intended production branch and verify the returned invocation URL.
6. Wire the Pages frontend to the verified function URL in a separate change. Never put provider credentials in Pages JavaScript.

## Limits / not yet implemented

- This is a specialist-routing runtime, not proof that all 15 architecture roles are live.
- RAG corpus ingestion, source chunking, citations, admin review workflow, persistent rate limits, usage budgets, and frontend chat UI are not implemented by this slice.
- In-memory rate limits are per isolate and are only a safety floor, not a durable abuse-control system.
- Do not use dark-web sources by default. Use lawful, public, licensed, verifiable sources and human approval before indexing.
- A model provider and its secret must be configured before inference can work. No provider key is currently committed or assumed.
