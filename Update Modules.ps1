#region Parameters
[string]$LogPath = "C:\Users\MichaelSeidlau2mator\OneDrive - Seidl Michael\2-au2mator\1 - TECHGUY\GitHub\PowerShell-Tools" #Path to store the Lofgile, only local or Hybrid
[string]$LogfileName = "UpdatePSModule" #FileName of the Logfile, only local or Hybrid
[int]$DeleteAfterDays = 10 #Time Period in Days when older Files will be deleted, only local or Hybrid


$Module = "ALL" #Module Name or ALL
$AutoUpdateLevel = "Patch" #Patch, Minor, Major

#endregion Parameters

#region Function
function Write-TechguyLog {
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        [string]$Text
    )

    #Decide Platform
    $environment = "local"
    if ($env:AZUREPS_HOST_ENVIRONMENT) { $environment = "AAnoHybrid" }
    if ($env:AUTOMATION_WORKER_CERTIFICATE) { $environment = "AAHybrid" }
    
    if ($environment -eq "AAHybrid" -or $environment -eq "local") {
        # Set logging path
        if (!(Test-Path -Path $logPath)) {
            try {
                $null = New-Item -Path $logPath -ItemType Directory
                Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
            }
            catch {
                Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
            }
        }
        else {
            Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
        }
        [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyyMMdd'), $LogfileName
        $logEntry = '{0}: <{1}> {2}' -f $(Get-Date -Format yyyyMMdd_HHmmss), $Type, $Text
        Add-Content -Path $logFile -Value $logEntry
    }
    elseif ($environment -eq "AAHybrid" -or $environment -eq "AAnoHybrid") {
        $logEntry = '{0}: <{1}> {2}' -f $(Get-Date -Format yyyyMMdd_HHmmss), $Type, $Text

        switch ($Type) {
            INFO { Write-Output $logEntry }
            WARNING { Write-Warning $logEntry }
            ERROR { Write-Error $logEntry }
            DEBUG { Write-Output $logEntry }
            Default { Write-Output $logEntry }
        }
    }
}
#endregion Function
Write-TechguyLog -Type INFO -Text "START Script"

$Result = @()

#Get Modules or Modules
if ($Module -eq "ALL") {
    Write-TechguyLog -Type INFO -Text "Get all installed Modules"
    $modules = Get-Module -ListAvailable
}
else {
    Write-TechguyLog -Type INFO -Text "Get single Module: $Module"
    $modules = Get-Module -Name $Module -ListAvailable 
}


#filter Modules from PSGallery
Write-TechguyLog -Type INFO -Text "Limit Module to online Repo"
$GalleryModules = $modules | Where-Object -Property repositorysourcelocation -Value $Null -ne


foreach ($G in $GalleryModules) {
    Write-TechguyLog -Type INFO -Text "Work with Module: $($g.name)"

    Write-TechguyLog -Type INFO -Text "Get Online Repo"
    $o = Find-Module -Name $g.name -Repository PSGallery -ErrorAction Stop
    #compare versions
    Write-TechguyLog -Type INFO -Text "Compare Online and local Version"

    Write-TechguyLog -Type INFO -Text "Installed Version: $($g.version -as [version])"
    Write-TechguyLog -Type INFO -Text "Online Version: $($o.version -as [version])"


    if (($o.version -as [version]) -gt ($g.version -as [version])) {
        Write-TechguyLog -Type INFO -Text "Online Version is newer"
        $UpdateAvailable = $True
        #Determine Major, Minor or Patch

        if (($o.version -as [version]).Major -gt ($g.version -as [version]).Major) {
            Write-TechguyLog -Type INFO -Text "There is a Major Update"
            $UpdateMajority = "Major"   
        }
        elseif (($o.version -as [version]).Minor -gt ($g.version -as [version]).Minor) {
            Write-TechguyLog -Type INFO -Text "There is a Minor Update"
            $UpdateMajority = "Minor"   
        }
        elseif (($o.version -as [version]).Build -gt ($g.version -as [version]).Build) {
            Write-TechguyLog -Type INFO -Text "There is a Patch Update"
            $UpdateMajority = "Patch"   
        }
        else {
            $UpdateMajority = "NONE"
        }
    }
    else {
        Write-TechguyLog -Type INFO -Text "Installed Version is the latest"
        $UpdateAvailable = $False
        $UpdateMajority = "NONE"

    }

    if ($UpdateAvailable -and $UpdateMajority -eq $AutoUpdateLevel) {
        Write-TechguyLog -Type INFO -Text "Update Majority is: $UpdateMajority"
        try {
            Write-TechguyLog -Type INFO -Text "Online Version is newer and Update Majority is configured to update"
            Update-Module -Name $g.Name -Force -AcceptLicense -RequiredVersion $o.Version -Scope AllUsers
            $UpdateResult = "OK"
        }
        catch {
            Write-TechguyLog -Type INFO -Text "Error during PS Module Update, Error: $Error"
            $UpdateResult = "ERROR"
        }

    }
    else {
        $UpdateResult = "NO UPDATE NEEDED"
    }

    $item = New-Object PSObject
    $item | Add-Member -type NoteProperty -Name 'name' -Value $g.name
    $item | Add-Member -type NoteProperty -Name 'local Version' -Value $g.Version
    $item | Add-Member -type NoteProperty -Name 'online Version' -Value $o.Version
    $item | Add-Member -type NoteProperty -Name 'UpdateAvailable' -Value $UpdateAvailable
    $item | Add-Member -type NoteProperty -Name 'Majority' -Value $UpdateMajority
    $item | Add-Member -type NoteProperty -Name 'UpdateResult' -Value $UpdateResult
    $Result += $item
}

$Result

#Clean Logs
if ($environment -eq "AAHybrid" -or $environment -eq "local") {
    Write-TechguyLog -Type INFO -Text "Clean Log Files"
    $limit = (Get-Date).AddDays(-$DeleteAfterDays)
    Get-ChildItem -Path $LogPath -Filter "*$LogfileName.log" | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
}

Write-TechguyLog -Type INFO -Text "END Script"