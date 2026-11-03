# Architecture Decision Records

Accepted architecture decisions for the I-Ching Consultant app. Each record is
written in a lightweight [MADR](https://adr.github.io/madr/) style: **Status**,
**Context**, **Decision**, **Consequences**, plus follow-ups where relevant.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-remote-llm-support.md) | Allow remote LLM providers alongside on-device models | Accepted |

## Adding a new ADR

1. Copy the structure of an existing record into `NNNN-short-title.md`.
2. Set the status to `Proposed` until the decision is agreed, then `Accepted`.
3. Add a row to the table above.
4. If a new decision replaces an old one, mark the old record `Superseded by ADR NNNN`.
