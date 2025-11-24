import os
import pathlib

def extract_song_titles():
    """
    Extract all song titles from OST folder and generate a character list
    for TextMeshPro Font Asset Creator.
    """
    # Path to the OST folder
    ost_folder = pathlib.Path("Assets/Resources/Audio/OST")
    
    # Get all mp3 files
    mp3_files = [f for f in ost_folder.iterdir() if f.suffix == '.mp3']
    
    # Extract titles (remove file extension and " - ShibayanRecords" or similar artist suffix)
    titles = []
    all_chars = set()
    
    for mp3_file in mp3_files:
        # Get filename without extension
        title = mp3_file.stem
        titles.append(title)
        
        # Add all characters from title to set
        for char in title:
            all_chars.add(char)
    
    # Add ASCII printable characters (32-126)
    for i in range(32, 127):
        all_chars.add(chr(i))
    
    # Add extended Latin (160-255)
    for i in range(160, 256):
        all_chars.add(chr(i))
    
    # Add common punctuation and symbols (8192-8303)
    for i in range(8192, 8304):
        all_chars.add(chr(i))
    
    # Add specific symbols
    all_chars.add(chr(8364))  # Euro €
    all_chars.add(chr(8482))  # Trademark ™
    all_chars.add(chr(9633))  # Square ■
    
    # Add misc symbols (10752-11007) - includes ⧸
    for i in range(10752, 11008):
        all_chars.add(chr(i))
    
    # Add CJK symbols and punctuation, Hiragana, Katakana (12288-12543)
    for i in range(12288, 12544):
        all_chars.add(chr(i))
    
    # Add full-width characters (65280-65519)
    for i in range(65280, 65520):
        all_chars.add(chr(i))
    
    # Sort characters for better organization
    sorted_chars = sorted(all_chars)
    
    # Create Fonts directory if it doesn't exist
    fonts_dir = pathlib.Path("Assets/Fonts")
    fonts_dir.mkdir(parents=True, exist_ok=True)
    
    # Write everything to a single output file in Assets/Fonts
    output_file = fonts_dir / "font_characters.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        # Write all characters in one line (TMP likes this format)
        f.write(''.join(sorted_chars))
    
    # Generate Unicode range string
    unicode_ranges = "32-126,160-255,8192-8303,8364,8482,9633,10752-11007,12288-12543,65280-65519"
    
    print(f"✅ Generated {output_file} with {len(sorted_chars)} unique characters")
    print(f"✅ Found {len(titles)} song titles")
    print(f"\n📋 Unicode Range for TMP Font Asset Creator:")
    print(f"   {unicode_ranges}")
    print(f"\n📁 File created in: {os.getcwd()}")
    print(f"\n🎵 Song titles found:")
    for title in sorted(titles):
        print(f"   - {title}")

if __name__ == "__main__":
    extract_song_titles()
