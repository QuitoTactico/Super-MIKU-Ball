using UnityEngine;

public class Scaler : MonoBehaviour
{
    [Header("Scaling Settings")]
    public float baseScale = 1f;       // The normal (center) scale
    public float amplitude = 0.2f;     // How much it scales up/down from base
    public float frequency = 1f;       // How many cycles per second

    private Vector3 initialScale;

    void Start()
    {
        // Store the object's original scale
        initialScale = transform.localScale;
    }

    void Update()
    {
        // Calculate a scale factor that oscillates with time
        float scaleFactor = baseScale + Mathf.Sin(Time.time * frequency * 2f * Mathf.PI) * amplitude;

        // Apply the scaling (uniformly in all directions)
        transform.localScale = initialScale * scaleFactor;
    }
}
