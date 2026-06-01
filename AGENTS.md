# AGENTS.md — cf-controller

Shared startup, DoD, and session rules: **`agent-contract-master/AGENTS.md`** (multi-root workspace).

Work only in this repo (`cf-controller` root) for git, `feature_list.json`, and `claude-progress.md`.

## Project

**CF-01 — Cloudflare mesh network implementation** (see `feature_list.json`).

This repo owns Cloudflare / controller automation and related infra (for example `terraform/`). It does not own homelab Proxmox, FortiGate, or C9300 design — see **`proxmox/AGENTS.md`**.

## Layout

| Path | Purpose |
|------|---------|
| `terraform/` | Infra definitions (for example `sg-hl-cfvm/`) |
| `init.sh` | Deps + baseline verification for this repo |
| `feature_list.json` | Feature backlog and evidence |
| `claude-progress.md` | Session state (create when work starts) |

## Verification

- Run `./init.sh` from this repo root after dependency or layout changes
- Record verification commands and results in `feature_list.json` / `claude-progress.md`
- Do not mark features complete without ran checks

## Secrets

Follow `agent-contract-master/docs/secrets-baseline.md`. Add `docs/1password-secrets.md` here when Cloudflare/API tokens are wired (item names only, no values).

## Do not

- Apply homelab VLAN / Proxmox / FortiGate rules from the proxmox repo unless explicitly cross-cutting
- Commit API tokens, tunnel secrets, or `.env` files
