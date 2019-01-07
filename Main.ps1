. "\funcs.ps1"

$Key = ""

$MyTeams = New-Object System.Collections.ArrayList
$MyTeams += @{League = "NFL"; Team = "IND"; Color1 = "blue"; Color2 = "white"}
$MyTeams +=  @{League = "NHL"; Team = "Tampa Bay Lightning"; Color1 = "blue"; Color2 = "white"}
$MyTeams += @{League = "NFL"; Team = "LAC"; Color1 = "yellow"; Color2 = "blue"}
$MyTeams +=  @{League = "NHL"; Team = "Chicago Blackhawks"; Color1 = "yellow"; Color2 = "green"}

$TimeToRun = 60 #minutes
$RunTime = 0

$TeamsToMonitor = ($MyTeams | Select-Object @{Name="TeamName"; Expression = {$_.Team}}).TeamName

$CurrentScores = get-NFLScores 
$CurrentScores += get-NHLScores
$CurrentScores = $CurrentScores| Where-Object {$_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor) -and $_.GameStatus -ne "Final"}
$PreviousScores = $CurrentScores


while ($RunTime -le $TimeToRun*60){
    Remove-Variable CurrentScores
    $CurrentScores = get-NFLScores 
    $CurrentScores += get-NHLScores
    $CurrentScores = $CurrentScores| Where-Object {$_.Home -in $($TeamsToMonitor) -or $_.Away -in $($TeamsToMonitor) -and $_.GameStatus -ne "Final"}
    Start-Sleep -Seconds 10
    $RunTime += 10
    $PreviousScores = $CurrentScores

    $Scores = New-Object System.Collections.ArrayList
    $Scores += compare-Scores -PreviousScores $PreviousScores -CurrentScores $CurrentScores -MyTeams $MyTeams
    
    invoke-ScoreBird -Scores $Scores 
}


