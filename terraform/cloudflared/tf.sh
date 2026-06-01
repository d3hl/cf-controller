#!/bin/bash
set -euo pipefail

export TF_VAR_SERVICE_ACCOUNT_TOKEN="$(op read op://d3HLPRV/iu2lj435cprjpf3ddpjnfuyqni/Token)"
export CLOUDFLARE_API_TOKEN="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/credential')"
export TF_VAR_account_id="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/Account ID')"
export TF_VAR_zone_id="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/Zone ID')"

terraform "${@:-plan}"
