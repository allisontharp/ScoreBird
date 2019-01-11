<#
    ToDO:
        - Leagues to add:
            - https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b
            - Men's College Basketball: http://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard
            + Men's College Football: http://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard 
            - ECHL
            + NBA
        - only trigger IND if it is IND and NBA (and not if I have IND NFL for pacers)
        - turn lights on after blinking
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
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value "NFL - $($nflObject.home.abbr)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $($nflObject.home.score.T)
        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value "NFL - $($nflObject.away.abbr)"
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
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value "NHL - $($game.teams.home.team.name)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $($game.teams.home.score)

        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value "NHL - $($game.teams.away.team.name)"
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
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value "NCAAF - $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).team.abbreviation)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).score)
        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value "NCAAF - $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).team.abbreviation)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name AwayScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).score)

        $GamesArray += $gamesObject
    }
    return $gamesArray
}

function get-NBAScores(){
    $gamesArray = New-Object System.Collections.ArrayList

    $url = "http://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard"
    $scores = Invoke-WebRequest -Uri $url | ConvertFrom-Json

    $gameIDs = $scores.events | Select-Object id

    foreach ($gameID in $gameIDs){
        $gameID = $($gameID.id)
        $game = $scores.events | Where-Object {$_.id -eq $gameID}
        $gamesObject = New-Object System.Object

        $gamesObject | Add-Member -MemberType NoteProperty -Name GameID -Value $gameID
        $gamesObject | Add-Member -MemberType NoteProperty -Name League -Value "NBA"
        $gamesObject | Add-Member -MemberType NoteProperty -Name GameStatus -Value $($game.status.type.shortDetail)
        
        $gamesObject | Add-Member -MemberType NoteProperty -Name Home -Value "NBA - $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).team.abbreviation)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name HomeScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'home'}).score)
        $gamesObject | Add-Member -MemberType NoteProperty -Name Away -Value "NBA - $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).team.abbreviation)"
        $gamesObject | Add-Member -MemberType NoteProperty -Name AwayScore -Value $(($game.competitions[0].competitors | Where-Object {$_.homeAway -eq 'away'}).score)

        $GamesArray += $gamesObject
    }
    return $gamesArray
}

function invoke-ScoreBird ($Scores, $myTeams, $token){
    foreach($score in $Scores){
        if($score.TeamName -in $myTeams.LeagueTeam){
            "Yay! $($score.TeamName) scores!"
            invoke-Pulse -primaryColor ($MyTeams | Where-Object {$_.LeagueTeam -eq $($score.TeamName)}).color1 -secondaryColor ($MyTeams | Where-Object {$_.LeagueTeam -eq $($score.TeamName)}).color2 -numberBlinks $score.Points -token $token
        } else {
            "Boo! $($score.TeamName) Score!"
            invoke-Breathe -primaryColor "red" -token $token   
        }
    }
}



function get-CurrentScores($OnlyMonitoredTeams, $OnlyActiveGames, $TeamsToMonitor, $LeaguesToMonitor){  
    if ("NFL" -in $LeaguesToMonitor)  
        {$CurrentScores = get-NFLScores}
    if ("NHL" -in $LeaguesToMonitor)
        {$CurrentScores += get-NHLScores}
    if ("NCAAF" -in $LeaguesToMonitor)
        {$CurrentScores += get-NCAAFScores}
    if ("NBA" -in $LeaguesToMonitor)
        {$CurrentScores += get-NBAScores}
    
    if($OnlyMonitoredTeams -eq 1 -and $OnlyActiveGames -eq 1){
        $CurrentScores = $CurrentScores| Where-Object {($_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor)) -and $_.GameStatus -ne "Final"}
    }elseif ($OnlyMonitoredTeams -eq 1 -and $OnlyActiveGames -eq 0) {
        $CurrentScores = $CurrentScores| Where-Object {($_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor))}        
    }elseif ($OnlyMonitoredTeams -eq 0 -and $OnlyActiveGames -eq 1) {
        $CurrentScores = $CurrentScores| Where-Object {$_.GameStatus -ne "Final"}        
    }
    return $CurrentScores 
}


function invoke-setLight ($color, $brightness, $token){
    $url = "https://api.lifx.com/v1/lights/all/state"

    $header = @{
        "Authorization" = "Bearer $token"
    }

    $body = @{
        "power"="on";
        "color" = "$color";
        "brightness" = $brightness
    }

    Invoke-RestMethod -Headers $header -Uri $url -Body $($body|ConvertTo-Json) -Method Put
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

function invoke-Breathe ($primaryColor, $token){
    $url = "https://api.lifx.com/v1/lights/all/effects/breathe"

    $header = @{
        "Authorization" = "Bearer $token"
    }

    $body = @{
        "color" = "$primaryColor";
        "period" = 10;
        "cycles" = 1;
        "persist" = $false;
        "power_on" = $true
    }

    Invoke-RestMethod -Headers $header -Uri $url -Body $($body|ConvertTo-Json) -Method Post -ContentType application/json

}