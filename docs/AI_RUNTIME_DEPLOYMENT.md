# EDUNEXUS AI Runtime — deployment and verification

## What this slice implements

- A Neon Function using the web-standard `fetch(Request) -> Response` contract.
- `GET /health` reports authentication, knowledge corpus readiness/version/chunk count and inference configuration; it never exposes secret values.
- `POST /chat` requires a Bearer JWT whose RS256 signature is checked against Neon Auth JWKS, checks expiry, applies an in-memory per-user request cap, validates request size, and allows only the EDUNEXUS Pages origin by default.
- A bounded specialist registry routes learning requests to up to four specialists and project-planning requests to a fixed four-agent team (Project Manager, Solution Architect, Software Engineer, QA & Security).
- The model provider is OpenAI-compatible and configured only through server-side environment variables.
- When a model key is absent, learning mode returns an explicitly labeled curated-retrieval-only answer with matched source summaries and links. Project mode fails closed with HTTP 503 instead of presenting a fake AI plan. When a model key is configured, project mode runs the four bounded specialists in parallel and labels the result as planning only; it does not claim to edit code, run tests, commit, or deploy.
- A 24-chunk curated corpus of EDUNEXUS product/security guidance and external source summaries is deployed with the production function; lexical-overlap retrieval selects up to four chunks and responses expose source IDs/URLs.
- Retrieval is lexical, not embedding/vector search. A public allowlist registry has 14 source records. A weekly metadata-only refresh job records public page title/description/HTTP metadata and opens a review PR; it does not copy full pages or auto-promote unreviewed text into the runtime corpus.

## Required server-side environment

- `NEON_AUTH_JWKS_URL`: exact JWKS URL from the active Neon Auth configuration.
- `NEON_AUTH_ISSUER`: optional exact issuer claim, only set after verifying a real JWT's `iss`.
- `MODEL_API_BASE_URL`: provider's OpenAI-compatible API base URL.
- `MODEL_API_KEY`: secret key; never add it to GitHub, frontend JavaScript, a commit, or a public issue.
- `MODEL_ID`: exact model identifier supported by the chosen provider.
- `APP_ORIGIN`: optional origin override. Default is `https://akvisomr-eng.github.io`.

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
- Production model inference is not yet configured because `MODEL_API_KEY` is absent from the current production function environment metadata. The source-only learning assistant works without that key; model-generated multi-agent answers and Project Builder planning require a provider key stored as a Neon Function secret. Repository execution, patch generation, CI repair, and deployment automation are not enabled. No provider key is committed or assumed.
