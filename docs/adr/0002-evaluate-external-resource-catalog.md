---
status: accepted
---

# Evaluate a resource catalog through an optional adapter

Accepted on 2026-10-12 for evaluation only. Brian authorized validating the GatherMate2 provider rather than expanding Couchside's five-name experimental catalog into a maintained game database. Use its category/name lookup through the existing read-only optional adapter. Keep discovery, symbol policy and controller presentation in Couchside. Permanent dependency adoption, automatic use in the display and full locale/mining coverage remain pending.

Use the maintainer's unchanged `1.52.3-8-g26d58dd` alpha package, revision `26d58dde107e8340fcdc3c89796d9c0822c64de2`, for the Forever test. The stable `1.52.3` archive predates the relevant Forever support and Vanilla translations. No provider source or catalog is vendored in this repository. Record the package fingerprint, local replay results and Brian's native results separately. The full provider was installed for evaluation and subsequently withdrawn; no hard or optional TOC dependency has been added to Couchside.

GatherMate catalog IDs are provider-specific category keys, not Blizzard entity IDs. A name match remains a resource candidate; missing providers, errors and collisions must preserve unknown or ambiguous results. Provider history is not evidence of currently spawned nodes. Ace3 supplies infrastructure rather than the missing catalog. HereBeDragons addresses projection, not native pin identity. Licensing notices conflict, so copying the provider catalog is not part of this decision.

The accepted decision is the evaluation boundary, not a claim of compatibility. See the [test and handoff record](../research/gathering-provider-validation.md), [library research](../research/gathering-classifier-libraries.md) and [human-readable test page](../gathering-provider-validation.html).

## Validation evidence boundary

Brian confirmed the tested controls worked after the provider evaluation and reloaded; fresh scans and provider state were observed on disk. That confirms the reported input outcome, not the exact native classifications, because the original report was console-only. Version 0.10.0 therefore records explicit library results in a separate bounded history in the existing SavedVariables file. Raw scan evidence remains unchanged. Permanent adoption still awaits that native result. Do not substitute isolated replay output for an observed client response.

## Runtime gate failed and evaluation package withdrawn

On 2026-10-12, the saved error log attributed protected gamepad calls to GatherMate2 during quest-detail/world-map controller navigation. Brian confirmed those errors break controller input. The full-addon package is unsuitable for adoption in the tested setup, regardless of successful name lookups or the earlier basic control check. It was moved intact outside AddOns, preserving provider data and the error baseline. A reload and provider-out comparison were required to assess recovery. The reported comparison passed as recorded below; the original taint source remains unproven.

The accepted evaluation boundary remains: external lookup must not compromise the controller experience. Do not reinstall or make this full addon a required dependency to finish the catalog test. A future data-provider approach needs its own native evaluation, including the controller map paths that failed here. See the [error audit](../bugsack-audit-2026-10-12.html) and [withdrawal evidence](../research/gathering-provider-withdrawal-2026-10-12.json).

## Recovery outcome

Brian reported no problems after withdrawal. The refreshed BugGrabber database, session 56 at 22:02 local time, contains the same eight historical entries with unchanged counts, sessions and timestamps. No new errors were saved. This supports a GatherMate2-dependent failure or interaction in the tested setup; the original taint source remains unproven. The full-addon trial is closed and rejected for adoption, with provider-out recovery confirmed for the reported comparison. Preserve this result when considering another catalog source. See the [recovery evidence](../research/gathering-provider-recovery-2026-10-12.json).

## Offline source investigation

Following Brian's suggestions, source inspection identified wow.export as a candidate for a bounded client-table export outside WoW. Public schema definitions include the installed Forever build, but the needed rows and herb/mining category coverage remain unverified. This records the next feasibility experiment, not adoption of an extracted catalog. No extraction tool or new runtime dependency was installed. Preserve name ambiguity, provenance and native validation requirements if the experiment succeeds. See the [client-file source notes](../research/client-file-catalog-tools.md).

Brian authorized the subsequent offline extraction. GameObjects parsed completely but lacked every checked herb/ore name, so it is unsuitable for that catalog need. LockType confirmed harvesting labels, while Creature/Lock could not be decrypted with the pinned public keys. Cached object names are partial historical evidence; inferred fields and the lock join remain unverified. No catalog was adopted or native behavior changed. The data-only evaluation boundary remains accepted; a usable complete source is unresolved. See the [export outcome](../research/client-table-export-2026-10-12.md).

The October 13 [Wago evaluation](../research/wago-table-followup-2026-10-13.md) recovered exact-build public CSV exports for the missing tables. It supports a provisional cache-to-lock cross-check for four herbs and three unrelated containers, while complete catalog coverage, mining and exact cache schema remain unresolved. This is evidence within the existing offline evaluation boundary, not approval to import cache history as a complete catalog or to change installed behavior. Preserve the original failed-local-decryption record alongside this new access result.

## Replacement by a curated static catalog

On 2026-10-14 Brian requested a local static list after encountering uncatalogued Purple Lotus, and issue #9 called for retiring the duplicate seeds and withdrawn adapter. The 0.15.0 candidate uses one curated Classic English catalog for both display and diagnostics, without an external addon or copied provider dataset. It retires the library command, adapter, provider-report history and standalone package check; trial/recovery evidence remains in these records. Native-unconfirmed names stay explicit, and unsupported labels remain unknown rather than borrowing a known type's stamp. See the [catalog scope](../research/gathering-static-catalog-2026-10-14.md).
