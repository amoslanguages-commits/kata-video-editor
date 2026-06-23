# 29B-10 Full Multitrack Behavior QA

## Required Test Project

Create a test project with:

- V1 Main video
- V2 B-roll video
- V3 Overlay image/sticker
- V4 Text title
- V5 Adjustment placeholder
- A1 Voice
- A2 Music
- A3 SFX

Add at least:

- 2 overlapping video clips
- 1 image overlay
- 1 text clip
- 1 voice clip
- 1 music clip
- 2 short SFX clips
- 1 video clip with embedded audio

---

## 1. Track Controls

### Mute

- [ ] Muting V2 hides V2 in export graph enabled visual tracks.
- [ ] Muting V2 makes Android visual probe exclude V2 layers.
- [ ] Muting A2 excludes A2 from activeAudioTrackIds.
- [ ] Muting A2 makes audio probe exclude A2 clips.

### Solo

- [ ] Solo A1 makes activeAudioTrackIds contain only A1.
- [ ] Solo A2 makes activeAudioTrackIds contain only A2.
- [ ] Solo A1 + A2 makes activeAudioTrackIds contain A1 and A2 only.
- [ ] No solo restores normal unmuted audio tracks.

### Hide

- [ ] Hiding V3 excludes V3 from enabledVisualTrackIdsBottomToTop.
- [ ] Android visual probe excludes V3 layers.
- [ ] Hidden track is still serialized in tracks list.
- [ ] Hidden track can be unhidden and restored.

### Lock

- [ ] Locking V1 does not remove V1 from RenderGraph.
- [ ] Locking V1 does not prevent export rendering.
- [ ] Locking V1 blocks moving clips.
- [ ] Locking V1 blocks trimming clips.
- [ ] Locking V1 blocks deleting clips.
- [ ] Unlocking V1 restores editing.

---

## 2. Clip Interactions

### Selection

- [ ] Tap V1 clip selects it.
- [ ] Inspector updates to V1 clip.
- [ ] Tap text clip selects it.
- [ ] Inspector updates to text controls.

### Move

- [ ] Move clip right.
- [ ] DB updates timelineStartMicros/timelineEndMicros.
- [ ] RenderGraph updates clip timing.
- [ ] Android visual probe shows clip at new timing.

### Trim

- [ ] Trim left.
- [ ] sourceStartMicros changes.
- [ ] timelineStartMicros changes.
- [ ] RenderGraph updates.
- [ ] Export respects source trim.

- [ ] Trim right.
- [ ] sourceEndMicros changes.
- [ ] timelineEndMicros changes.
- [ ] RenderGraph updates.
- [ ] Export respects end trim.

### Split

- [ ] Split clip at playhead.
- [ ] Left clip ends at playhead.
- [ ] Right clip starts at playhead.
- [ ] Source split is correct.
- [ ] RenderGraph contains both clips.

### Duplicate

- [ ] Duplicate clip.
- [ ] New clip appears after original.
- [ ] New clip keeps transform/audio/color fields.
- [ ] RenderGraph contains duplicated clip.

### Delete

- [ ] Delete clip.
- [ ] Clip disappears from timeline.
- [ ] Clip disappears from RenderGraph.
- [ ] Asset is not deleted.

---

## 3. Snapping

- [ ] Clip start snaps to playhead.
- [ ] Clip end snaps to playhead.
- [ ] Clip start snaps to another clip end.
- [ ] Clip end snaps to another clip start.
- [ ] Trim left snaps to clip edge.
- [ ] Trim right snaps to playhead.
- [ ] Magnetic guide appears.
- [ ] Magnetic guide disappears.
- [ ] Snapping still works after zooming in.
- [ ] Snapping still works after zooming out.

---

## 4. Zoom + Virtualization

- [ ] Zoom in around playhead.
- [ ] Zoom out around playhead.
- [ ] Pinch zoom around finger.
- [ ] Timeline does not jump badly.
- [ ] 100+ clips scroll smoothly.
- [ ] Offscreen clips are not built.
- [ ] Selected clip remains selected after scrolling.
