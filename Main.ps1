. "\funcs.ps1"

$PeoplesTeams = New-Object system.Collections.ArrayList


$MyTeams = New-Object System.Collections.ArrayList
$MyTeams +=  @{League = "NHL"; Team = "Tampa Bay Lightning"; Color1 = "blue"; Color2 = "white"}
$MyTeams +=  @{League = "NFL"; Team = "IND"; Color1 = "blue"; Color2 = "white"}

$PeoplesTeams += @{Name="Person1"; Key="Key1"; Teams=$MyTeams}


$DadsTeams = New-Object System.Collections.ArrayList
$DadsTeams +=  @{League = "NFL"; Team = "IND"; Color1 = "blue"; Color2 = ""}
$PeoplesTeams += @{Name="Person2"; Key="Key2"; Teams=$DadsTeams}


$TeamsToMonitor = $PeoplesTeams.teams.team
$LeaguesToMonitor = $PeoplesTeams.teams.League

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
        $Scores += compare-Scores -PreviousScores $($PreviousScores | Where-Object {$_.home -in $MyTeams.Team -or $_.away -in $MyTeams.Team}) `
            -CurrentScores $($CurrentScores | Where-Object {$_.home -in $MyTeams.Team -or $_.away -in $MyTeams.Team}) -MyTeams $($person.Teams)

        invoke-ScoreBird -Scores $Scores -MyTeams $MyTeams -token $token
    }

    $PreviousScores = $CurrentScores
    Start-Sleep -Seconds 10
    $RunTime += 10
    $LeaguesToMonitor = $CurrentScores.League
}





