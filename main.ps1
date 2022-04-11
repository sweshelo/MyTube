# Import API Key
. ./key.ps1

function check_health(){
  try{
    $null = $(youtube-dl --version);
  }catch{
    Write-Output "youtube-dl not installed";
    exit 1;
  }

  try{
    $null = $(mpv --version);
  }catch{
    Write-Output "mpv not installed";
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression && scoop install mpv
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
  return $(Invoke-WebRequest "https://www.googleapis.com/youtube/v3/search?$paramStrings");
}

function getVideos($HTTPResponse){
  $ResultsObject = $HTTPResponse.Content | ConvertFrom-Json;
  return $ResultsObject.items | Where-Object{ $_.id.kind -eq 'youtube#video' }
}

function expand_to_array([string]$str){
  return $str.Split(",") | %{
    if($_.Contains("-")){
      $val=$_.Split("-");
      $start = convertTo-int($val[0]);
      $end = convertTo-int($val[1]);
      if ( $start -eq -1 -or $end -eq -1) {
        Write-Error "Invalid range : $($val[0]) to $($val[1])";
        return @();
      }
      for($i = $start; $i -le $end; $i++){
        $i;
      }
    }else{
      if (convertTo-int($_) -ne $null){
        convertTo-int($_);
      }else{
        Write-Error "Invalid value : $_";
        return @();
      }
    }
  }
}

function convertTo-int([string]$str){
  try{
    return [int]$str;
  }catch{
    return $null;
  }
}

function show_result($Videos){
  $index = 0;
  $Videos | ForEach-Object{
    $index++;
    Write-Host $("{0:D2} - $($_.snippet.title + $_.title)" -f $index);
  }
  Write-Host ""
}

function main(){
  $resultList = @();
  $mode = "remote";
  $downloaded_videos = Get-Content ~/Downloads/mytube/data.json | ConvertFrom-Json

  while($true){
    $query = Read-Host -p "Enter /<text> to search for videos";
    $action = $false;

    # 入力内容から操作を分岐させる
    switch($query){
      { $query -eq "exit" -or $query -eq "quit" -or $query -eq "q"} {
        $downloaded_videos | ConvertTo-Json > ~/Downloads/mytube/data.json;
        exit;
      }
      "help" {
        Write-Host "exit: exit the program";
        Write-Host "help: show this help";
        Write-Host "/<text>: search videos";
        Write-Host "<Number>: download the video";
        Write-Host "local: change to local mode";
        $action = $true;
        break;
      }
      "play" {
        $mode = "local";
        $resultList = $downloaded_videos.videos;
        show_result($downloaded_videos.videos);
        $action = $true;
        break;
      }
    }

    if ( $action ) { continue };

    # 検索
    if ($query[0] -eq '/'){
      $mode = "remote";
      $query = $query.Substring(1);
      $resultList = getVideos(search($query));
      show_result($resultList);
      continue;
    }

    $splited_query = expand_to_array($query);

    # ダウンロード
    if ($splited_query.Length -gt 0 -and $mode -eq "remote"){
      $splited_query | %{
        $videoIndex = $_;
        $target_video = $resultList[$($videoIndex - 1)];
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
      }
      continue;
    }

    # 再生
    if($splited_query.Length -gt 0 -and $mode -eq "local") {
      $splited_query | %{
        $videoIndex = $_;
        $target_path = "~/Downloads/mytube/" + $resultList[$($videoIndex - 1)].id + ".wav";
        echo "Start : $target_path"
        mpv $(Convert-Path $target_path);
      }
      continue;
    }

    Write-Host "Invalid query"
  }
}

check_health
main
