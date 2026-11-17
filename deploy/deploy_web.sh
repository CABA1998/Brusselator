#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Deploy the interactive simulations (web/) to https://brusselator.carlosb.dev
#
# The simulations are a static site, so "deploying" is just copying files:
#   web/  ──aws s3 sync──►  s3://caba-curriculum-vitae/brusselator/
# They live in the SAME bucket and CloudFront distribution as carlosb.dev, under
# their own prefix. The curriculum's deploy.ps1 never touches brusselator/ because
# its `--delete` only applies to the folders it explicitly --include's.
#
# The subdomain brusselator.carlosb.dev is mapped to that prefix by a CloudFront
# Function (see deploy/cloudfront/carlosb-host-rewrite.js and deploy/README.md).
# Without it, the site is still reachable at https://carlosb.dev/brusselator/index.html
#
# Usage (from WSL or Git Bash, after `aws sso login --profile portfolio-deploy`):
#   deploy/deploy_web.sh --dry-run   # show what would change
#   deploy/deploy_web.sh             # upload + invalidate /brusselator/*
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROFILE="${BRUSSELATOR_DEPLOY_PROFILE:-portfolio-deploy}"
BUCKET="s3://caba-curriculum-vitae"
PREFIX="brusselator"
DISTRIBUTION_ID="E2DV1F1KKLSNTM"

DRYRUN=()
if [[ "${1:-}" == "--dry-run" ]]; then
  DRYRUN=(--dryrun)
fi

# Resolve web/ relative to this script, so it works from any cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/web"

# --delete removes files that no longer exist locally, but ONLY inside brusselator/.
aws s3 sync "$SRC" "$BUCKET/$PREFIX" \
  --delete \
  --exclude "*.md" \
  --cache-control "public, max-age=300" \
  --profile "$PROFILE" \
  "${DRYRUN[@]}"

if [[ ${#DRYRUN[@]} -eq 0 ]]; then
  # Tell CloudFront to drop its cached copies of the simulations (and only those).
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/$PREFIX/*" \
    --profile "$PROFILE" \
    --query 'Invalidation.{Id:Id,Status:Status}' --output text
  echo "Deployed: https://carlosb.dev/$PREFIX/index.html (and https://brusselator.carlosb.dev/ once the CloudFront Function is updated)"
fi
