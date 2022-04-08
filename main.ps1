# Import API Key
. ./key.ps1

function check_health(){
  try{
    $youtube_dl = $(youtube-dl --version);
  }catch{
    echo "youtube-dl not installed";
    exit 1;
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
    Write-Host $("{0:D2} - $($_.snippet.title)" -f $index);
  }
  Write-Host ""
}

function main(){
  $resultList = @();
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
        break;
      }
      {$query[0] -eq '/'} {
        $query = $query.Substring(1);
        $resultList = getVideos(search($query));
        show_result($resultList)
        break;
      }
      {$query -as [int] -gt 0 -and $resultList} {
        $target_video = $resultList[$([int]$query - 1)]
        $videoId = $target_video.id.videoId;
        if ($videoId){
          Write-Host "Start downloading ${videoId}...";
          $downloaded_videos.videos += @{
            id = $videoId;
            title = $target_video.snippet.title;
            channel = $target_video.snippet.channelTitle;
          };
          youtube-dl $videoId --no-playlist --audio-format wav -x -o "~/Downloads/mytube/${videoId}.%(ext)s" --verbose && Write-Host "Download complete ${videoId}" &
        }
        break;
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
