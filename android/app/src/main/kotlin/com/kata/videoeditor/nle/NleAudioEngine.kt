package com.kata.videoeditor.nle

/**
 * Native audio engine for one project session.
 *
 * Composes:
 *  - [NlePlaybackClock]   — frame-accurate tick source (~60 fps via HandlerThread)
 *  - [NleSilentAudioSink] — AudioTrack output (silent in V1; decoded PCM in Step 17+)
 *
 * Play / pause / seek are forwarded to the clock; the sink mirrors the play state.
 * The [onPlayheadTick] callback is invoked on the clock's HandlerThread.
 */
class NleAudioEngine(
    durationMicros: Long,
    private val onPlayheadTick: (playheadMicros: Long, isPlaying: Boolean) -> Unit,
    private val onPlaybackEnded: () -> Unit = {}
) {
    private val sink = NleSilentAudioSink()

    private val clock = NlePlaybackClock(
        durationMicros = durationMicros,
        onTick = { micros, playing -> onPlayheadTick(micros, playing) },
        onEnded = {
            sink.pause()
            onPlaybackEnded()
        }
    )

    // ── State ─────────────────────────────────────────────────────────────────

    val playheadMicros: Long   get() = clock.currentPlayheadMicros
    val isPlaying: Boolean     get() = clock.currentIsPlaying
    val isSinkReady: Boolean   get() = sink.isInitialized

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    /**
     * Initialises the audio sink.
     *
     * @return `true` on success, `false` if [AudioTrack] creation failed.
     */
    fun initialize(): Boolean = sink.initialize()

    fun play() {
        sink.play()
        clock.play()
    }

    fun pause() {
        clock.pause()
        sink.pause()
    }

    fun seek(positionMicros: Long) {
        clock.seek(positionMicros)
    }

    fun setRate(rate: Float) {
        clock.setRate(rate)
    }

    fun setDuration(micros: Long) {
        clock.setDuration(micros)
    }

    fun release() {
        clock.release()
        sink.release()
    }

    // ── Serialisation ─────────────────────────────────────────────────────────

    fun toMap(): Map<String, Any?> = mapOf(
        "isPlaying"    to isPlaying,
        "playheadMicros" to playheadMicros,
        "isSinkReady"  to isSinkReady
    )
}
