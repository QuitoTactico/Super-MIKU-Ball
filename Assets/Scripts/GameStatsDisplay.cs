using UnityEngine;
using TMPro;

public class GameStatsDisplay : MonoBehaviour
{
    [Header("UI Text References")]
    public TextMeshProUGUI titleText;
    public TextMeshProUGUI scoreText;
    public TextMeshProUGUI timeText;
    public TextMeshProUGUI deathsText;

    void Start()
    {
        gameObject.SetActive(false);
    }

    public void ShowWinStats(PlayerController player)
    {
    ShowStats("You Win!!\nPress R to restart", player);
    }

    public void ShowGameOverStats(PlayerController player)
    {
        ShowStats("Game Over!\nPress R to restart", player);
    }

    private void ShowStats(string title, PlayerController player)
    {
        Debug.Log("ShowStats called with title: " + title);

        HideCanvasUI(player);
        
        // Activate this centered display
        gameObject.SetActive(true);

        // Set the title
        if (titleText != null)
            titleText.text = title;

        // Copy values from corner UI
        if (player != null)
        {
            Debug.Log($"Player ScoreText found: {player.ScoreText != null}");
            Debug.Log($"Player TimeText found: {player.TimeText != null}");
            Debug.Log($"Player DeathsText found: {player.DeathsText != null}");
            
            if (scoreText != null && player.ScoreText != null)
            {
                string originalText = player.ScoreText.text;
                scoreText.text = originalText;
                Debug.Log($"Copied score text: {originalText}");
            }

            if (timeText != null && player.TimeText != null)
            {
                string originalText = player.TimeText.text;
                timeText.text = originalText;
                Debug.Log($"Copied time text: {originalText}");
            }

            if (deathsText != null && player.DeathsText != null)
            {
                string originalText = player.DeathsText.text;
                deathsText.text = originalText;
                Debug.Log($"Copied deaths text: {originalText}");
            }
        }
        else
        {
            Debug.LogError("Player reference is null!");
        }
    }

    private void HideCanvasUI(PlayerController player)
    {
        if (player.ScoreText != null) 
        {
            player.ScoreText.gameObject.SetActive(false);
            Debug.Log("Hidden ScoreText");
        }
        if (player.TimeText != null) 
        {
            player.TimeText.gameObject.SetActive(false);
            Debug.Log("Hidden TimeText");
        }
        if (player.DeathsText != null) 
        {
            player.DeathsText.gameObject.SetActive(false);
            Debug.Log("Hidden DeathsText");
        }
        if (player.LivesText != null) 
        {
            player.LivesText.gameObject.SetActive(false);
            Debug.Log("Hidden LivesText");
        }
    }

    public void HideStats()
    {
        gameObject.SetActive(false);
    }
}