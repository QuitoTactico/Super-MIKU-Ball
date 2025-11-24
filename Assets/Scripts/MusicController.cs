using UnityEngine;
using UnityEngine.InputSystem;
using TMPro;

public class MusicController : MonoBehaviour
{
    [Header("References")]
    public PlayerController player;
    public AudioSource musicPlayer;
    public AudioSource musicPlayerWin;
    public TextMeshProUGUI songText;
    
    private bool winMusicPlayed = false;
    
    void Start()
    {
        // Load and play random OST at start
        PlayRandomOST();
    }

    void Update()
    {
        // Check if player won and win music hasn't been played yet
        if (player != null && !winMusicPlayed && player.gameWon)
        {
            winMusicPlayed = true;
            if (musicPlayerWin != null)
            {
                musicPlayerWin.gameObject.SetActive(true);
                musicPlayer.gameObject.SetActive(false);
            }
        }

        // Press M to randomize OST
        if (Keyboard.current != null && Keyboard.current.mKey.wasPressedThisFrame)
        {
            PlayRandomOST();
        }
        
        // Check for gamepad button as well (B/O button)
        if (Gamepad.current != null && Gamepad.current.buttonEast.wasPressedThisFrame)
        {
            PlayRandomOST();
        }
    }
    
    private void PlayRandomOST()
    {
        if (musicPlayer == null) return;
        
        // Load all audio clips from Resources/Audio/OST
        AudioClip[] ostClips = Resources.LoadAll<AudioClip>("Audio/OST");
        
        if (ostClips.Length > 0)
        {
            // Pick a random OST
            int randomIndex = Random.Range(0, ostClips.Length);
            musicPlayer.clip = ostClips[randomIndex];
            musicPlayer.Play();
            
            // Update song title text (remove .mp3 extension if present)
            string songTitle = ostClips[randomIndex].name;
            UpdateSongText(songTitle);
            
            Debug.Log($"Now playing: {songTitle}");
        }
        else
        {
            Debug.LogWarning("No OST files found in Resources/Audio/OST");
        }
    }
    
    private void UpdateSongText(string songTitle)
    {
        if (songText != null)
        {
            songText.text = songTitle;
        }
    }
}
