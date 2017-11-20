Param (
    [parameter(position=1, mandatory=$false)][int]$ObjectPerRun = 20,
    [parameter(position=2, mandatory=$false)][int]$MaxThreads = 3,
    [parameter(position=3, mandatory=$false)][Switch]$HideExcel = $true,
    [paremeter(position=0, mandatory=$true)][String]$ADForest = "DC=hbl,DC=hibblabs,DC=org"
)

#region Global_Variables
$CurrentDate = Get-Date
#if ($PSBoundParameters["Debug"]){$DebugPreference="Continue"}
$DebugPreference="Continue"
#endregion

# Import Active Usage report
Write-Debug -Message "Importing Office 365 Usage Report"
$O365_ActiveUserReport = Import-CSV -path 'C:\Users\HibbertDA\downloads\ActiveUser10_17_2017 11_59_46 AM.csv'

# Find any usage of OneDrive of SharePoint Online in the last 30 days
Write-Debug -Message "Processing active users in last 30 days"
$30ProcessTime = Measure-Command {
    $DateRange = ($CurrentDate.adddays(-29))
    $ActiveUsers_raw = ($O365_ActiveUserReport | Where-Object {`
            $_."Last Activity Date For SharePoint" -gt $DateRange `
        -or $_."Last Activity Date For OneDrive" -gt $DateRange `
        -or $_."Last Activity Date For Exchange" -gt $DateRange})
}
Write-Debug -Message "Processing active users took [$($30ProcessTime.Seconds)] seconds"

#region UserLookUp
$TotalCount = $ActiveUsers_raw.count
Write-Debug "Found [$TotalCount] active users"

# Run Space Pool
[int]$ittr_start = 0 
[int]$ittr_end = $ittr_start+$ObjectPerRun
[int]$RunNumber = 1

$RunSpacePool = [RunspaceFactory]::CreateRunspacePool(1,$MaxThreads)
$RunSpacePool.Open()

# Runspace Script Block
$ScriptBlock = {
param (
    [int]$RunNumber,
    $list
    )  
    $RunResults = @()

    $dom = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

    $objsearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objsearcher.SearchRoot.distinguishedName = $ADForest
    $objsearcher.SearchRoot.Path = $("GC://"+$ADForest)
    $objsearcher.PageSize = 1000
    $objsearcher.Filter = $searchFilter
    $objsearcher.SearchScope = "subtree"

    $List | Where-Object {$_."User principal name" -notlike "*.onmicrosoft.com"} | foreach {
        # Update search filter
        $searchFilter = "(userprincipalname=$($_."User principal name"))" 
        $objsearcher.Filter = $searchFilter
    
        # Run search 
        $fe_Temp = $objsearcher.FindAll()

        $obj = New-Object psobject -Property @{
               Firstname = [string]($fe_temp.properties.givenname)
               LastName = [string]($fe_temp.properties.sn)
               Department = [string]($fe_temp.Properties.department)
               City = [string]($fe_temp.properties.l)
               Office = [string]($fe_temp.properties.office)
               Country = [string]($fe_temp.properties.c)
            "User Principal Name" = $_."User Principal name"
            DisplayName = $_.DisplayName
            "Email Address" = [string]($fe_temp.properties.mail)
        }
        $RunResults += $obj
    }
    Return $RunResults
}
# Run Space Script Block
$jobs = @()
# Add / Start Jobs
$JobProcessingTime = Measure-Command {
do {
    Write-Debug -Message "Creating Job: $RunNumber - $($ActiveUsers_raw[$ittr_start..$ittr_end].count) Objects"
    $RunGroup = $ActiveUsers_raw[$ittr_start..$ittr_end]   
    $job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($RunNumber).AddArgument($RunGroup)
    $job.RunSpacePool = $RunSpacePool
    $jobs += New-Object PSObject -Property @{
        Pipe = $job
        Results = $job.BeginInvoke()
    }
    $ittr_start = $ittr_end+1
    $ittr_end = $ittr_start+$ObjectPerRun
    $RunNumber++
}
## DEBUG
While ($ittr_start -lt $ActiveUsers_raw.count)
#While ($ittr_start -gt $ActiveUsers_raw.count)

# Wait for Jobs to complete
Do {
    $Inprogress_jobs = ($jobs.Results | ? {$_.IsCompleted -eq $False}).count
    $Completed_jobs = ($jobs.Results | ? {$_.IsCompleted -eq $True}).count

    Write-Progress -Activity "Collecting User Detail" -Id 1 `
        -Status "$Inprogress_jobs in progress | $Completed_jobs jobs completed" `
        -PercentComplete ($Completed_jobs/$jobs.count*100)
    Start-Sleep -Seconds 1   
}
While ($jobs.Results.IsCompleted -contains $False)
Write-Progress -Activity "Collecting User Detail" -Id 1 -Completed 

# Collect job results
$ActiveUsers_Processed = @()
foreach ($CompletedJob in $jobs){$ActiveUsers_Processed += $CompletedJob.pipe.endinvoke($CompletedJob.results)}
Write-Debug -Message "Processed [$($ActiveUsers_Processed.count)] objects"
}
Write-Debug -Message "User object processing compelted in $($JobProcessingTime.Minutes) minutes"
#endregion

#region Total_users
$TotalUsers_Source = Import-Csv -Path "H:\TotalO365Users_Processed.csv"
$TotalUsers_Add = $TotalUsers_Source + $($ActiveUsers_Processed | Select-Object "Email Address", @{Expression={$_.DisplayName};L="Name"} )

# Find duplicates
($TotalUsers_Add | group -Property "Email Address" | ? {$_.count -gt 1}).count

# Export unique based on "Email Address"
$TotalUsers_Processed = $TotalUsers_Add | Sort-Object -Unique "Email Address"
#endregion

#region Create_Excel
# Create Execl doc
$Excel = New-Object -ComObject excel.application
$Excel.Visible = $HideExcel

#Add workbook
$Workbook = $excel.Workbooks.add()

#Add worksheet
$Excel.Worksheets.add()
$Excel.Worksheets.add()

#region Populate_ActiveUsers
$ActiveUserWorksheet = $Excel.Worksheets.Item(1)
$ActiveUserWorksheet.name = "Active Users"

$ActiveUserWorksheet.cells.Item(1,1) = "User Principal Name"
$ActiveUserWorksheet.cells.Item(1,2) = "DisplayName"
$ActiveUserWorksheet.cells.Item(1,3) = "FistName"
$ActiveUserWorksheet.cells.Item(1,4) = "LastName"
$ActiveUserWorksheet.cells.Item(1,5) = "Office"
$ActiveUserWorksheet.cells.Item(1,6) = "Department"
$ActiveUserWorksheet.cells.Item(1,7) = "City"
$ActiveUserWorksheet.cells.Item(1,8) = "Country"

$row = 2
$ActiveUsers_Processed | Foreach {
    $ActiveUserWorksheet.cells.Item($row,1) = $_."User principal name"
    $ActiveUserWorksheet.cells.Item($row,2) = $_."DisplayName"
    $ActiveUserWorksheet.cells.Item($row,3) = $_."FistName"
    $ActiveUserWorksheet.cells.Item($row,4) = $_."LastName"
    $ActiveUserWorksheet.cells.Item($row,5) = $_."Office"
    $ActiveUserWorksheet.cells.Item($row,6) = $_."Department"
    $ActiveUserWorksheet.cells.Item($row,7) = $_."City"
    $ActiveUserWorksheet.cells.Item($row,8) = $_."Country"
    $row++
}
#endregion
#region Populate_TotalUsers
$TotalUserWorksheet = $Excel.Worksheets.Item(2)
$TotalUserWorksheet.name = "Total Users"
$TotalUserWorksheet.cells.Item(1,1) = "Name"
$TotalUserWorksheet.cells.Item(1,2) = "Email Address"

$row = 2
$TotalUsers_Processed | Foreach {
    $TotalUserWorksheet.cells.Item($row,1) = $_.Name
    $TotalUserWorksheet.cells.Item($row,2) = $_."Email Address"
    $row++
}
#endregion
#region History
$HistorySheet = $Excel.Worksheets.Item(3)

$HistorySheet.name = "ReportTotals"
$HistorySheet.cells.Item(1,1) = "Date"
$HistorySheet.cells.Item(1,2) = "ActiveUsers"
$HistorySheet.cells.Item(1,3) = "TotalUsers"

## NEED TO ADD DATA ##
#endregion
# Convert worksheets to Excel Tables
$TotalUserWorksheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $TotalUserWorksheet.cells.CurrentRegion, $null ,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
$ActiveUserWorksheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $ActiveUserWorksheet.cells.CurrentRegion, $null ,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
$HistorySheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $HistorySheet.cells.CurrentRegion, $null ,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)

# Save Excel Doc
$Save_FileName = "Office365Users_$($CurrentDate.month)$($CurrentDate.day)$($CurrentDate.Year)_$(Get-Random)_.xlsx"
$Save_Path = "H:\$Save_FileName"
Write-Debug -Message "Saving Excel doc: $Save_Path"
$Workbook.SaveAs($Save_Path)

#endregion
