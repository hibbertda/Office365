﻿#region GlobalVariables
# Service account to connect to the service
$ServiceAccount = "EWSimp@hibblabs.org" ## Need Mailbox ##

# Path to EWS managed API
$EWS_DLLPath = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

# Get service account credentials
$credentials = Get-Credential
#endregion

#region ConnectToExchangeOnline
# Connect to Exchange
<#
    A connection to Exchange Online is needed to get a list of all user
    mailboxes to search.
#>
#$EXO_Session = New-PSSession -ConfigurationName Microsoft.Exchange `
#    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
#    -Credential ($credentials) `
#    -Authentication Basic `
#    -AllowRedirection `
#    -ErrorAction Stop

#Import-PSSession $EXO_Session -ErrorAction Stop | Out-Null

#endregion

# Set impresonation
# MSDN: how to configure impersonation
# https://msdn.microsoft.com/en-us/library/office/dn722376(v=exchg.150).aspx

#New-ManagementRoleAssignment –name:ImpersonateEWS –Role:ApplicationImpersonation –User:$ServiceAccount

# Get all mailboxes (exclude DiscoveryMailbox)
$Mailboxes = Get-mailbox | ? {$_.RecipientTypeDetails -ne "DiscoveryMailbox"}

# Import EWS managed API
if ((test-path -Path $EWS_DLLPath) -eq $False){
    Write-host -ForegroundColor red "Unable to find EWS Managed API 2.2"
    exit
}
else {Import-Module $EWS_DLLPath}

# Create connetction to EWS
$creds = New-Object System.Net.NetworkCredential($credentials.UserName.ToString(),$credentials.GetNetworkCredential().password.ToString())

Measure-Command {
$Service = [Microsoft.Exchange.WebServices.Data.ExchangeService]::new()
$Service.Credentials = $creds
$service.AutodiscoverUrl($credentials.UserName.ToString(), {$true})


$Mailboxes | Foreach-object {

    $service.ImpersonatedUserId = `
        New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$_.PrimarySmtpAddress );

    # Bind to the Inbox folder
    $AttachmentTrueQuery = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::HasAttachments, $true)
    $dateTimeItem = [Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived
    $DateRange = (Get-Date).AddDays(-1)
    $TimeFrameQuery = New-Object -TypeName Microsoft.Exchange.WebServices.Data.SearchFilter+IsgreaterThanOrEqualTo -ArgumentList $dateTimeItem,$DateRange
    $folderid= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)   
    $Inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$folderid)

    # Create Search Collection and Add Search Criteria
    $SearchCollection = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::And)
    $SearchCollection.Add($AttachmentTrueQuery)
    $SearchCollection.add($TimeFrameQuery)
    
    # Testing Loop
    Write-host -ForegroundColor Green "Mailbox: $($_.Name)"
    Write-host -ForegroundColor white "Total Email: $($Inbox.TotalCount)"
    Write-host -ForegroundColor white "Unread Email: $($Inbox.UnreadCount)"

    $ivItemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10 #(100)
    #$findItemsResults = $Inbox.FindItems($AttachmentTrueQuery,$ivItemView)
    $findItemsResults = $Inbox.FindItems($SearchCollection,$ivItemView)

    $RunResult = @()

    foreach($miMailItems in $findItemsResults.Items){
        $miMailItems.Load()
        foreach($attach in $miMailItems.Attachments){
            $attach.Load()   

            $obj = New-Object psobject -Property @{
                Senders = $miMailItems.Sender
                AttachmentName = $attach.name.tostring()
                Received = $miMailItems.DateTimeReceived
                "AttachmentSize(kb)" = [math]::round(($attach.Size / 1024),2)
                Type = $attach.ContentType
                Recivedby = $miMailItems.ReceivedBy

            }

            $RunResult += $obj
        }
    }
  
    $RunResult

    Write-Host -ForegroundColor white "Attachements recevind in last 24 hours: $($findItemsResults.TotalCount)"

}
}