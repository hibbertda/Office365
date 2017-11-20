<#

https://docs.microsoft.com/en-us/information-protection/deploy-use/log-analyze-usage
#>


Param (
	#Number of days to collect AIP logs (Default: 1)
	[parameter(Position=0, Mandatory=$False)][int]$DaysToSearch = 1
)

Connect-AadrmService

#Download Azure Information Protection Logs
$TempLog_Storage = "C:\Users\dahibber\Desktop\AIPLogs"

#Connect-AadrmService
Get-AadrmUserLog -Path $TempLog_Storage `
    -FromDate (Get-date).AddDays($($DaysToSearch*-1))`
    -Verbose

# Import and consolidate logs
$logfiles = Get-ChildItem -Path $TempLog_Storage -Filter *.log
# Use logparser
$LogParse_AllLogs = "C:\Users\dahibber\Desktop\AIPLogs\AllLogs.csv"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' –i:w3c –o:csv `
    "SELECT * INTO $LogParse_AllLogs FROM $TempLog_Storage\*.log"

$ConsolidatedLogs = Import-Csv -Path $LogParse_AllLogs

#Create Azure SQL Connection
$Hostname = "hbllogs.database.windows.net"
$DBName = "AIPLogs"
$DB_Username = "hibbertda@hbllogs"
$DB_Password = 'darwin212!'
$con = new-object System.data.sqlclient.SQLconnection

$cstr = "Server=tcp:$Hostname;`
    Database=$DBName;`
    User ID=$DB_Username;`
    Password=$DB_Password;`
    Trusted_Connection=False;`
    Encrypt=True;"

$con = new-object system.data.SqlClient.SqlConnection($cstr)
$con.open()

#Query configuration information
$query = "SELECT * FROM Configuration"

$ConfigQuery = $con.CreateCommand()
$ConfigQuery.CommandText = $query

$ConfigResult = $ConfigQuery.ExecuteReader()

$GlobalConfig = New-Object system.data.datatable
$GlobalConfig.load($ConfigResult)

$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.connection = $con

#region Update_RMS_template_infomration 
#Import RMS template information
$RMS_Templates = Get-AadrmTemplate

#INSERT RMS template information
$RMS_Templates | foreach {
        $cmd.commandtext = `
            "INSERT INTO templates (templateid,name,description) `
            VALUES('{0}','{1}','{2}')" -f `
            $_.TemplateId,`
            ($_.Names | ? {$_.key -eq 1033}).value,`
            ($_.Descriptions | ? {$_.Key -eq 1033}).value
        
        $cmd.executenonquery()
    }
#endregion
$ConsolidatedLogs | foreach-object {
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

#delete from YOUR_TABLE where your_date_column < '2009-01-01';
$clean_cmd = New-Object System.Data.SqlClient.SqlCommand
$clean_cmd.connection = $con

$DeleteTime = (Get-Date).AddDays(-15)

$clean_cmd.commandtext = "DELETE from logs WHERE Date < '2017/09/15'"#$DeleteTime"
#$clean_cmd.executenonquery()

#Update configuration
$cmd.commandtext = `
    "INSERT INTO Configuration (lastrun) `
    VALUES('{0}')" -f `
    $(Get-Date)

$cmd.executenonquery()


$con.Close()

#Cleanup logs
Get-childitem $TempLog_Storage | Remove-Item -Confirm:$false



####


