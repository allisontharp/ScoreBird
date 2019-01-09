<#
    ToDO:
        - Leagues to add:
            - https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b
            - Men's College Basketball: http://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard
            - Men's College Football: http://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard 
#>


function get-NFLScores(){
    $GamesArray = New-Object System.Collections.ArrayList
    
    $url = "http://www.nfl.com/liveupdate/scores/scores.json"

    $scores = Invoke-WebRequest -Uri $url | ConvertFrom-Json

    $gameIDs = $scores | Get-Member | Where-Object MemberType -eq NoteProperty | Select-Object Name

    foreach ($game in $gameIDs){
        $nflObject = $scores.$($game.Name)

        $gamesObject = New-Object System.Object
        $gamesObject | Add-Member -MemberType NoteProperty -Name GameID -Value $($game.name)
        $gamesObject | Add-Member -MemberType NoteProperty -Name League -Value "NFL"
        $gamesObject | Add-Member -MemberType NoteProperty -Name GameStatus -Value $($nflObject.qtr)
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value $($nflObject.home.abbr)
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $($nflObject.home.score.T)
        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value $($nflObject.away.abbr)
        $gamesObject | Add-Member -MemberType NoteProperty -Name AwayScore -Value $($nflObject.away.score.T)

        $GamesArray += $gamesObject
        
    }
    return $GamesArray
}

function compare-Scores($PreviousScores, $CurrentScores, $MyTeams){
    $Output = New-Object System.Collections.ArrayList
    
    foreach($game in $PreviousScores){
        $GameID = $game.GameID
        $CurrentScoreForGame = $CurrentScores | Where-Object {$_.GameID -eq $GameID}
        $HomeDiff = $CurrentScoreForGame.HomeScore - $Game.HomeScore
        $AwayDiff = $CurrentScoreForGame.AwayScore - $Game.AwayScore

        if($HomeDiff -gt 0){
            $TeamName = $game.Home
            $Color1 = ($MyTeams | Where-Object {$_.Team -eq $TeamName}).Color1
            if($Color1.count -eq 0){$Color1 = "red"}
            $Output += @{TeamName = $TeamName; Points = $HomeDiff; Color = $Color1}
        }

        if ($AwayDiff -gt 0){
            $TeamName = $game.Away
            $Color1 = ($MyTeams | Where-Object {$_.Team -eq $TeamName}).Color1
            if($Color1.count -eq 0){$Color1 = "red"}
            $Output += @{TeamName = $($game.Away); Points = $AwayDiff; Color = $Color1}
        }
    }

    $Output
}

function get-NHLScores(){
    $url = "https://statsapi.web.nhl.com/api/v1/schedule?"
    $games = Invoke-WebRequest -Uri $url | ConvertFrom-Json
    $games = $games.dates.games   # ToDO: what happens if multiple dates?

    $GamesArray = New-Object System.Collections.ArrayList

    foreach ($game in $games){
        $gamesObject = New-Object System.Object

        $gamesObject | Add-Member -MemberType NoteProperty -Name GameID -Value $($game.gamePk)
        $gamesObject | Add-Member -MemberType NoteProperty -Name League -Value "NHL"
        $gamesObject | Add-Member -MemberType NoteProperty -Name GameStatus -Value $($game.status.abstractGameState)
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value $($game.teams.home.team.name)
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $($game.teams.home.score)

        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value $($game.teams.away.team.name)
        $gamesObject | Add-Member -MemberType NoteProperty -Name AwayScore -Value $($game.teams.away.score)

        $GamesArray += $gamesObject
    }
    return $GamesArray
}

function get-NCAAFScores(){
    $gamesArray = New-Object System.Collections.ArrayList

    $url = "http://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard"
    $scores = Invoke-WebRequest -Uri $url | ConvertFrom-Json

    $gameIDs = $scores.events | Select-Object id

    foreach ($gameID in $gameIDs){
        $gameID = $($gameID.id)
        $game = $scores.events | Where-Object {$_.id -eq $gameID}
        $gamesObject = New-Object System.Object

        $gamesObject | Add-Member -MemberType NoteProperty -Name GameID -Value $gameID
        $gamesObject | Add-Member -MemberType NoteProperty -Name League -Value "NCAAF"
        $gamesObject | Add-Member -MemberType NoteProperty -Name GameStatus -Value $($game.status.type.shortDetail)
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).team.abbreviation)
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).score)
        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).team.abbreviation)
        $gamesObject | Add-Member -MemberType NoteProperty -Name AwayScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).score)

        $GamesArray += $gamesObject
    }
    return $gamesArray
}

function invoke-IFTTTTrigger ($Key, $IFTTTrigger, $Body){
    $MakerURL = "https://maker.ifttt.com/trigger/$IFTTTrigger/with/key/$Key"
    $request = Invoke-WebRequest -Uri $MakerURL -Method Post -Body (ConvertTo-Json $body) -ContentType application/json
}

function invoke-ScoreBird ($Scores, $Key, $TeamsToMonitor){
    foreach($score in $Scores){
        if($score.TeamName -in $TeamsToMonitor){
            "Yay! $($score.TeamName) scores!"
            $body = @{value1="$($score.Points)"; value2="$($Score.Color)"}
            invoke-IFTTTTrigger -Key $Key -IFTTTrigger "scorebird" -Body $body
        } else {
            "Boo! No $($score.TeamName) Score!"
            $body = @{value1="10"; value2="red"} # value1 is fade_out_duration , value2 is color
            invoke-IFTTTTrigger -Key $Key -IFTTTrigger "FadeOut" -Body $body
            Start-Sleep -Seconds 5
            $body = @{value1="10"; value2="white"} # value1 is fade_out_duration , value2 is color
            invoke-IFTTTTrigger -Key $Key -IFTTTrigger "FadeIn" -Body $body

            
        }
    }
}



function get-CurrentScores($OnlyMonitoredTeams, $OnlyActiveGames, $TeamsToMonitor, $LeaguesToMonitor){  
    if ("NFL" -in $LeaguesToMonitor)  
        {$CurrentScores = get-NFLScores}
    if ("NHL" -in $LeaguesToMonitor)
        {$CurrentScores += get-NHLScores}
    if ("NCAAF -in $LeaguesToMonitor")
        {$CurrentScores += get-NCAAFScores}
    
    if($OnlyMonitoredTeams -eq 1 -and $OnlyActiveGames -eq 1){
        $CurrentScores = $CurrentScores| Where-Object {($_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor)) -and $_.GameStatus -ne "Final"}
    }elseif ($OnlyMonitoredTeams -eq 1 -and $OnlyActiveGames -eq 0) {
        $CurrentScores = $CurrentScores| Where-Object {($_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor))}        
    }elseif ($OnlyMonitoredTeams -eq 0 -and $OnlyActiveGames -eq 1) {
        $CurrentScores = $CurrentScores| Where-Object {$_.GameStatus -ne "Final"}        
    }
    return $CurrentScores 
}


function invoke-setLight ($color, $brightness){
    $url = "https://api.lifx.com/v1/lights/all/state"
    $body = @{
        "power"="on";
        "color" = "$color";
        "brightness" = $brightness
    }

    Invoke-RestMethod -Headers $header -Uri $url -Body $($body|ConvertTo-Json) -Method Put
}
function invoke-cycleColors ($primaryColor, $secondaryColor, $numberBlinks){
    $url = "https://api.lifx.com/v1/lights/all/cycle"
    if($primaryColor -ne $secondaryColor) {
        $body = @{
            "states" = @(
                @{"brightness" = 1.0;
                    "color" = "$primaryColor"},
                @{"brightness" = 1.0;
                    "color" = "$secondaryColor"}
            );
            "defaults" = @{
                "power" = "on";
                "duration" = 0;
                "fast" = "true"
            }
        }
    } else {
        $body = @{
            "states" = @(
                @{"brightness" = 1.0;
                    "color" = "$primaryColor"},
                @{"brightness" = 1.0;
                    "color" = "white"}
            );
            "defaults" = @{
                "power" = "on";
                "duration" = 0;
                "fast" = "true"
            }
        }
        $numberBlinks += $numberBlinks
    }

    for($i=0; $i -le $numberBlinks; $i++){
        Invoke-RestMethod -Headers $header -Uri $url -Body $($body|ConvertTo-Json) -Method Post -ContentType application/json
    }

    invoke-setLight -color "white" -brightness 0.8

}


function invoke-Pulse ($primaryColor, $secondaryColor, $numberBlinks, $token){
    $url = "https://api.lifx.com/v1/lights/all/effects/pulse"

    $header = @{
        "Authorization" = "Bearer $token"
    }
    
    $body = @{
        "color" = "$primaryColor";
        "from_color" = "$secondaryColor";
        "period" = 1;
        "cycles" = $numberBlinks;
        "power_on" = $true;
        "persist" = $false
    }
    Invoke-RestMethod -Headers $header -Uri $url -Body $($body|ConvertTo-Json) -Method Post -ContentType application/json
}