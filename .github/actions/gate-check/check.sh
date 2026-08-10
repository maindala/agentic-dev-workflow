#!/usr/bin/env bash
# The actual logic behind the gate-check Action (action.yml in this directory).
#
# What it checks, per conventions/traceability.md: a design doc, a user-stories doc, and a
# QA-test-cases doc share one basename across three parallel directories, and the QA doc
# references at least one story ID defined in the stories doc.
#
# What it deliberately does NOT check (see the README's enforcement-boundary section): that the
# acceptance criteria are complete, that the QA cases were actually executed, that the design is
# good, or anything about content quality. This is presence-and-cross-reference only — a
# structural gate, not a review.
#
# Scope: only slugs touched by this PR are checked (a file added/changed under design-artifacts/,
# story-artifacts/design/, or qa-test-cases/). A PR that touches none of those three directories
# is a no-op pass — this check has nothing to say about it.
set -euo pipefail

base_sha="${1:?usage: check.sh <base-sha> <head-sha>}"
head_sha="${2:?usage: check.sh <base-sha> <head-sha>}"

changed=$(git diff --name-only "$base_sha" "$head_sha" || true)

# ── Collect the set of slugs touched in any of the three traceability directories ──
slugs=$(printf '%s\n' "$changed" \
  | grep -E '^(design-artifacts|story-artifacts/design|qa-test-cases)/[^/]+\.md$' \
  | sed -E 's#^design-artifacts/##; s#^story-artifacts/design/##; s#^qa-test-cases/##; s#\.md$##' \
  | sort -u || true)

if [ -z "$slugs" ]; then
  echo "No design-artifacts/, story-artifacts/design/, or qa-test-cases/ file changed in this PR — nothing to check."
  exit 0
fi

fail=0
while IFS= read -r slug; do
  [ -z "$slug" ] && continue

  design="design-artifacts/${slug}.md"
  story="story-artifacts/design/${slug}.md"
  qa="qa-test-cases/${slug}.md"

  # ── Presence: all three files must exist at the PR's head ──
  missing=""
  [ -f "$design" ] || missing="$missing $design"
  [ -f "$story" ] || missing="$missing $story"
  [ -f "$qa" ] || missing="$missing $qa"

  if [ -n "$missing" ]; then
    echo "::error::Traceability triad incomplete for '$slug' — missing:$missing"
    fail=1
    continue
  fi

  # ── Cross-reference: the story file must declare at least one prefixed story ID (e.g. CES-1),
  #    and the QA file must reference at least one of those same IDs ──
  ids=$(grep -oE '\b[A-Z]{2,5}-[0-9]+\b' "$story" | sort -u || true)
  if [ -z "$ids" ]; then
    echo "::error::Traceability triad for '$slug' — $story declares no story IDs (expected a pattern like CES-1, per conventions/traceability.md)."
    fail=1
    continue
  fi

  covered=""
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    if grep -qF "$id" "$qa"; then
      covered="$id"
      break
    fi
  done <<EOF
$ids
EOF

  if [ -z "$covered" ]; then
    echo "::error::Traceability triad for '$slug' — $qa references none of the story IDs declared in $story (expected e.g. **Covers:** <ID>)."
    fail=1
  fi
done <<EOF
$slugs
EOF

exit $fail
