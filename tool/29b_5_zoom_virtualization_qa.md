# 29B-5 Zoom + Virtualization QA Checklist

## Goals

This checklist verifies that Step 29B-5 (Timeline Zoom + Virtualization) works
correctly in isolation and does not break any existing 29B-1 through 29B-4
functionality.

---

## 1. Zoom Buttons (Anchored around Playhead)

| Test | Expected | Pass? |
|------|----------|-------|
| Tap **Zoom In** (+) | Timeline zooms in; playhead stays near same screen X position | ☐ |
| Tap **Zoom Out** (−) | Timeline zooms out; playhead stays near same screen X position | ☐ |
| Tap Zoom In repeatedly to max | Zoom level clamps at 360 px/s; px/s pill shows `360 px/s` | ☐ |
| Tap Zoom Out repeatedly to min | Zoom level clamps at 18 px/s; px/s pill shows `18 px/s` | ☐ |
| Zoom while playhead is off-screen left | Scrollbar adjusts to keep focal point stable | ☐ |
| Zoom while playhead is off-screen right | Scrollbar adjusts to keep focal point stable | ☐ |

---

## 2. Pinch Zoom (Anchored around Focal Point)

| Test | Expected | Pass? |
|------|----------|-------|
| Pinch in with two fingers on timeline lanes | Timeline zooms in around finger focal point | ☐ |
| Pinch out with two fingers on timeline lanes | Timeline zooms out around finger focal point | ☐ |
| Quick pinch jitter (scale ≈ 1.0) | No zoom applied (jitter guard < 0.015 scale delta) | ☐ |
| Pinch to max zoom | Clamps; no flutter assertion errors | ☐ |
| Pinch to min zoom | Clamps; no flutter assertion errors | ☐ |
| Release pinch then single-finger scroll | Scroll works normally; no stuck gesture state | ☐ |

---

## 3. Zoom Level Pill

| Test | Expected | Pass? |
|------|----------|-------|
| Default zoom | Pill shows `72 px/s` | ☐ |
| After zoom in | Pill shows updated round value | ☐ |
| After zoom out | Pill shows updated round value | ☐ |

---

## 4. Performance Badge (Virtualization)

| Test | Expected | Pass? |
|------|----------|-------|
| Badge visible in bottom-right of tracks area | Shows `X/Y clips  •  M/N tracks  •  Z px/s` | ☐ |
| 3 tracks, all visible | Badge shows `3/3 tracks` | ☐ |
| 3 tracks, scroll so 1 is off-screen | Badge shows `2/3 tracks` | ☐ |
| 10 clips, 5 visible | Badge shows `5/10 clips` | ☐ |
| Zoom way out so all clips fit | Badge shows totalClips/totalClips | ☐ |

---

## 5. Track Virtualization

| Test | Expected | Pass? |
|------|----------|-------|
| Scroll to top of track list | Only top tracks rendered (bottom off-screen) | ☐ |
| Scroll to bottom of track list | Only bottom tracks rendered (top off-screen) | ☐ |
| Add 10+ tracks | No jank during scroll | ☐ |

---

## 6. Clip Virtualization

| Test | Expected | Pass? |
|------|----------|-------|
| Clips before visible window not rendered | No clip widget built for clips with endMicros < visibleStart | ☐ |
| Clips after visible window not rendered | No clip widget built for clips with startMicros > visibleEnd | ☐ |
| Horizontal scroll reveals new clips | New clips appear seamlessly as they enter the viewport | ☐ |
| Clip at exact left edge of window | Rendered (overscan covers it) | ☐ |
| Clip at exact right edge of window | Rendered (overscan covers it) | ☐ |

---

## 7. Track Headers (Virtualised)

| Test | Expected | Pass? |
|------|----------|-------|
| Headers scroll in sync with lane lanes vertically | Headers stay aligned with their lane rows | ☐ |
| Header vertical scroll does not trigger horizontal scroll | Header scrolls only vertically | ☐ |
| Track height change (resize) | Header and lane stay the same height | ☐ |

---

## 8. Snapping Compatibility (29B-4)

| Test | Expected | Pass? |
|------|----------|-------|
| Move clip near playhead | Cyan snap guide line appears | ☐ |
| Snap to clip edge | Guide line snaps to clip start/end | ☐ |
| Snap to timeline zero | Guide line appears at x=0 | ☐ |
| Disable snapping via toggle | No guide line during drag | ☐ |
| Long press snap toggle | Snap settings sheet appears | ☐ |

---

## 9. Track Controls Compatibility (29B-2)

| Test | Expected | Pass? |
|------|----------|-------|
| Mute a track | Track lane dims; mute icon active | ☐ |
| Solo a track | Other tracks dim | ☐ |
| Lock a track | Lock icon active; clip drag shows toast | ☐ |
| Hide a track | Track lane invisible; clips hidden | ☐ |
| Rename a track | Dialog opens; name updated in header | ☐ |

---

## 10. Clip Interactions Compatibility (29B-3)

| Test | Expected | Pass? |
|------|----------|-------|
| Select clip | Clip border turns white with trim handles | ☐ |
| Move clip left | Clip shifts left after pan ends | ☐ |
| Move clip right | Clip shifts right after pan ends | ☐ |
| Trim left handle | Left edge moves right (shortens clip) | ☐ |
| Trim right handle | Right edge moves right (extends/shortens clip) | ☐ |
| Split clip at playhead | Two clips appear after split | ☐ |
| Duplicate clip | Copy appears offset +0.5s | ☐ |
| Delete clip via context menu | Clip removed; confirm dialog shown | ☐ |

---

## 11. Compact Mode

| Test | Expected | Pass? |
|------|----------|-------|
| Toggle compact tracks | Track height decreases smoothly | ☐ |
| Compact + zoom in | Both modes work simultaneously | ☐ |

---

## 12. Stress Test

| Test | Expected | Pass? |
|------|----------|-------|
| Add 50 clips to V1 track | Timeline scrolls at 60fps | ☐ |
| Add 100 clips across 5 tracks | Performance badge confirms <20 clips visible | ☐ |
| Pinch zoom with 100 clips | No dropped frames, no layout errors | ☐ |
| Rapid horizontal scroll at max zoom | Smooth, no jank | ☐ |

---

## Automated Tests

Run `flutter test test/timeline_virtualization_test.dart` to verify all unit tests pass.

Expected: **0 failures**, **≥ 22 assertions green**.
