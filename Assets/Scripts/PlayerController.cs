using UnityEngine;
using UnityEngine.InputSystem;
using TMPro;

public class PlayerController : MonoBehaviour
{
    public TextMeshProUGUI scoreText;
    public GameObject winTextObject;
    public float speed = 0;
    public int lives = 3;

    private Rigidbody rb;
    private Vector3 initialSpawnPos;
    private Transform activeCheckpoint;
    private int score;
    private float movementX;
    private float movementY;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        score = 0;
        SetScoreText();
        winTextObject.SetActive(false);
        initialSpawnPos = transform.position;
    }

    void OnMove(InputValue movementValue)
    {
        Vector2 movementVector = movementValue.Get<Vector2>();

        movementX = movementVector.x;
        movementY = movementVector.y;
    }

    void SetScoreText()
    {
        scoreText.text = $"Score: {score}";
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
            // get points from the pickup object
            if (other.TryGetComponent<PickUp>(out var pickUp))
            {
                score += pickUp.points;
            }
            
            other.gameObject.SetActive(false);
            SetScoreText();
        }
        
        if (other.gameObject.CompareTag("Goal"))
        {
            // if you reach the goal, you win the game!
            winTextObject.SetActive(true);
            winTextObject.GetComponent<TextMeshProUGUI>().text = "You Won!";
            Destroy(GameObject.FindGameObjectWithTag("Enemy"));
        }
        
        // player dies when touching limit/border
        if (other.gameObject.CompareTag("Limit"))
        {
            Die();
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

    private void Die()
    {
        if (lives > 0)
        {
            Respawn();
        }
        else
        {
            GameOver();
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Enemy"))
        {
            Die();
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
