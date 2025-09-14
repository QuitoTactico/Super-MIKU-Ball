using UnityEngine;

public class HorizontalRotator : MonoBehaviour
{
    void Update()
    {
        transform.Rotate (new Vector3 (0, 30, 0) * Time.deltaTime);
    }
}
