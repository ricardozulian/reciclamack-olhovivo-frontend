# Totem Build Handoff

## Purpose

Use this handoff when work resumes on the dedicated totem build.

The current Astro release uses `APP_MODE=web`. The expanded totem work in the
local frontend worktree is not part of that release.

## Important source state

The frontend worktree contains uncommitted totem changes. Treat these files as
user work. Do not discard, replace, or include them in another release without
review.

Run this command before work starts:

```powershell
git status --short
```

The main uncommitted work includes these areas:

- the dedicated `TotemPage` route;
- the browser camera adapter;
- the square camera crop;
- the two-panel result flow;
- the result timers and reset sequence;
- the related widget tests.

Inspect the current status for the complete file list. The list can change
after this handoff date.

## Shared stale-image defect

An Astro web test showed the prior image with current detection boxes. The API
stored the correct new image and returned the correct new detections.

Flutter Web reused the prior HTML image element. The overlay then painted the
new boxes on that old element.

Frontend commit `75e115c134f3498b2e29d7cb7918ba32189bda18` fixes this defect. The
`AnnotatedImage` widget now uses `ObjectKey(bytes)` for its image widget.

The totem result screen also uses `AnnotatedImage`. Keep this fix in every
future totem build.

Each camera capture currently returns a new `Uint8List`. This makes the object
key change for each accepted capture.

## Related release evidence

| Item | Value |
|---|---|
| Fix commit | `75e115c134f3498b2e29d7cb7918ba32189bda18` |
| Focused widget tests | Three passed |
| Astro verification release | `20260828T144717Z-52454658` |
| Release mode | `web` |
| Model change | None |

The Astro release proves the web fix and the shared widget artifact. It does
not approve the dedicated totem build.

## Required next work

1. Review all uncommitted totem files before an edit.
2. Preserve the centered square crop for the preview and submitted JPEG.
3. Preserve centered letterbox preprocessing in the backend.
4. Keep the stale-image regression test.
5. Add a totem test for two accepted items in consecutive scan cycles.
6. Confirm that the second result uses the second captured bytes.
7. Confirm that the second boxes match the second result.
8. Run all Flutter tests.
9. Build with `APP_MODE=totem`.
10. Test the build in Chromium with the intended USB camera.
11. Commit the reviewed totem source as a focused change.
12. Build the laptop release only from clean Git sources.

## Minimum browser regression

1. Start the totem.
2. Present item A.
3. Wait for the actionable result.
4. Record the image and dominant class.
5. Complete the removal step.
6. Clear the camera area for two probes.
7. Present a visibly different item B.
8. Wait for the second actionable result.
9. Confirm that the result shows item B.
10. Confirm that all boxes belong to item B.
11. Repeat the test for at least ten A-to-B cycles.

Reject the build if any cycle shows an earlier image with current boxes.

## Release references

Use these documents for the complete release procedure:

- `../../deploy/laptop/TOTEM_TEST_PLAN.md`
- `../../deploy/laptop/INSTALLATION.md`
- `README.md`

Keep the Docker shipment architecture. Stop and ask the user before any
architecture, deployment, or approved plan change.
