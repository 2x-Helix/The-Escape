using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Simple quit key functionality for FIT3169 (for builds only)

public class QuitKey : MonoBehaviour
{
    public KeyCode quitKey;

    void Update()
    {
        if (Input.GetKeyDown(quitKey))
        {

            Application.Quit();
        }
    }
}
