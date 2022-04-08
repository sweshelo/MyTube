# Import API Key
. ./key.ps1

function check_health(){
  try{
    $youtube_dl = $(youtube-dl --version);
  }catch{
    echo "youtube-dl not installed";
    exit 1;
  }

  try{
    $mpv = $(mpv --version);
  }catch{
    echo "mpv not installed";
    iwr -useb get.scoop.sh | iex && scoop install mpv
  }

  if ( !(Test-Path "~/Downloads/mytube") ){
    mkdir ~/Downloads/mytube;
  }

  if ( !(Test-Path "~/Downloads/mytube/data.json") ){
    $new_data = @{
      videos = @();
      playlist = @();
    }
    $new_data | ConvertTo-Json > ~/Downloads/mytube/data.json;
  }
}

function search($query){
  $paramStrings = "part=snippet&q=" + $query + "&key=" + $API_KEY + "&maxResults=10" + "&type=video";
  return $(iwr "https://www.googleapis.com/youtube/v3/search?$paramStrings");
}

function getVideos($HTTPResponse){
  $ResultsObject = $HTTPResponse.Content | ConvertFrom-Json;
  return $ResultsObject.items | ?{ $_.id.kind -eq 'youtube#video' }
}

function show_result($Videos){
  $index = 0;
  $Videos | %{
    $index++;
    Write-Host $("{0:D2} - $($_.snippet.title + $_.title)" -f $index);
  }
  Write-Host ""
}

function main(){
  $resultList = @();
  $mode = "remote";
  $downloaded_videos = cat ~/Downloads/mytube/data.json | ConvertFrom-Json

  while($true){
    $query = Read-Host -p "Enter /<text> to search for videos";

    # 入力内容から操作を分岐させる
    switch ($query){
      {$query -eq "exit" -or $query -eq "quit" -or $query -eq "q"}{
        $downloaded_videos | ConvertTo-Json > ~/Downloads/mytube/data.json
        exit;
      }
      "help"{
        Write-Host "exit: exit the program";
        Write-Host "help: show this help";
        Write-Host "/<text>: search videos";
        Write-Host "<Number>: download the video";
        Write-Host "local: change to local mode";
        break;
      }
      "play"{
        $mode = "local";
        $resultList = $downloaded_videos.videos;
        show_result($downloaded_videos.videos);
      }
      {$query[0] -eq '/'} {
        $mode = "remote";
        $query = $query.Substring(1);
        $resultList = getVideos(search($query));
        show_result($resultList)
        break;
      }
      {$query -as [int] -gt 0 -and $mode -eq "remote"} {
        $target_video = $resultList[$([int]$query - 1)]
        $videoId = $target_video.id.videoId;
        if ($videoId){
          Write-Host "Start downloading ${videoId}...";
          $downloaded_videos.videos += @{
            id = $videoId;
            title = $target_video.snippet.title;
            channel = $target_video.snippet.channelTitle;
          };
          youtube-dl $videoId --no-playlist --audio-format wav -x -o "~/Downloads/mytube/${videoId}.%(ext)s" --verbose && Write-Host "Download complete ${videoId}" && $downloaded_videos | ConvertTo-Json > ~/Downloads/mytube/data.json &
        }
        break;
      }
      {$query -as [int] -gt 0 -and $mode -eq "local"} {
        $target_path = "~/Downloads/mytube/" + $resultList[$([int]$query - 1)].id + ".wav"
        mpv $(Convert-Path $target_path)
      }
      default{
        Write-Host "Invalid query"
      }
    }
    Write-Host ""
  }
}

check_health
main
