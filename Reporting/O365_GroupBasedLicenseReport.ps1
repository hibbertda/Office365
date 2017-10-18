Connect-MsolService

#region TenantLicenses
$TenantLicenses = Get-MsolAccountSku | foreach {
    
    New-Object Object |
        Add-Member -NotePropertyName LicenseName -NotePropertyValue $_.Skupartnumber -PassThru |
        Add-Member -NotePropertyName ActiveUsers -NotePropertyValue $_.activeUnits -PassThru |
        Add-Member -NotePropertyName ConsumedUnits -NotePropertyValue $_.consumedunits -PassThru |
        Add-Member -NotePropertyName ServicePlans -NotePropertyValue ([string]$_.ServiceStatus.serviceplan.servicename).replace(' ',', ') -PassThru

}

$TenantLicenses | export-csv -NoTypeInformation -Path ~\Desktop\TenantLic.csv
#endregion

#region GroupBaseLicensing
$licenseGroups = Get-MsolGroup -HasLicenseErrorsOnly:$False | Where-Object {$_.Licenses}
$licenseGroups_errors = Get-MsolGroup -HasLicenseErrorsOnly:$True | Where-Object {$_.Licenses}

$Process_groups = $licenseGroups | foreach {
    $GroupMembers = Get-MSOLGroupMember -GroupObjectId $_.ObjectId -All 
    if ($_.LastDirSyncTime -eq $null){$GroupSync = "Cloud"}
    Else {$GroupSync = "Synced"}

    New-object Object |
        Add-Member -NotePropertyName GroupName -NotePropertyValue $_.DisplayName -PassThru |
        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $_.Description -PassThru |
        Add-Member -NotePropertyName AssignedLicenses -NotePropertyValue $(([string]($_.Licenses | Select -ExpandProperty SkuPartNumber)).replace(' ',', ')) -PassThru | 
        Add-Member -NotePropertyName UserCount -NotePropertyValue $GroupMembers.count -PassThru | 
        Add-Member -NotePropertyName GroupMembers -NotePropertyValue $(([string]($GroupMembers).EmailAddress).replace(' ',', ')) -PassThru | 
        Add-Member -NotePropertyName GroupType -NotePropertyValue $_.GroupType -PassThru | 
        Add-Member -NotePropertyName Synced -NotePropertyValue $GroupSync -PassThru
}

$Process_groups | export-csv -NoTypeInformation -Path ~\Desktop\GroupBaseLicensereport.csv
#endregion