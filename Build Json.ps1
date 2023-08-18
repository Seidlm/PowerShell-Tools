#Simple JSON
[hashtable]$body = @{}
$Body.givenName = "Michael"
$Body.surname = "Seidl"
$Body.fileAs = "Michael Seidl"


$Json = $body | ConvertTo-Json
$Json




#String Array JSON
[hashtable]$body = @{}
$Body.givenName = "Michael"
$Body.surname = "Seidl"
$Body.fileAs = "Michael Seidl"
$Body.businessPhones = @(
                "0664 1234567"
            )

$Json = $body | ConvertTo-Json
$Json









#Complex Array JSON
[hashtable]$body = @{}
$Body.givenName = "Michael"
$Body.surname = "Seidl"
$Body.fileAs = "Michael Seidl"
$Body.emailAddresses = @([ordered]@{
    address = "michael.seidl@au2mator.com"; name = "Michael Seidl"
})

$Json = $body | ConvertTo-Json
$Json



#Batch Request JSON
$i=0
[hashtable]$Array = @{}

foreach ($User in $Users) #This is an example Array with no data
{
    $i++

    [hashtable]$body = @{}
    $Body.givenName = "$($User.gn)"
    $Body.surname = "$($User.sn)"
    $Body.fileAs = "$($User.gn) $($User.sn)"
    
    $Array.requests += @([ordered]@{ 
        id      = "$i";
        method  = "POST"
        url     = "/url/"
        body    = $Body
        headers = @{"Content-Type" = "application/json; charset=utf-8" }
    })
    
}


$BatchJson = $Array | ConvertTo-Json -Depth 10
$BatchJson 