-----

<!-- Adapted from Homebrew/homebrew-core's PR template for this OHOS tap.
     Do not tick a checkbox if you haven't performed its action. -->

- [ ] Commit messages follow this tap's convention (enforced by `lint-commits`):
      `foo 1.2.3` (version bump) / `foo 1.2.3 (new formula)` /
      `foo: revision bump to ...` / `foo: <fix description>`
- [ ] Built in the OHOS container with `brew install --build-from-source <formula>`
      (or you're relying on this PR's CI build — it publishes the bottle onto
      this branch before merge)
- [ ] `brew test <formula>` passes
- [ ] `brew audit <formula>` passes (`brew audit --new <formula>` for a new formula)
- [ ] Prebuilt-binary formula? Confirmed whether it needs
      `HOMEBREW_OHOS_BOTTLE_BINARY_SIGN` unset (see `build.sh`'s
      `UNSET_SIGN_FORMULAS` + the odie guards in opencode/grok-build)

-----

⚠️ **Merge with a merge commit or rebase — never squash.** Squash merging is
disabled repo-wide after #29: it collapses the content change and CI's bottle
write-back into one commit, which breaks `detect-changes.sh`'s self-trigger
detection and causes a redundant rebuild + duplicate release.

-----

- [ ] AI was used to generate or assist with this PR. *If so, note below how it
      was used and what you manually verified.*
