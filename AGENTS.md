# AGENTS.md - cf-controller

Shared workspace rules live in `agent-contract-master/AGENTS.md`. This file adds the local harness for the Cloudflare controller repo.

Work only from the `cf-controller` repo root for git commands, harness state, and Terraform validation.

## Project

CF-01 - Cloudflare mesh network implementation.

This repo owns Cloudflare/controller automation and related Terraform under `terraform/`. It does not own Proxmox, FortiGate, C9300, VLAN, or homelab host design unless a task explicitly says it is cross-repo work.

## Startup Workflow

Before writing code:

1. Confirm `pwd` is `/home/d3/Github/cf-controller`.
2. Read `claude-progress.md` for Current State, Current Objective, and Recommended Next Step.
3. Read `feature_list.json` and pick the highest-priority unfinished feature whose dependencies are satisfied.
4. Review recent commits with `git log --oneline -5`.
5. Run `./init.sh` and treat any failure as the first task.

`claude-progress.md` is the canonical progress log for this workspace. If a tool asks for `progress.md`, treat it as an alias for `claude-progress.md` rather than creating a second source of truth.

## Verification Commands

- Baseline static check: `./init.sh`
- Terraform lint/static check: `terraform -chdir=terraform/cloudflared fmt -check -diff` (run by `./init.sh`)
- Terraform validation test: `terraform -chdir=terraform/cloudflared validate` (run by `./init.sh`)
- Manual credentialed plan, only when needed: `terraform/cloudflared/tf.sh plan`

`./init.sh` must stay safe for a fresh checkout: no live Cloudflare changes, no plaintext secrets, and no required 1Password session.

## Scope

- One feature at a time.
- Stay in scope for the selected `feature_list.json` item.
- Keep Cloudflare work here and Proxmox/homelab network work in the proxmox repo.
- For multi-agent Cloudflare work, follow `docs/multi-agent-cloudflare-contract.md`: Codex plans and approves, Composer reviews/implements, and DeepSeek verifies before handoff back to Codex.
- A narrow supporting fix is allowed only when it is required for verification or restartability.
- Do not silently change verification rules to make a feature look done.

## Definition of Done

A feature is done only when:

- Target behavior is implemented.
- Required verification ran successfully.
- Evidence includes the command, result, and date in `feature_list.json` or `claude-progress.md`.
- `./init.sh` succeeds from the repo root.
- `session-handoff.md` leaves a clean restart path if work is still in progress.

## End of Session

Before ending work:

1. Update `claude-progress.md` with Last Updated, Current State, Current Objective, Verification Evidence, and Recommended Next Step.
2. Update `feature_list.json` status, evidence, and nextStep for touched features.
3. Update `session-handoff.md` with files touched, blockers, risks, and next session command.
4. Leave the repo restartable and record any dirty worktree state.

## Secrets

Follow `agent-contract-master/docs/secrets-baseline.md`.

- Use 1Password references through `op` or `op run`; never commit plaintext secrets.
- Never paste token values into prompts, markdown, logs, or validation output.
- If an item or field is missing, report the `op://` path only.

## Do Not

- Commit API tokens, tunnel secrets, `.env`, or local `*.tfvars` files.
- Run `terraform apply` unless the user explicitly asks for live infrastructure changes.
- Edit tracked Terraform plan artifacts as part of harness work.
