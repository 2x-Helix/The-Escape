using UnityEngine;
using System.Collections;

// Simple cursor lock functionality for FIT3169

public class MouseLock : MonoBehaviour {

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
}
