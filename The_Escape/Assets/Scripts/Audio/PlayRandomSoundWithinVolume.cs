using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Plays a random sound at a random location within a box volume
// The audio source you drag in should already be configured for 3D spatial sound

// Written by Mike Yeates for FIT3169

[RequireComponent(typeof(BoxCollider))]
public class PlayRandomSoundWithinVolume : MonoBehaviour
{
    [Tooltip("Drag in one or more audio clips")]
    public AudioClip[] sounds;

    [Tooltip("Sounds will play from this audio source. Each time a sound plays, this audio source will move to a random position within the box collider")]
    public AudioSource audioSourceToUse;

    [Header("Timer")]
    [Tooltip("Minimum time in seconds before next sound is played")]
    public float minSleepSeconds;
    [Tooltip("Maximum time in seconds before next sound is played")]
    public float maxSleepSeconds;

    private BoxCollider boxCollider; // Axis-alligned with world only
    private float timeUntilNextPlay;

    void Start()
    {
        boxCollider = GetComponent<BoxCollider>();

        timeUntilNextPlay = Random.Range(minSleepSeconds, maxSleepSeconds);

        audioSourceToUse.loop = false;
    }

    void Update()
    {
        timeUntilNextPlay -= Time.deltaTime;

        if(timeUntilNextPlay <= 0.0f)
        {
            AudioClip soundToPlay = GetRandomAudioClip();
            Vector3 location = GetRandomPositionWithinBounds(boxCollider.bounds);

            if(soundToPlay != null)
            {
                audioSourceToUse.clip = soundToPlay;
                audioSourceToUse.transform.position = location; // Move audio source to chosen location
                audioSourceToUse.Play();
            }

            timeUntilNextPlay = Random.Range(minSleepSeconds, maxSleepSeconds);
        }
    }

    private AudioClip GetRandomAudioClip()
    {
        return sounds[Random.Range(0, sounds.Length)];
    }

    private Vector3 GetRandomPositionWithinBounds(Bounds bounds)
    {
        return new Vector3(Random.Range(bounds.min.x, bounds.max.x),
                           Random.Range(bounds.min.y, bounds.max.y),
                           Random.Range(bounds.min.z, bounds.max.z));
    }
}
