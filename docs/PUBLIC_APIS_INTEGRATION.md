# EDUNEXUS integration review: marcelscruz/public-apis

**Review date:** 2026-10-16  
**Repository:** https://github.com/marcelscruz/public-apis  
**Upstream license:** MIT (the repository catalog itself; this does not license each API or its data).

## Decision

Use this repository as a **discovery catalog for project-based learning**, not as a package to import wholesale and not as a live runtime dependency. It is a broad, community-maintained directory across AI, dictionaries, programming, science, open data, weather, security, books, and other categories. Its table fields such as authentication, HTTPS and CORS are useful triage hints, not a service-level guarantee or a substitute for current provider documentation.

EDUNEXUS now carries a small, reviewed candidate list in `knowledge/public-api-catalog.json` and a source-grounded discovery chunk in the curated AI corpus. The metadata-only knowledge refresh registry also links the upstream repository. **Live API calls remain disabled by default**; this change does not add third-party network requests to the learner frontend or AI runtime.

## Priority candidates

| Priority | API | Learning use | Decision |
|---|---|---|---|
| 1 | [JSONPlaceholder](https://jsonplaceholder.typicode.com/) | REST/JSON, HTTP methods, test fixtures and API client practice with fake data | Best first sandbox candidate; confirm current policy before workshops |
| 2 | [REST Countries](https://restcountries.com/) | Geography, JSON transformation, filters, charts and data literacy | Candidate; check terms, version, attribution and limits |
| 3 | [Free Dictionary API](https://dictionaryapi.dev/) | Vocabulary and glossary activities | Candidate; verify content rights and source quality |
| 4 | [Open Library](https://openlibrary.org/developers/api) | Book discovery, reading lists and information literacy | Candidate; obey usage guidelines and reuse rules |
| 5 | [Open Trivia DB](https://opentdb.com/api_config.php) | Low-stakes quiz prototypes and JSON parsing | Candidate only; not validated curriculum or high-stakes assessment |
| 6 | [Open-Meteo](https://open-meteo.com/en/docs) | Weather/environmental data, time series and charting | Candidate; verify current free and commercial terms before activation |

The catalog intentionally excludes from the first implementation AI gateways, payment/finance, identity/authentication vendors, malware/file scanning and location tracking APIs. They either duplicate the existing Groq/Neon design, add sensitive data or operational risk, or need a separate product/security justification.

## Integration boundaries

- Keep Neon as the backend and data system; do not migrate to another database or hosting provider.
- The API catalog is discovery metadata, not a promise that an endpoint is live, free, safe, licensed for commercial use, or available without registration.
- The upstream repository's MIT license applies to that repository, not automatically to every provider or dataset listed in it.
- Do not scrape or bulk-import the entire upstream README. Keep provider URLs, short original descriptions and learning mappings; link users to canonical documentation.
- No API keys are stored in this registry. Do not expose secrets in GitHub Pages or browser code.
- Never forward learner names, emails, JWTs, submissions, private institutional content, or other personal data to an external API by default.
- Any future live connector must be a narrow server-side adapter with explicit host allowlisting, request validation, timeout, bounded response size, caching, per-user quotas, sanitized errors, provenance, and a fallback when the provider is unavailable.
- Do not present external API data as curriculum authority. Add source date and provider link, verify factual claims, and use human-reviewed rubrics for consequential assessment.

## Tests and release gates for a future live connector

1. Provider documentation and terms checked at implementation time; commercial-use rights, attribution, privacy and rate limits recorded.
2. Contract tests with fixtures; no live provider calls in the normal CI suite.
3. Network tests in a controlled workflow for HTTPS, timeout, malformed responses, 429/5xx and size limits.
4. Privacy tests confirm that no auth token or learner-identifying data is forwarded.
5. Fallback tests prove that the lesson remains usable if the provider fails.
6. Accessibility and Indonesian-language UI checks for any new learner-facing module.
7. Feature flag defaults off until review passes; monitor usage and provide an emergency disable switch.

## Files changed

- `knowledge/public-api-catalog.json`: curated candidate list with disabled-by-default flags and per-provider review requirements.
- `knowledge/sources.json`: adds the upstream catalog as a metadata-only source.
- `neon/functions/edunexusai/knowledge.json`: adds one source-grounded knowledge chunk and increments the corpus version.
- `tests/edunexus-ai-runtime.test.mjs`: checks catalog policy and corpus provenance.
- `.github/workflows/ci.yml`: validates catalog shape and default-disabled policy.

## Upstream references

- [Public APIs catalog](https://github.com/marcelscruz/public-apis)
- [Upstream MIT license](https://github.com/marcelscruz/public-apis/blob/main/LICENSE)
- [Open-Meteo documentation](https://open-meteo.com/en/docs)
- [Open Library API guidance](https://openlibrary.org/developers/api)
- [JSONPlaceholder](https://jsonplaceholder.typicode.com/)
