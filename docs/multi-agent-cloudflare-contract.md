# Multi-Agent Contract: Cloudflare Terraform

This contract defines how Codex, Composer, and DeepSeek collaborate on Cloudflare work in `cf-controller`. It is scoped to Cloudflare/controller automation and Terraform under `terraform/cloudflared`.

## Source of Truth

- `AGENTS.md`
- `feature_list.json`
- `claude-progress.md`
- `session-handoff.md`
- `terraform/cloudflared/main.tf`
- `terraform/cloudflared/variables.tf`
- `terraform/cloudflared/tf.sh`

Cloudflare Terraform provider documentation was checked through Context7 for provider-v5 workflow boundaries. Keep static checks separate from credentialed plan/apply work.

## Agent Roles

### Codex

Codex owns planning, design, and input configuration.

Codex owns:

- Cloudflare task brief, target behavior, and acceptance criteria.
- Terraform resource intent and required input variables.
- Safety gates, rollback expectations, and final approval.
- Final updates to harness state after Composer and DeepSeek evidence is reviewed.

Codex must not:

- Run `terraform apply` without explicit user approval.
- Approve live changes before Composer review and DeepSeek verification evidence are available.
- Put plaintext Cloudflare or 1Password secrets in docs, prompts, logs, or Terraform files.

### Composer

Composer owns validation, debate, configuration review, and implementation.

Composer owns:

- Reviewing Codex's proposed Cloudflare/Terraform design for correctness and provider-v5 compatibility.
- Debating configuration risks before implementation.
- Implementing approved Terraform/configuration changes in `terraform/cloudflared`.
- Reporting drift, provider issues, and credential-handling risks before handoff.

Composer must not:

- Implement changes without an explicit Codex design or task brief.
- Modify Proxmox, FortiGate, Cisco, or non-Cloudflare repos as part of this contract.
- Run `terraform apply` without Codex final approval and explicit user approval.
- Commit plaintext secrets, local `*.tfvars`, `.env`, Terraform state, or plan artifacts.

### DeepSeek

DeepSeek owns testing, verification, and handoff back to Codex.

DeepSeek owns:

- Static verification with `./init.sh`.
- Terraform checks: `fmt -check -diff`, `init -backend=false -input=false`, and `validate`.
- Credentialed `terraform/cloudflared/tf.sh plan` only when credentials are available and the active task requires live planning.
- Pass/fail evidence, drift notes, and risk findings for Codex final approval.

DeepSeek must not:

- Run `terraform apply`.
- Change Terraform configuration while acting as the verification owner.
- Continue after verification failure without recording the failed command, observed state, and recommended owner for the fix.

## Workflow

### Phase 1: Codex Plan and Inputs

Codex prepares:

- Desired Cloudflare behavior.
- Target Terraform resources and inputs.
- Expected verification commands.
- Rollback and no-go conditions.

### Phase 2: Composer Review and Implementation

Composer reviews the design, raises configuration objections, then implements only approved Cloudflare/Terraform changes.

Composer output must include:

- Files changed.
- Configuration rationale.
- Any provider-v5 compatibility notes.
- Risks requiring DeepSeek verification.

### Phase 3: DeepSeek Verification

DeepSeek runs:

```bash
cd /home/d3/Github/cf-controller
./init.sh
terraform -chdir=terraform/cloudflared fmt -check -diff
terraform -chdir=terraform/cloudflared init -backend=false -input=false
terraform -chdir=terraform/cloudflared validate
```

DeepSeek may run a live plan only when requested and credentials are available:

```bash
cd /home/d3/Github/cf-controller/terraform/cloudflared
./tf.sh plan
```

### Phase 4: Codex Final Approval

Codex reviews Composer and DeepSeek evidence, then records:

- Final approval or rejection.
- Required follow-up changes.
- Verification evidence in `feature_list.json` or `claude-progress.md`.
- Restart state in `session-handoff.md`.

## Handoff Format

Each handoff should include:

```text
Agent:
Phase:
Cloudflare task:
Files used:
Credential source:
Design or implementation summary:
Commands executed:
Validation result:
Drift or provider findings:
Blocked items:
Rollback notes:
Next owner:
```

## Completion Criteria

A Cloudflare multi-agent task is complete only when:

- Codex design and acceptance criteria are explicit.
- Composer has reviewed or implemented the approved Terraform/configuration change.
- DeepSeek verification evidence is recorded.
- Codex has completed final approval.
- No plaintext secrets, local `*.tfvars`, state files, or plan artifacts are committed as part of the task.
