using UnityEngine;

public class PlayerSparks : MonoBehaviour
{
    [Header("Reference")]
    public Transform miku; // miku model transform

    void LateUpdate()
    {
        if (miku == null) return;

        // use the inverse of the miku rotation instead of unary minus
        transform.rotation = Quaternion.Inverse(miku.rotation);
    }
}
