. "\funcs.ps1"

$TeamsToMonitor = "IND", "CHI", "PHI"
$MakerURL = ""

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
    $Scores += compare-Scores -PreviousScores $PreviousScores -CurrentScores $CurrentScores
    foreach($score in $Scores){
        if($score.TeamName -in $TeamsToMonitor){
            "Yay! $($score.TeamName) scores!"
            $body = @{value1="$($score.Points)"; value2="$($Score.Color)"}
            Invoke-WebRequest -Uri $MakerURL -Method Post -Body (ConvertTo-Json $body) -ContentType application/json
        } else {
            "Boo! No $($score.TeamName) Score!"
            $body = @{value1="1"; value2="red)"; value3="5"} #Value3 could be transition_duration or fade_out_duration
        }
    }
}


