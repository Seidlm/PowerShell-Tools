$Module = "ALL" #Module Name or ALL


$Result = @()

#Get Modules or Modules

if ($Module -eq "ALL") {

    $modules = Get-Module -ListAvailable
}
else {
    $modules = Get-Module -Name $Module -ListAvailable 
}


#filter Modules from PSGallery

$GalleryModules = $modules | Where-Object -Property repositorysourcelocation -Value $Null -ne


foreach ($G in $GalleryModules) {

    $o = Find-Module -Name $g.name -Repository PSGallery -ErrorAction Stop
    #compare versions
    if (($o.version -as [version]) -gt ($g.version -as [version])) {
        $UpdateAvailable = $True
        #Determine Major, Minor or Patch

        if ($o.version.Major -gt $g.version.Major) {
            $UpdateMajority = "Major"   
        }
        elseif ($o.version.Minor -gt $g.version.Minor) {
            $UpdateMajority = "Minor"   
        }
        elseif ($o.version.Build -gt $g.version.Build) {
            $UpdateMajority = "Patch"   
        }
        else {
            $UpdateMajority = "NONE"
        }
    }
    else {
        $UpdateAvailable = $False
        $UpdateMajority = "NONE"

    }

    $item = New-Object PSObject
    $item | Add-Member -type NoteProperty -Name 'name' -Value $g.name
    $item | Add-Member -type NoteProperty -Name 'local Version' -Value $g.Version
    $item | Add-Member -type NoteProperty -Name 'online Version' -Value $o.Version
    $item | Add-Member -type NoteProperty -Name 'UpdateAvailable' -Value $UpdateAvailable
    $item | Add-Member -type NoteProperty -Name 'Majority' -Value $UpdateMajority
    $Result += $item

}

$Result