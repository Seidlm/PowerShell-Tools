$clientID = "your-ClientID"
$Clientsecret = "your-Secret"
$tenantID = "your-TenantID"

$BaseURL="https://graph.microsoft.com/v1.0"

$UserUPN="michael.seidl@au2mator.com"
$MailArray=@()




#Connect to GRAPH API
$tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $clientId
    Client_Secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody
$headers = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-type"  = "application/json"
}

$URLReadFolder="$BaseURL/users/$UserUPN/mailFolders"
$Inboxfolder=(Invoke-RestMethod -Method GET -Uri $URLReadFolder -Headers $headers).value | Where-Object -Property displayname -Value Inbox -eq

$URLReadMail="$BaseURL/users/$UserUPN/mailFolders/$($Inboxfolder.id)/messages?`$filter=startswith(Subject,'au2mator - Self Service Portal')"
$Mails=Invoke-RestMethod -Method GET -Uri $URLReadMail -Headers $headers

foreach ($M in $Mails.value)
{
    $Mailarray+=$M.body.content.substring(0,$M.body.content.IndexOf(")")+1).replace("From: ","")
}
""
""
""
"The Comic Winners are:"
""
$Comicwinners=$MailArray | Get-Random -Count 3
$Comicwinners
""
""
""


$MailArray = $MailArray |Where-Object { $Comicwinners -notcontains $_ }
#$MailArray.count
$BaseCapWinners=$MailArray | Get-Random -Count 3
""
""
""
"The BaseCap Winners are:"
""
$BaseCapWinners
""
""
""