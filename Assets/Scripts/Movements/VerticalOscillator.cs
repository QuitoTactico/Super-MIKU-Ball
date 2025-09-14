using UnityEngine;

public class VerticalOscillator : MonoBehaviour
{
    [SerializeField] private float amplitude = 0.3f; // oscillation range (+/-)
    [SerializeField] private float frequency = 5f;   // oscillation speed

    private float initialY;
    private float phaseOffset;

    void Start()
    {
        initialY = transform.position.y;
        phaseOffset = Random.Range(0f, Mathf.PI * 2f); // random start in sine cycle
    }

    void Update()
    {
        float yOffset = Mathf.Sin(Time.time * frequency + phaseOffset) * amplitude;
        Vector3 pos = transform.position;
        pos.y = initialY + yOffset;
        transform.position = pos;
    }
}