using UnityEngine;

[RequireComponent(typeof(HorizontalRotator))]
public class Checkpoint : MonoBehaviour
{
    private static Checkpoint currentActive;
    private HorizontalRotator checkpointRotator;

    private void Awake()
    {
        checkpointRotator = GetComponent<HorizontalRotator>();
        if (checkpointRotator) checkpointRotator.enabled = false;
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            if (other.TryGetComponent<PlayerController>(out var player))
            {
                player.SetCheckpoint(this);
            }
        }
    }

    public void ActivateThisCheckpoint()
    {
        if (currentActive != null && currentActive.checkpointRotator != null)
        {
            currentActive.checkpointRotator.enabled = false;
        }

        if (checkpointRotator != null)
        {
            checkpointRotator.enabled = true;
        }

        currentActive = this;
    }
}