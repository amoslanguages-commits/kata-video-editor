# 29B-4 Snapping QA

## Snap Targets

- [ ] Clip can snap to timeline zero.
- [ ] Clip start can snap to playhead.
- [ ] Clip end can snap to playhead.
- [ ] Clip start can snap to another clip start.
- [ ] Clip start can snap to another clip end.
- [ ] Clip end can snap to another clip start.
- [ ] Clip end can snap to another clip end.
- [ ] Marker snap provider exists even before marker DB is added.

## Move

- [ ] Dragging clip body shows guide line near snap target.
- [ ] Dropping clip near snap target writes snapped time to DB.
- [ ] Moving clip far away does not snap.
- [ ] Moving clip cannot cross before timeline zero.

## Trim Left

- [ ] Left trim handle snaps to playhead.
- [ ] Left trim handle snaps to clip edge.
- [ ] Left trim handle snaps to timeline zero.
- [ ] Left trim still respects minimum clip duration.

## Trim Right

- [ ] Right trim handle snaps to playhead.
- [ ] Right trim handle snaps to clip edge.
- [ ] Right trim still respects minimum clip duration.

## UI

- [ ] Magnetic guide appears during drag.
- [ ] Magnetic guide disappears after drag.
- [ ] Snap toggle disables snapping.
- [ ] Snap toggle enables snapping again.
- [ ] Haptic feedback fires once per snap target.

## Zoom Behavior

- [ ] Snapping feels tight when zoomed in.
- [ ] Snapping feels natural when zoomed out.
- [ ] Snap threshold is pixel-based, not fixed time-based.
