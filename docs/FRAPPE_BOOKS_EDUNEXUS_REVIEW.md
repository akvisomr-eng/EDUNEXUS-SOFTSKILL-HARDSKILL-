# EDUNEXUS review: Frappe Books

**Review date:** 2026-10-16  
**Requested repository:** https://github.com/frappe/books

## Decision

Use Frappe Books as a **feature reference and source of original accounting-learning projects**, not as a codebase to import into EDUNEXUS. The requested `frappe/books` repository is archived and licensed under AGPL-3.0. Frappe's newer `frappe/frappe-books` repository is an AGPL-3.0-only application built on the Frappe Framework. Reusing code or bundling either application can create license and source-disclosure obligations; a free/open-source license does not mean there are no compliance costs.

References:
- [Requested archived repository](https://github.com/frappe/books)
- [Original AGPL license](https://github.com/frappe/books/blob/master/LICENSE)
- [Current Frappe Books app](https://github.com/frappe/frappe-books)
- [Current app feature and stack overview](https://github.com/frappe/frappe-books/blob/develop/README.md)

## What is useful for EDUNEXUS

| Area | EDUNEXUS application |
|---|---|
| Double-entry ledger | Hard-skill module teaching debit/credit, balanced journal entries and ledger posting |
| Financial statements | Practice generating a trial balance, profit-and-loss, balance sheet and cash-flow summary from synthetic data |
| Sales and purchases | Project templates for quote → invoice → payment and purchase bill → expense |
| Inventory | Simulated stock ledger, receipts/issues and stock balance |
| Point of sale | Optional business-simulation project for checkout, receipts and simple daily reconciliation |
| Mobile-friendly finance UX | Reference for responsive tables, clear status states and printable documents; implement with EDUNEXUS's existing frontend stack |
| Roles and permissions | Design inspiration only; implement authorization using the existing Neon identity, policies and tests |

## Recommended first integration

Start with **learning content and a safe Project Builder template**, not a production accounting system:

1. **Dasar Akuntansi** — assets, liabilities, equity, revenue, expenses and the accounting equation.
2. **Jurnal Berpasangan** — journal entries, debits/credits, general ledger and trial balance using fictional transactions.
3. **Buku Kas Usaha Mikro** — income, expenses, invoice/payment tracking and a monthly profit-and-loss report using synthetic data.
4. **Anggaran Kursus/Institusi** — planned vs actual course revenue, mentor fees, scholarships and remaining budget.
5. **Persediaan Simulasi** — stock receipts/issues and their accounting effects, without changing real stock.
6. **Rekonsiliasi Pembayaran** — match fictional invoices and payments and identify discrepancies.

These are educational simulations, not a claim that EDUNEXUS currently provides a compliant production accounting engine.

## Architecture and safety boundaries

- Preserve the existing EDUNEXUS architecture and Neon as the system of record. This review does not add Frappe hosting, a new database, or third-party runtime calls.
- Do not copy upstream source files, UI components, assets, or substantial code snippets by default. If code reuse is later proposed, conduct a legal/license and dependency review first and document AGPL compliance obligations.
- Keep AI agents in advisory mode. They may explain transactions, draft reports from authorized data and flag inconsistencies, but must not independently post journals, close periods, issue payouts or change tax treatment.
- A future real finance module must include organization-scoped authorization, audit trails, balanced-journal constraints, decimal-safe currency arithmetic, idempotency, reversal entries, period locks, approval workflows, backup/restore testing and cross-account isolation tests.
- Never send learner identities, credentials, private institutional finance records or transaction details to upstream services by default.
- Indonesian tax and accounting requirements must be checked against current official sources and reviewed by a qualified professional before commercial use.

## Acceptance gates before production finance

1. Requirements and accounting model approved by the product owner and qualified reviewer.
2. Schema constraints prove every posted journal balances; failed or repeated requests cannot double-post.
3. Two-account and cross-organization isolation tests pass.
4. Draft/post/reverse/period-close transitions are audited and authorized.
5. Financial reports reconcile to ledger fixtures; rounding and currency tests pass.
6. Human approval is required for consequential actions.
7. CI, staging smoke tests and backup/restore checks pass.
8. Any applicable Indonesian tax/reporting claims have current official sources and professional review.

## Files in this change

- `knowledge/frappe-books-review.json`: machine-readable review, candidate learning modules and production gates.
- `knowledge/sources.json`: source registry entries for the archived repository and current app.
- `neon/functions/edunexusai/knowledge.json`: source-grounded AI knowledge chunk for relevant accounting-learning queries.
- `tests/edunexus-ai-runtime.test.mjs`: checks the default-off and no-code-copy policy.
