using UnityEngine;
using UnityEngine.InputSystem;
using TMPro;

public class PlayerController : MonoBehaviour
{
    [Header("UI References")]
    public Canvas uiCanvas;
    public GameStatsDisplay statsDisplay;
    
    [Header("Game Settings")]
    public float speed = 0;
    public int lives = 3;

    private Rigidbody rb;
    private Vector3 initialSpawnPos;
    private Transform activeCheckpoint;
    private int score;
    private int deaths = 0;
    private float gameTime = 0f;
    private float movementX;
    private float movementY;

    // UI Text references (found automatically)
    private TextMeshProUGUI scoreText;
    private TextMeshProUGUI timeText;
    private TextMeshProUGUI deathsText;
    private TextMeshProUGUI livesText;

    // Public accessors for GameStatsDisplay
    public TextMeshProUGUI ScoreText => scoreText;
    public TextMeshProUGUI TimeText => timeText;
    public TextMeshProUGUI DeathsText => deathsText;
    public TextMeshProUGUI LivesText => livesText;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        score = 0;
        
        // Find UI components automatically
        FindUIComponents();
        
        SetScoreText();
        UpdateDeathsText();
        UpdateLivesText();
        initialSpawnPos = transform.position;
    }

    void FindUIComponents()
    {
        if (uiCanvas != null)
        {
            // Find UI text components by name in the canvas
            scoreText = FindTextComponentByName("scoreText");
            timeText = FindTextComponentByName("timeText");
            deathsText = FindTextComponentByName("deathsText");
            livesText = FindTextComponentByName("livesText");
        }
        else
        {
            Debug.LogError("UI Canvas is not assigned!");
        }
    }

    TextMeshProUGUI FindTextComponentByName(string componentName)
    {
        if (uiCanvas == null) return null;
        
        // Search recursively through all children
        TextMeshProUGUI[] allTexts = uiCanvas.GetComponentsInChildren<TextMeshProUGUI>(true);
        
        foreach (var text in allTexts)
        {
            if (text.gameObject.name == componentName)
            {
                return text;
            }
        }
        
        return null;
    }

    void OnMove(InputValue movementValue)
    {
        Vector2 movementVector = movementValue.Get<Vector2>();

        movementX = movementVector.x * 0.6f;
        movementY = movementVector.y * 0.6f;
    }

    void SetScoreText()
    {
        if (scoreText != null)
            scoreText.text = $"Score: {score}";
    }

    void UpdateTimeText()
    {
        if (timeText != null)
        {
            int minutes = Mathf.FloorToInt(gameTime / 60f);
            int seconds = Mathf.FloorToInt(gameTime % 60f);
            timeText.text = $"Time: {minutes:00}:{seconds:00}";
        }
    }

    void UpdateDeathsText()
    {
        if (deathsText != null)
        {
            deathsText.text = $"Deaths: {deaths}";
        }
    }

    void UpdateLivesText()
    {
        if (livesText != null)
        {
            livesText.text = $"Lives: {lives}";
        }
    }

    void Update()
    {
        gameTime += Time.deltaTime;
        UpdateTimeText();
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
                lives += pickUp.healthRestore;
            }

            other.gameObject.SetActive(false);
            SetScoreText();
            UpdateLivesText();
        }
        
        if (other.gameObject.CompareTag("Goal"))
        {
            // if you reach the goal, you win the game!
            if (statsDisplay != null)
            {
                statsDisplay.ShowWinStats(this);
            }
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
        deaths++; // Count deaths
        UpdateDeathsText();
        if (lives > 1)
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
        UpdateLivesText();

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
        if (statsDisplay != null)
        {
            statsDisplay.ShowGameOverStats(this);
        }
        Destroy(gameObject);
    }
}
