using UnityEngine;

public class PlayerSparks : MonoBehaviour
{
    [Header("Reference")]
    public Transform miku; // miku model transform

    [Header("Settings")]
    public float distanceBehind = 0.6f; // distance behind miku

    void Start()
    {
        // detach from parent to avoid inheriting rotations
        transform.SetParent(null);
    }

    void LateUpdate()
    {
        if (miku == null) return;

        // get the velocity direction of the player to position sparks behind
        Rigidbody playerRb = miku.GetComponentInParent<Rigidbody>();
        
        if (playerRb != null && playerRb.linearVelocity.sqrMagnitude > 0.01f)
        {
            // position sparks behind the movement direction
            Vector3 movementDirection = playerRb.linearVelocity.normalized;
            transform.position = miku.position - movementDirection * distanceBehind;
        }
        else
        {
            // if not moving, keep at last position or use world back
            transform.position = miku.position + Vector3.back * distanceBehind;
        }

        // keep rotation fixed in world space (identity = no rotation)
        //transform.rotation = Quaternion.identity;
    }
}
