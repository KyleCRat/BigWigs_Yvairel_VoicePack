# BigWigs_Yvairels_VoicePack — FIXME

## 1. `logAbility` signature inconsistent with LittleWigs variant

**Severity:** Low — maintenance burden when updating both addons in parallel

**Problem:** The BigWigs VoicePack's `logAbility` takes a pre-resolved `played` string directly, while the LittleWigs variant takes `hadFile, hadYFile` booleans and calls `getPlayed()` to derive the string internally. These two sibling addons should use the same function signature.

**Fix:** Align LittleWigs to pass the resolved `played` string (Option A — BigWigs style). No changes needed in this repo.
