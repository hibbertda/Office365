<#

https://docs.microsoft.com/en-us/information-protection/deploy-use/log-analyze-usage
#>


Param (
	#Number of days to collect AIP logs (Default: 1)
    [parameter(Position=0, Mandatory=$False)][int]$DaysToSearch = 20,
    [parameter(Position=0, Mandatory=$False)][string]$Logstorage = "C:\Users\Daniel\Desktop\AIP_logs"
)

#Download Azure Information Protection Logs
$TempLog_Storage = $Logstorage

#Connect-AadrmService
Get-AadrmUserLog -Path $TempLog_Storage -FromDate (Get-date).AddDays($($DaysToSearch*-1))

# Import and consolidate logs
$logpath = $Logstorage
$logfiles = Get-ChildItem -Path $logpath -Filter *.log

# Use logparser
$LogParse_AllLogs = $Logstorage+"\AllLogs.csv"

$originalworkingdir = $PWD

cd "C:\Program Files (x86)\Log Parser 2.2"
.\LogParser.exe –i:w3c –o:csv "SELECT * INTO $LogParse_AllLogs FROM C:\Users\Daniel\Desktop\AIP_logs\*.log"

$ConsolidatedLogs = Import-Csv -Path $LogParse_AllLogs

#Create SQL Connection
$Hostname = "localhost"
$DBName = "AIP_Logs"
$con = new-object "System.data.sqlclient.SQLconnection"

#Set Connection String
$con.ConnectionString =(“Data Source=$Hostname;Initial Catalog=$DBName;Integrated Security=SSPI”)
$con.open()

$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.connection = $con

$ConsolidatedLogs | foreach {

    #$ClientInfo = $_."c-info".split(';')

    $ClientInfo = New-Object psobject -Property @{
        OS = ($_."c-info".split(';') | ? {$_ -like "OSName*"}).Split('=')[1]
        OSVersion = ($_."c-info".split(';') | ? {$_ -like "OSVer*"}).Split('=')[1]
    }
    if ($_."content-id".count -ne 1){$contentid = $_."content-id".replace('{','').replace('}','')}
    else {$contentid = ""}

    #try{
    $cmd.commandtext = `
        "INSERT INTO logs (date,time,rowid,requesttype,result,templateid,contentid,clientip,userid,correlationid,OS,OSversion) `
        VALUES('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}')" -f `
        $_.date,`
        $_.time,`
        $_."row-id",`
        $_."request-type",`
        $_.result.Replace("'",""),`
        $_."template-id".replace('{','').replace('}',''),`
        $contentid,`
        $_."c-ip",`
        $_."user-id".replace("'",""),
        $_."correlation-id",`
        $ClientInfo.OS,
        $ClientInfo.OSVersion
    
    $cmd.executenonquery()
    #}
    #catch { Write-host "duplicate value" }
}

#$cmd.executenonquery()

#delete from YOUR_TABLE where your_date_column < '2009-01-01';
$clean_cmd = New-Object System.Data.SqlClient.SqlCommand
$clean_cmd.connection = $con

$DeleteTime = (Get-Date).AddDays(-15)

$clean_cmd.commandtext = "DELETE from logs WHERE Date < '2017/09/15'"#$DeleteTime"
#$clean_cmd.executenonquery()

$con.Close()

#Cleanup logs
Get-childitem $TempLog_Storage | Remove-Item -Confirm:$false

# retrun back to original working directory
cd $originalworkingdir