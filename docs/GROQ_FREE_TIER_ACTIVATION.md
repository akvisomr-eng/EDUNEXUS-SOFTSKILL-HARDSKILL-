# EDUNEXUS — Groq free-tier activation and public pilot gate

**Purpose:** test Groq as an external model provider while keeping Neon as the database/auth platform and keeping provider costs at Rp0. This is an activation runbook, not evidence that a live model call has already succeeded.

## Current verified code contract

The Neon Function at `neon/functions/edunexusai/index.mjs` already supports an OpenAI-compatible provider through server-side variables:

- `MODEL_API_BASE_URL`
- `MODEL_API_KEY`
- `MODEL_ID`
- `AI_ENABLED`

The runtime appends `/chat/completions` to the configured base URL. Do not include that path in `MODEL_API_BASE_URL`. Keep the current production `AI_ENABLED=false` until the real authenticated provider test passes.

## Groq free-tier candidate configuration

Use the following as the initial test configuration; confirm the model remains available and the actual limits shown in the Groq account before activation:

- `MODEL_API_BASE_URL=https://api.groq.com/openai/v1`
- `MODEL_ID=openai/gpt-oss-20b`
- `MODEL_API_KEY=<secret created in the official Groq console>`
- `AI_ENABLED=true` only for the preview branch during initial validation

Official references:

- OpenAI-compatible API: https://console.groq.com/docs/openai
- Supported models and exact active model IDs: https://console.groq.com/docs/models
- Rate limits: https://console.groq.com/docs/rate-limits
- Account/API key console: https://console.groq.com/

Groq documents an OpenAI-compatible base URL of `https://api.groq.com/openai/v1`. The model `openai/gpt-oss-20b` is listed in its model documentation and the free-plan rate-limit table at the time this runbook was written. Provider limits can change and may differ by organization/account. The account's own limits page is authoritative. A free tier is not a service-level guarantee.

## Secret handling and cost guardrails

1. Create the API key only in the official Groq console.
2. Store it only in the **preview Neon Function server-side environment** as `MODEL_API_KEY`. Never paste it into ChatGPT, a GitHub issue, a commit, browser JavaScript, Pages configuration, or logs.
3. Keep `AI_ENABLED=false` in production during the pilot. Do not enable production inference as part of this initial preview test.
4. Verify the account is on the free plan, check model availability/limits, and ensure no paid plan, billing upgrade, or paid add-on is enabled. Do not make purchases or enable auto-upgrades.
5. Keep EDUNEXUS's persistent quota at 10 requests/minute and 100/day per application identity. This is an application limit, not a substitute for the provider's organization-wide rate limits or billing controls.
6. The runtime sends the user message and curated source context to the model provider. During the pilot, use synthetic/non-sensitive prompts only. Do not send student records, names, contact details, minors' data, credentials, confidential work, or sensitive submissions. Review the provider's current privacy/data-use terms before any real-user data is permitted.
7. Do not retry repeatedly on 429/5xx. Stop testing when a quota is reached; preserve the fail-closed fallback.

## Preview validation checklist

Record date, branch, deployment ID, model ID, status code, and sanitized result. Never record the API key or full user content.

- [ ] Confirm the preview branch and function URL before changing environment variables.
- [ ] `GET /health` returns HTTP 200, `authConfigured=true`, `knowledgeConfigured=true`, and a non-empty corpus version; no secret appears in the response.
- [ ] No-token `POST /chat` returns HTTP 401.
- [ ] A disallowed Origin is rejected; only the configured EDUNEXUS Pages origin is allowed.
- [ ] A synthetic Indonesian learning prompt with a valid signed-in test account returns a non-empty model answer and mode `specialist_parallel_v1` (or the appropriate single-specialist mode).
- [ ] Provider response is relevant, in Indonesian, grounded in provided sources where available, and does not invent source IDs. Check factual accuracy manually.
- [ ] Project mode returns a planning-only result; it does not claim to edit a repository, execute code, commit, or deploy.
- [ ] Oversized/malformed messages are rejected; persistent quota failure fails closed; app quota produces HTTP 429 when reached.
- [ ] Invalid/revoked provider key, provider 429, timeout, and provider 5xx produce safe generic errors with no key, upstream body, or stack trace exposed.
- [ ] The UI continues to label the current mode accurately; no generative AI feature is marketed as active before the live request test passes.
- [ ] Confirm free-tier limits remain adequate and review data retention/privacy terms before any public pilot.

## Public pilot gate

A public pilot is **not approved** until every preview validation item passes, the privacy notice/terms are reviewed, a support and incident route is available, retention/deletion expectations are documented, two-account tenant isolation has been tested, and a rollback is rehearsed.

After preview validation, obtain owner approval before setting the production secret or changing production `AI_ENABLED`. A production activation must be a separate controlled deployment with a fresh authenticated smoke test and an immediate rollback path. Do not enable production simply because `/health` reports `inferenceConfigured=true`; only a successful authenticated model request proves provider access.

## Fallback and rollback

- Before provider activation, learning mode uses clearly labeled curated retrieval and Project Builder fails closed.
- If any validation fails, set `AI_ENABLED=false` in the affected Neon Function environment and deploy a new function version. Verify `/health` reports `inferenceDisabled=true` and `inferenceConfigured=false`; confirm curated retrieval still works and Project Builder remains unavailable.
- Never show a fabricated answer as if it came from a model. Never silently switch a failed model request into an unlabelled answer.

## Current status

**Pending owner action:** create a Groq API key in the official console and store it directly in the preview Neon Function secret configuration. No key has been requested in chat, no provider request has been represented as successful, no production AI activation has been made, and no paid plan or credit purchase has been performed.
