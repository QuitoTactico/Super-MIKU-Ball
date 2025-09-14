using UnityEngine;

public class CheckpointRotator : MonoBehaviour
{
    void Update()
    {
        transform.Rotate (new Vector3 (0, 30, 0) * Time.deltaTime);
    }
}
