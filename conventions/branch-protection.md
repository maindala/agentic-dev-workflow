# Branch protection & CODEOWNERS setup

The [`hooks/ship-gate.sh`](../hooks/ship-gate.sh) hook enforces Gate 2 *inside* an agent session.
It has no power over what happens outside one — a direct `git push --force` to `main`, a PR merged
by someone who never ran the agent at all, or a workflow file edited to remove a check. Repository
settings are what closes that gap, and GitHub Actions and a local hook are complementary, not
substitutes for each other: the hook stops an agent from typing the command; branch protection
stops the command from taking effect even if something else typed it.

This doc is setup guidance, not something this repo can apply for you — GitHub has no config-as-
code for repository rulesets that ships free on every plan, so these are manual steps (or your own
Terraform/`gh api` automation) in your own repo.

## 1. Require the gate-check Action as a required status check

1. Copy [`.github/workflows/gate-check.yml`](../.github/workflows/gate-check.yml) into your repo
   (or reference this repo's action directly:
   `uses: maindala/agentic-dev-workflow/.github/actions/gate-check@<pinned-sha-or-tag>`).
2. Repo **Settings → Branches → Branch protection rules** (or **Rules → Rulesets** on repos that
   have migrated to the newer rulesets UI) → add a rule for `main`.
3. Enable **Require status checks to pass before merging**, and select the `Gate Check /
   traceability-triad` check once it has run at least once (GitHub only lists checks that have
   executed on the repo before).
4. Enable **Require branches to be up to date before merging** so the check runs against the
   actual merge result, not a stale base.

## 2. Require CODEOWNERS review

1. Copy [`templates/CODEOWNERS.example`](../templates/CODEOWNERS.example) to `.github/CODEOWNERS`
   in your repo and replace the placeholder handles.
2. In the same branch protection rule, enable **Require a pull request before merging** →
   **Require review from Code Owners**.
3. Consider **Require approval of the most recent reviewable push** so a late change to an
   already-approved PR (e.g. someone editing the workflow file after review) forces a fresh
   approval.

## 3. Lock down who can bypass the rule

1. In the branch protection rule, leave **Allow specified actors to bypass required pull
   requests** empty unless you have a specific, documented break-glass need.
2. Enable **Do not allow bypassing the above settings** so repository admins are held to the same
   rule as everyone else — an admin bypass is the single most common way a protected-branch policy
   turns out to have had a hole in it the whole time.
3. If your org uses the newer **Rulesets** UI instead of classic branch protection, the equivalent
   is setting **Bypass list** to empty and enforcement to **Active** (not **Evaluate**, which only
   logs what *would* have been blocked).

## 4. Merge-commit identity, not just merge method

Separately from status checks and reviews: decide who is allowed to click merge, and merge from an
account whose commits you're comfortable seeing on `main` forever. GitHub's squash and rebase merge
methods **re-author the resulting commit to the merging account** — this is not a hypothetical: a
personal email address ended up on a public repository's `main` branch this exact way during this
project's own history, purely because the account that clicked merge happened to be a personal one.
If your repo is public and you care about commit-author identity, merge from an org-owned account,
not a personal one, regardless of which merge method you pick.

## What this section does not give you

This is guidance for GitHub's own repository settings — it does not create an audit trail outside
GitHub, does not integrate with any identity provider beyond GitHub's own accounts/teams, and does
not prevent a repo admin with **Do not allow bypassing** left unchecked from disabling the rule
itself before merging. See the README's "What CI enforcement does not cover" section for the full
list of things this workflow — hook, Action, and branch protection together — does not claim to be.
