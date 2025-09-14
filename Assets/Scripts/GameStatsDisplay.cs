using UnityEngine;
using TMPro;

public class GameStatsDisplay : MonoBehaviour
{
    [Header("UI Text References")]
    public TextMeshProUGUI titleText;
    public TextMeshProUGUI scoreText;
    public TextMeshProUGUI timeText;
    public TextMeshProUGUI deathsText;

    [Header("Player Reference")]
    public PlayerController player;

    public void ShowWinStats()
    {
        ShowStats("You Win!!!");
    }

    public void ShowGameOverStats()
    {
        ShowStats("Game Over!");
    }

    private void ShowStats(string title)
    {
        // Hide corner UI elements
        HideCornerUI();
        
        // Activate this centered display
        gameObject.SetActive(true);

        // Set the title
        if (titleText != null)
            titleText.text = title;

        // Copy values from corner UI
        if (player != null)
        {
            if (scoreText != null && player.ScoreText != null)
                scoreText.text = player.ScoreText.text;

            if (timeText != null && player.TimeText != null)
                timeText.text = player.TimeText.text;

            if (deathsText != null && player.DeathsText != null)
                deathsText.text = player.DeathsText.text;
        }
    }

    private void HideCornerUI()
    {
        if (player != null)
        {
            if (player.ScoreText != null) player.ScoreText.gameObject.SetActive(false);
            if (player.TimeText != null) player.TimeText.gameObject.SetActive(false);
            if (player.DeathsText != null) player.DeathsText.gameObject.SetActive(false);
            if (player.LivesText != null) player.LivesText.gameObject.SetActive(false);
        }
    }

    public void HideStats()
    {
        gameObject.SetActive(false);
    }
}