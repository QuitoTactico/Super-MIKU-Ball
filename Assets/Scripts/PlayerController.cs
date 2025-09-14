using UnityEngine;
using UnityEngine.InputSystem;
using TMPro;

public class PlayerController : MonoBehaviour
{
    public TextMeshProUGUI countText;
    public GameObject winTextObject;
    public float speed = 0;
    public int lives = 3;

    private Rigidbody rb;
    private Vector3 initialSpawnPos;
    private Transform activeCheckpoint;
    private int count;
    private float movementX;
    private float movementY;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        count = 0;
        SetCountText();
        winTextObject.SetActive(false);
        initialSpawnPos = transform.position;
    }

    void OnMove(InputValue movementValue)
    {
        Vector2 movementVector = movementValue.Get<Vector2>();

        movementX = movementVector.x;
        movementY = movementVector.y;
    }

    void SetCountText()
    {
        int totalPickUps = GameObject.FindGameObjectsWithTag("PickUp").Length + count;
        countText.text = $"Count: {count} / {totalPickUps}";

        if (count >= totalPickUps)
        {
            winTextObject.SetActive(true);
            Destroy(GameObject.FindGameObjectWithTag("Enemy"));
        }
    }

    private void FixedUpdate()
    {
        Vector3 movement = new Vector3(movementX, 0.0f, movementY);
        rb.AddForce(movement * speed);
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("PickUp"))
        {
            other.gameObject.SetActive(false);
            count = count + 1;
            SetCountText();
        }
        
        if (other.gameObject.CompareTag("EnemySpawn"))
        {
            GameObject Enemy = GameObject.Find("Enemy");
            if (Enemy != null)
            {
                Enemy.SetActive(true);
            }
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Enemy"))
        {
            if (lives > 0) // if we have lives left
            {
                Respawn();
            }
            else // u die bro
            {
                GameOver();
            }
        }
    }

    public void SetCheckpoint(Checkpoint checkpoint)
    {
        activeCheckpoint = checkpoint.transform;
        checkpoint.ActivateThisCheckpoint();
    }

    public void Respawn()
    {
        lives--;

        Vector3 respawnPos;

        if (activeCheckpoint != null)
        {
            respawnPos = activeCheckpoint.position + new Vector3(0, 0.5f, 0);
            Debug.Log("Respawning at checkpoint: " + activeCheckpoint.position);
        }
        else
        {
            respawnPos = initialSpawnPos;
            Debug.Log("No active checkpoint, respawning at initial position: " + initialSpawnPos);
        }

        transform.position = respawnPos;
        rb.linearVelocity = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
    }

    private void GameOver()
    {
        winTextObject.gameObject.SetActive(true);
        winTextObject.GetComponent<TextMeshProUGUI>().text = "Game Over!";
        Destroy(gameObject);
    }
}
