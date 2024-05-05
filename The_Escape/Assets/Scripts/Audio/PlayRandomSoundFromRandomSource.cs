using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Plays a random sound from a random audio source based on a timer
// The audio sources you drag in should already be configured for 3D spatial sound

// Written by Mike Yeates for FIT3169

public class PlayRandomSoundFromRandomSource : MonoBehaviour
{
    [Tooltip("Drag in one or more audio clips")]
    public AudioClip[] sounds;

    [Tooltip("Drag in one or more audio sources")]
    public AudioSource[] audioSources;

    [Header("Timer")]
    [Tooltip("Minimum time in seconds before next sound is played")]
    public float minSleepSeconds; 
    [Tooltip("Maximum time in seconds before next sound is played")]
    public float maxSleepSeconds;

    private float timeUntilNextPlay;

    void Start()
    {
        timeUntilNextPlay = Random.Range(minSleepSeconds, maxSleepSeconds);

        // Ensure audio sources are not set to loop
        for(int i = 0; i < audioSources.Length; i++)
        {
            if(audioSources[i] != null)
            {
                audioSources[i].loop = false;
            }
        }
    }

    void Update()
    {
        timeUntilNextPlay -= Time.deltaTime;

        if(timeUntilNextPlay <= 0.0f)
        {
            AudioClip soundToPlay = GetRandomAudioClip();
            AudioSource source = GetRandomAudioSource();

            if(soundToPlay != null && source != null)
            {
                source.clip = soundToPlay;
                source.Play();
            }

            timeUntilNextPlay = Random.Range(minSleepSeconds, maxSleepSeconds);
        }
    }

    private AudioClip GetRandomAudioClip()
    {
        return sounds[Random.Range(0, sounds.Length)];
    }

    private AudioSource GetRandomAudioSource()
    {
        return audioSources[Random.Range(0, audioSources.Length)];
    }
}
