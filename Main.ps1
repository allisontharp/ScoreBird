. "funcs.ps1"

$PeoplesTeams = New-Object system.Collections.ArrayList


$MyTeams = New-Object System.Collections.ArrayList
$MyTeams +=  @{League = "NHL"; Team = "Tampa Bay Lightning"; Color1 = "blue"; Color2 = "white"}
$MyTeams +=  @{League = "NFL"; Team = "IND"; Color1 = "blue"; Color2 = "white"}


$PeoplesTeams += @{Name="Person1"; Key="LifxKey1"; Teams=$MyTeams}


$DadsTeams = New-Object System.Collections.ArrayList
$DadsTeams +=  @{League = "NFL"; Team = "IND"; Color1 = "blue"; Color2 = ""}
$DadsTeams +=  @{League = "NBA"; Team = "IND"; Color1 = "blue"; Color2 = "yellow"}
$PeoplesTeams += @{Name="Person2"; Key="LifxKey2"; Teams=$DadsTeams}

# Get a key for League - Team
foreach ($person in $PeoplesTeams){
    foreach($team in $person.teams){
        $LeagueTeam = "$($team.League) - $($team.team)"   
        $team | Add-Member -MemberType NoteProperty -Name LeagueTeam -Value $LeagueTeam
    }
}


$TeamsToMonitor = $PeoplesTeams.Teams.LeagueTeam | sort -Unique
$LeaguesToMonitor = $PeoplesTeams.Teams.League | sort -Unique

$CurrentScores = get-CurrentScores -OnlyMonitoredTeams 1 -OnlyActiveGames 1 -TeamsToMonitor $TeamsToMonitor -LeaguesToMonitor $LeaguesToMonitor
$PreviousScores = $CurrentScores

$TimeToRun = 4*60
$RunTime = 0
while ($RunTime -le $TimeToRun*60){
    Remove-Variable CurrentScores
    $CurrentScores = get-CurrentScores -OnlyMonitoredTeams 1 -OnlyActiveGames 1 -TeamsToMonitor $TeamsToMonitor -LeaguesToMonitor $LeaguesToMonitor

    foreach($person in $PeoplesTeams){
        $MyTeams = $person.teams
        $Scores = New-Object system.Collections.ArrayList
        $Scores += compare-Scores -PreviousScores $($PreviousScores | Where-Object {$_.home -in $MyTeams.LeagueTeam -or $_.away -in $MyTeams.LeagueTeam}) `
            -CurrentScores $($CurrentScores | Where-Object {$_.home -in $MyTeams.LeagueTeam -or $_.away -in $MyTeams.LeagueTeam}) -MyTeams $($person.Teams)

        invoke-ScoreBird -Scores $Scores -MyTeams $MyTeams -token $person.key
    }

    $PreviousScores = $CurrentScores
    Start-Sleep -Seconds 10
    $RunTime += 10
    $LeaguesToMonitor = $CurrentScores.League
}





