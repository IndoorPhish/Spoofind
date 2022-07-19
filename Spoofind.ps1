Function CreateTheHiveAlert {
param(
#Params that must be passed to TheHive
[Parameter(mandatory=$True)] [string]$AlertTitle,
[Parameter(mandatory=$True)] [string]$Description,
[Parameter(mandatory=$True)] [string]$Source,
[Parameter(mandatory=$True)] [int]$Severity,
[Parameter(mandatory=$True)] $ioc_artifact
)
    [int]$tlp = 1
#Insert your API endpoint for TheHive
    [string]$API_Uri = "XXXXXX"
    [string]$API_Method = "Post"
    $AlertDescription = $Description -replace '<[^>]+>',''
#API Token goes below
$APIToken = "XXXXXX"
    $API_headers = @{Authorization = "Bearer $APIToken"}
$SourceRef = New-Guid

    $body = @{
        title = "$AlertTitle"
        description = "$AlertDescription"
        type = "external"
        source = "$Source"
        sourceRef = "$SourceRef"
        severity = $Severity
        tlp = $tlp
artifacts = $ioc_artifact
    }
$JsonBody = $body | ConvertTo-Json
Invoke-RestMethod -Uri $API_Uri -Headers $API_headers -Body $JsonBody -Method $API_Method -ContentType 'application/json' -Verbose
}

#Define regex matches below
$search = New-Object -TypeName "System.Collections.ArrayList"
[void]$search.Add("%Google%")
[void]$search.Add(".*[g9]+[0o]{2,}[9g]+[l7i1t]+[3ea]+.*")
[void]$search.Add("%Microsoft%")
[void]$search.Add(".*(m|rn)+[1i7oa04]*[ck]+[rtf]+[0o]*[s5z]+[0o]+[ft]+.*")

$dir = Get-Location
$date = Get-Date
#Check the previous day
$date = $date.AddDays(-1).ToString("yyyy-MM-dd")
$uri = "isc.sans.edu/api/recentdoma…" + $date + "?json"
$dlFile = $date + "-DomainNames.json"

#Get Domains from SANS
Invoke-WebRequest -Uri "$uri" -OutFile "$dlFile" -UserAgent "Powershell Core" -ErrorAction Stop

#Check if the output files already exist and delete them if they do
$outFileTxt = "$dir\$date-Detections.txt"
$outFileJSON = "$dir\$date-Detections.json"
$bool = Test-Path -Path "$dir\$date-Detections.txt"
$bool2 = Test-Path -Path "$dir\$date-Detections.json"
if ($bool -eq $true){
    Remove-Item -Path $outFileTxt
    }
if ($bool2 -eq $true){
    Remove-Item -Path $outFileJSON
    }

#Add date to the top of the text file and add a square bracket to the json file
$date | Set-Content -Path "$outFileTxt" -Force
Set-Content -Path "$outFileJSON" -Value "[" -Force -NoNewline

#Convert the downloaded file from json to run searches against it
$data = Get-Content "$dir\$dlFile" | ConvertFrom-JSON

#Counter count is used for determining the search currently running by ref'ing the array
#Counter results is used at the end to determine if there were any matches
[int]$count = 0
[int]$results = 0

ForEach ($s in $search){
#For each item in the search list that does not contain a perecent as this is the search title
    if ($s -notcontains "%"){
        ForEach ($line in $data) {
            if ($($line.domainname) -match $s){
                $results++
#This part just grabs the search name by referencing the search in the list -1
$name = $count-1
$searchName = $search[$name].trim("%")
#Determine if an IP is resolved - mainly used for sending to TheHive
if ($($line.ip) -eq "0.0.0.0"){
$desc = "An IP could not be resolved for this domain"
}
else {
$desc = "This domain resolved for the IP address $($line.ip)"
}
#Formatting for the txt and json files
                $printTxt = "Match found: $searchName --- $($line.domainname), First Observed: $($line.firstseen), IP Resolution: $desc"
$printJSON = "{""""match"""":""""$searchName"""",""""domainname"""":""""$($line.domainname)"""",""""ip"""":""""$($line.ip)"""",""""type"""":""""$($line.type)"""",""""firstseen"""":""""$($line.firstseen)""""},"
                $printTxt | Add-Content -Path "$outFileTxt"
$printJSON | Add-Content -Path "$outFileJSON" -NoNewline
$AlertTitle = "Suspicious Domain Registration Identified: $($line.domainname)"
$Description = "The domain $($line.domainname) was first observed on $($line.firstseen) and has matched search criteria for """"$searchName"""". This could be used for phishing or other nefarious purposes. $desc."
$ioc_artifact = @()
$ioc_artifact += @(
[ordered]@{
"datatype" = "domain";
"data" = $($line.domainname);
"message" = "domain";
"ioc" = $True;
"sighted" = $True;
}
)
#Call TheHive function to send data
#CreateTheHiveAlert -AlertTitle $AlertTitle -Description $Description -Source "Suspicious Domain Registrations" -Severity 1
}
        }
    }
    $count++
}
#Remove files if no results
if ($results -eq 0){
Remove-Item -Path $outFileTxt
Remove-Item -Path $outFileJSON
}
#If files then remove the final comma and add in a square bracket to make the json clean
else {
$t = Get-Content "$outFileJSON"
$t.TrimEnd(',') | Set-Content -Path "$outFileJSON" -Force -NoNewline
Add-Content -Path "$outFileJSON" -Value "]" -NoNewline
}
