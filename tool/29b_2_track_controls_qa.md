# 29B-2 Track Controls QA

## Database

- [ ] Tapping M updates Tracks.isMuted.
- [ ] Tapping S updates Tracks.isSolo.
- [ ] Tapping lock updates Tracks.isLocked.
- [ ] Tapping hide updates Tracks.isHidden.
- [ ] Rename updates Tracks.name.
- [ ] Taller increases Tracks.height.
- [ ] Shorter decreases Tracks.height.
- [ ] Reset restores default height.
- [ ] Track modifications are persisted in Drift SQLite DB.

## UI

- [ ] Muted track button becomes active.
- [ ] Solo track button becomes active.
- [ ] Locked track icon changes.
- [ ] Hidden track icon changes.
- [ ] Track lane dims when hidden/muted.
- [ ] Track name updates instantly after rename.
- [ ] Track height changes instantly.
- [ ] Timeline does not need app restart to show changes.

## Project Behavior

- [ ] Existing projects load controls correctly.
- [ ] New projects get default V1-V5 and A1-A3 tracks.
- [ ] Empty project still shows track controls.
- [ ] No clip interaction is broken.

## RenderGraph Hook

- [ ] trackGraphRefreshBridge invalidates timeline providers.
- [ ] Native graph refresh hook can be wired in 29B-7.
