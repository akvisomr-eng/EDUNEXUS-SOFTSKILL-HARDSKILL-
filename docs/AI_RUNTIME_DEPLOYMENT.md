# EDUNEXUS AI Runtime — deployment and verification

## What this slice implements

- A Neon Function using the web-standard `fetch(Request) -> Response` contract.
- `GET /health` reports authentication, knowledge corpus readiness/version/chunk count and inference configuration; it never exposes secret values.
- `POST /chat` requires a Bearer JWT whose RS256 signature is checked against Neon Auth JWKS, checks expiry, applies a bounded in-memory cap and a persistent Data API quota of 10 requests/minute and 100/day per application identity, validates request size, and allows only the EDUNEXUS Pages origin by default.
- A bounded specialist registry routes learning requests to up to four specialists and project-planning requests to a fixed four-agent team (Project Manager, Solution Architect, Software Engineer, QA & Security).
- The model provider is OpenAI-compatible and configured only through server-side environment variables.
- When a model key is absent, learning mode returns an explicitly labeled curated-retrieval-only answer with matched source summaries and links. Project mode fails closed with HTTP 503 instead of presenting a fake AI plan. When a model key is configured, project mode runs the four bounded specialists in parallel and labels the result as planning only; it does not claim to edit code, run tests, commit, or deploy.
- A 51-chunk curated corpus of EDUNEXUS product/security guidance and external source summaries is deployed with the production function; lexical-overlap retrieval selects up to four chunks and responses expose source IDs/URLs.
- Retrieval is lexical, not embedding/vector search. A public allowlist registry has 14 source records. A weekly metadata-only refresh job records public page title/description/HTTP metadata and opens a review PR; it does not copy full pages or auto-promote unreviewed text into the runtime corpus.

## Required server-side environment

- `NEON_AUTH_JWKS_URL`: exact JWKS URL from the active Neon Auth configuration.
- `NEON_AUTH_ISSUER`: optional exact issuer claim, only set after verifying a real JWT's `iss`.
- `MODEL_API_BASE_URL`: provider's OpenAI-compatible API base URL.
- `MODEL_API_KEY`: server-side provider key or a Neon credential scoped to `ai_gateway:invoke`; never add it to GitHub, frontend JavaScript, a commit, or a public issue. The Neon Gateway credential must only be used with its matching branch gateway URL.
- `MODEL_ID`: exact model identifier supported by the chosen provider.
- `APP_ORIGIN`: optional origin override. Default is `https://akvisomr-eng.github.io`.
- `AI_ENABLED`: optional emergency switch. Set to `false` in the server-side Neon Function environment and deploy to disable provider inference while keeping curated retrieval available.

Do not set `NEON_AUTH_ISSUER` by guessing. Verify it against a legitimate session token and the provider's official docs first. The browser must send the current Neon Auth JWT in the Authorization header.

## Deploy

1. Confirm the exact Neon project and target branch ID before any deployment. The production function has been deployed to project `holy-breeze-21216615`, branch `production` (`br-bitter-king-azb11lde`), and the live `/health` endpoint was verified by GitHub Actions.
2. Configure the server-side secrets in a private local environment file ignored by Git.
3. Use the current Neon CLI or Neon Functions management API to deploy `neon/functions/edunexusai/index.mjs` plus `knowledge.json` to a non-production branch first. The ZIP must place both files at its root; the runtime does not install npm dependencies.
4. Test `GET /health`, invalid/no-token rejection, real signed-in request, provider failure, origin rejection, and usage caps.
5. Production function deployment #7 completed on 2026-10-15. GitHub Actions verified live production health, authentication configuration, corpus version `edunexus-curated-knowledge-2026-10-14-v3` with 51 chunks, and honest `inferenceConfigured=false` state.
6. The GitHub Pages frontend is wired to the production function. The live Pages smoke test passed and confirmed the tutor / Project Builder mode selector is published. Project Builder is planning-only and returns an explicit unavailable response while model inference is unconfigured. Never put provider credentials in Pages JavaScript.

## Rp0 provider candidate

Google documents an OpenAI-compatible Gemini API endpoint at `https://generativelanguage.googleapis.com/v1beta/openai/`; obtain a key in Google AI Studio and verify a currently available model ID before use. Set `MODEL_API_BASE_URL`, `MODEL_API_KEY`, and `MODEL_ID` only as server-side function environment variables. Do not commit the key. Free-tier terms may permit use of submitted data to improve products; do not send personal, confidential, or identifiable learner data unless a privacy review confirms the provider terms are appropriate. Official references: https://ai.google.dev/gemini-api/docs/openai and https://ai.google.dev/gemini-api/docs/pricing.md.

## Limits / not yet implemented

- This is a bounded specialist-routing runtime, not proof that all 15 architecture roles are live.
- Automated full-text web ingestion, source licensing/review UI, embeddings/vector or semantic search, persistent rate limits, and durable usage budgets are not implemented. Current automation refreshes only public metadata and opens review PRs.
- In-memory rate limits are per isolate and are only a safety floor, not a durable abuse-control system.
- Do not use dark-web sources by default. Use lawful, public, licensed, verifiable sources and human approval before indexing.
- Production deployment #15 briefly configured the Neon AI Gateway endpoint and model credential. An authenticated E2E request on the preview branch returned HTTP 403; the sanitized upstream message indicated that AI Gateway is not enabled for the account's current plan. This is a plan-access blocker, not a source-code syntax failure. To avoid repeated failed calls and to keep public health truthful, production deployment #16 sets `AI_ENABLED=false`; `/health` should report `inferenceConfigured=false`, learning requests use clearly labeled curated retrieval, and Project Builder fails closed. Re-enable only after the owner approves an eligible Neon plan/credits or supplies a valid external provider key, then pass a real authenticated inference test. Repository execution, patch generation, CI repair, and deployment automation are not enabled. No credential is committed.


## Groq free-tier candidate (preview only)

The runtime's existing OpenAI-compatible provider interface can use Groq without changing Neon. Candidate values are `MODEL_API_BASE_URL=https://api.groq.com/openai/v1` and `MODEL_ID=openai/gpt-oss-20b`; set `MODEL_API_KEY` only in the server-side Neon Function environment. The function appends `/chat/completions` itself. Confirm current model availability and account-specific free limits in the official [Groq models](https://console.groq.com/docs/models), [OpenAI compatibility](https://console.groq.com/docs/openai), and [rate-limit](https://console.groq.com/docs/rate-limits) documentation. Keep production `AI_ENABLED=false`; validate only on preview first. Follow [the Groq activation gate](GROQ_FREE_TIER_ACTIVATION.md). A configured key or healthy `/health` response is not proof of successful inference; a real authenticated request is required. Do not send personal, student, minor, or confidential data during the pilot.
