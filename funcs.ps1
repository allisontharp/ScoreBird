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

function compare-Scores($PreviousScores, $CurrentScores){
    $Output = New-Object System.Collections.ArrayList
    
    foreach($game in $PreviousScores){
        $GameID = $game.GameID
        $CurrentScoreForGame = $CurrentScores | Where-Object {$_.GameID -eq $GameID}
        $HomeDiff = $CurrentScoreForGame.HomeScore - $Game.HomeScore
        $AwayDiff = $CurrentScoreForGame.AwayScore - $Game.AwayScore

        if($HomeDiff -gt 0){
            #$Output += ,($($game.Home), $HomeDiff, "blue")
            $Output += @{TeamName = $($game.Home); Points = $HomeDiff; Color = "blue"}
        }

        if ($AwayDiff -gt 0){
            #$Output += ,($($game.Away), $AwayDiff)
            $Output += @{TeamName = $($game.Away); Points = $AwayDiff; Color = "orange"}
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