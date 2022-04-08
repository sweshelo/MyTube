# Import API Key
. ./key.ps1

function check_health(){
  try{
    $youtube_dl = $(youtube-dl --version);
  }catch{
    echo "youtube-dl not installed";
    exit 1;
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

function show_and_select_result($Videos){
  $index = 0;
  $Videos | %{
    $index++;
    Write-Host $("{0:D2} - $($_.snippet.title)" -f $index);
  }
  try{
    return [int]$(Read-Host -Prompt "Select a video ");
  }catch{
    Write-Host "Please type a number";
    return -1;
  }
}

function main(){
  while($true){
    $query = Read-Host -p "Search ";
    $resultList = getVideos(search($query));
    $select = show_and_select_result($resultList);
    $videoId = $resultList[$($select - 1)].id.videoId
    if ( $select -gt 0){
      youtube-dl $videoId --no-playlist --audio-format wav -x -o "${videoId}.%(ext)s" --verbose && Write-Host "Download complete ${videoId}" &
    }
  }
}

main
