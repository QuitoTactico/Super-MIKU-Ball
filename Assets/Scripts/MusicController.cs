using UnityEngine;
using UnityEngine.InputSystem;

public class MusicController : MonoBehaviour
{
    [Header("References")]
    public PlayerController player;
    public AudioSource musicPlayer;
    public AudioSource musicPlayerWin;
    
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
            }
        }
        
        // Press M to randomize OST
        if (Keyboard.current != null && Keyboard.current.mKey.wasPressedThisFrame)
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
            
            Debug.Log($"Now playing: {ostClips[randomIndex].name}");
        }
        else
        {
            Debug.LogWarning("No OST files found in Resources/Audio/OST");
        }
    }
}
