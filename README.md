# MyTube
YouTube download on CUI using youtube-dl.

# Usage
1. Visit [Google Cloud Platform](https://console.cloud.google.com/apis/credentials) and create your API key.
2. Create `key.ps1` in this repository and write yout API key likely `$API_KEY = XXXXXXXXX`.
3. Run `./main.ps1` on PowerShell (not WindowsPowerShell).

## Download
Please type `/<search text>`.  
After display results, type index of video to Download.  
Supports shortened forms such as `1-3` and `1, 3, 6-9`.

## Play
Please type `play`.  
After display local .wav files, type a number to play music.  
