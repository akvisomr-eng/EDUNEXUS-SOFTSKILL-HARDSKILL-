# EDUNEXUS AI production readiness and Groq launch gate

**Current decision: do not open a public generative-AI trial yet.** The web application is published and the Neon AI runtime is deployed, but the production health probe last reported `inferenceConfigured: false`. The app must not describe knowledge-only retrieval as a live generative model.

## Current verified baseline

- Frontend: GitHub Pages.
- Backend, identity and persistent per-user quota: Neon.
- Curated corpus: `edunexus-curated-knowledge-2026-10-16-v6` (57 chunks), mirrored to `web/knowledge-corpus.json`.
- Chat requires a verified Neon Auth JWT; unauthorized requests return HTTP 401.
- Cross-account practice-session isolation smoke test passes on the disposable Neon branch.
- Project mode is planning-only. It does not write repositories, commit code, or deploy projects.
- Groq inference is **not ready until** the health endpoint reports `inferenceConfigured: true` and `inferenceProvider: "groq"`.

## Configure Groq without exposing the secret

In the Neon Console, open project **EDUNEXUS SOFTSKILL & HARDSKILL**, branch **production**, Function **edunexusai**, and its environment/deployment settings. Add or update these server-side variables:

- `AI_ENABLED=true`
- `MODEL_PROVIDER=groq`
- `MODEL_API_KEY` = a valid Groq API key, stored only as a server-side secret
- `MODEL_ID` = a model ID currently enabled for the Groq account

The function uses Groq's fixed OpenAI-compatible endpoint when `MODEL_PROVIDER=groq`; the browser must never receive the key. Keep the existing `APP_ORIGIN`, `NEON_AUTH_JWKS_URL`, `DATA_API_URL` (where configured), and `KNOWLEDGE_CORPUS_URL` values. Do not paste keys into chat, commit them to Git, add them to the frontend, or print them in logs. Do not change to another provider as a fallback.

After saving the variables, deploy a new Function version. Verify `GET /health` reports:
- `status: "ok"`
- `authConfigured: true`
- `persistentQuotaConfigured: true`
- `knowledgeVersion: "edunexus-curated-knowledge-2026-10-16-v6"`
- `inferenceConfigured: true`
- `inferenceProvider: "groq"`

Health is necessary but not sufficient. Run an authenticated chat smoke test and confirm a non-empty model response, expected agent/source metadata, and graceful handling of invalid auth, disallowed origins, rate limits, provider 429/5xx, timeout, empty model output, and quota-service failure. The knowledge-only fallback must clearly disclose that no generative model was used; project mode must stay unavailable if model inference is not configured.

## Public-trial gate

Keep a limited public trial closed until all of these are evidenced:

1. Groq health and authenticated inference checks pass on production.
2. Auth, profile ownership, persistent quotas, and cross-account RLS checks pass.
3. A real authenticated model response and the no-model fallback both behave as expected.
4. Rate limits and provider failures are handled without leaking secrets or personal data.
5. Privacy notice, consent/data-retention rules, terms, user feedback path, and incident/disable procedure are reviewed.
6. Usage/cost limits and an emergency switch (`AI_ENABLED=false`) are tested.

The readiness workflow checks the production health gate without displaying secrets. A failed gate is intentional and means the trial is not ready; it is not a reason to weaken authentication or bypass quotas.
