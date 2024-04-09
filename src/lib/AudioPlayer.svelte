<script>
    export let audioUrl = '';

    let audioRef;

    $: if (audioRef && audioUrl) {
        audioRef.src = audioUrl;
        // Optionally, load the audio or handle errors
        audioRef.load();
    }

    function togglePlay() {
        if (audioRef && audioRef.paused) {
            audioRef.play();
        } else if (audioRef) {
            audioRef.pause();
            audioRef.currentTime = 0;
        }
    }
</script>

<!-- Adjusted layout to include reactive audio source -->
<div>
    <button on:click={togglePlay}><span class="playbutton">▶ Play</span></button>
    | <span class="downloadbutton"><a href="{audioUrl}" download="response.mp3">⇓ Download</a></span> (unavailable after refresh!)
    <audio bind:this={audioRef} style="display: none;"></audio>
</div>

  

<style>
.playbutton, .downloadbutton {
    color: lightblue;
}
.playbutton:hover, .downloadbutton:hover {
    color: lightblue;
    text-decoration: underline;
}

</style>