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
            if($Color1.count -eq 0){$Color1 = "Red"}
            $Output += @{TeamName = $TeamName; Points = $HomeDiff; Color = $Color1}
        }

        if ($AwayDiff -gt 0){
            $TeamName = $game.Away
            $Color1 = ($MyTeams | Where-Object {$_.Team -eq $TeamName}).Color1
            if($Color1.count -eq 0){$Color1 = "Red"}
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

function invoke-IFTTTTrigger ($Key, $IFTTTrigger, $Body){
    $MakerURL = "https://maker.ifttt.com/trigger/$IFTTTrigger/with/key/$Key"
    Invoke-WebRequest -Uri $MakerURL -Method Post -Body (ConvertTo-Json $body) -ContentType application/json
}

function invoke-ScoreBird ($Scores){
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



