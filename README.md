# EDUNEXUS — Soft Skill & Hard Skill

Human Skill Intelligence & Development Platform.

**Aplikasi live:** https://akvisomr-eng.github.io/EDUNEXUS-SOFTSKILL-HARDSKILL-/

Frontend produksi menggunakan GitHub Pages, Neon Auth, dan Neon Data API. Supabase tetap tersedia sementara sebagai sumber rollback; data bisnis produksi tidak dihapus saat cutover.

This repository is initialized from EDUNEXUS MASTER BLUEPRINT v2.0.

## Commercial launch controls

Before offering EDUNEXUS to paying customers, review these operational documents:

- [Commercial readiness gates](docs/COMMERCIAL_READINESS.md) — release blockers, stages, and evidence register.
- [Draft privacy notice](docs/PRIVACY_NOTICE_DRAFT.md) — internal draft; must be completed and reviewed before publication.
- [Draft terms of service](docs/TERMS_OF_SERVICE_DRAFT.md) — internal draft; not yet suitable as final customer terms.
- [Secure AI runtime activation runbook](docs/AI_RUNTIME_SECURE_ACTIVATION_RUNBOOK.md) — server-side model credential setup and verification.\n- [Groq free-tier activation gate](docs/GROQ_FREE_TIER_ACTIVATION.md) — Rp0 provider configuration, preview-only tests, privacy, quotas, fallback, and public-pilot criteria.
- [Production DB promotion gate](docs/PRODUCTION_DB_PROMOTION_GATE.md) — verified preview/production schema difference and required two-account RLS tests before migration 0011 is promoted.

**Current launch gate:** a green CI/browser smoke workflow does not mean model inference, payments, or full commercial operations are ready. Confirm the current evidence in the [Commercial Readiness document](docs/COMMERCIAL_READINESS.md).
