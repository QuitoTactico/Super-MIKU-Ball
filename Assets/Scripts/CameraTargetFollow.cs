using UnityEngine;

public class CameraTargetFollow : MonoBehaviour
{
    [Header("References")]
    public Transform player; // The rolling ball

    [Header("Settings")]
    public Vector3 offset = new Vector3(0, 1f, 0); // height offset above ball
    public float smoothSpeed = 10f; // optional smoothing for camera follow

    void LateUpdate()
    {
        if (player == null) return;

        // Target position above the ball
        Vector3 targetPos = player.position + offset;

        // Smoothly move the camera target to follow the ball
        transform.position = Vector3.Lerp(transform.position, targetPos, smoothSpeed * Time.deltaTime);

        // Keep the camera target upright (don’t rotate with the ball)
        transform.rotation = Quaternion.identity;
    }
}
