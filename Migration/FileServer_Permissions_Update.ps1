
Param (
    [parameter(Position=0, Mandatory=$False)][String]$RootDirectory = "./",
	[parameter(Position=1, Mandatory=$True)][String]$AccountToAdd = "",
    [parameter(Position=2, Mandatory=$False)][String]$TBA
)

$RootFolderList = Get-Childitem -Path $RootDirectory -Directory
$Iteration = 1 
$RootFolderListCount = $RootFolderList.count
$PermUpdate = New-Object System.Security.AccessControl.FileSystemAccessRule($AccounttoAdd,"FullControl","Allow")

foreach ($folder in $RootFolderList){

    Write-Progress -Activity "Changing Permissions" -Status "Current Directory: [$($Iteration) of $($RootFolderList.count)] - $($Folder.fullname)" -PercentComplete (($iteration / ($RootFolderListCount + 1))*100) -Id 1
    $Folder_ACL = Get-ACL $Folder.FullName

    $Orig_Owner = New-Object Security.Principal.NTAccount($Folder_ACL.Owner)

    # Take ownership of folders and files in the directory 
    Write-Progress -Activity "Taking Ownership of all Files and Directories" -Id 2 -ParentId 1
    takeown.exe /f $folder.FullName /r /d:Y | Out-Null
    sleep 2
    Write-Progress -Activity "Taking Ownership of all Files and Directories" -id 2 -Completed

    Write-Progress -Activity "Finding all files" -Id 2 -ParentId 1
    $Folder_recurse = Get-ChildItem -Recurse -Path $Folder.Fullname
    sleep 1
    Write-Progress -Activity "Finding all files" -Id 2 -Completed 

    $PermIteration = 1
    $Folder_recurseCount = $Folder_recurse.count
    foreach ($Folder_Perm in $Folder_recurse){
        
        Write-Progress -Activity "Reverting NTFS Owners" -Status "Current Object: [$($PermIteration) of $($Folder_recurseCount)] - $($Folder_Perm.fullname)" -PercentComplete (($Permiteration / ($Folder_recurseCount + 1))*100) -Id 3 -ParentId 1
        $Folder_ACL.SetAccessRule($PermUpdate)
        $Folder_ACL.SetOwner($Orig_Owner)
        Set-ACL $Folder_Perm.fullname -AclObject $Folder_ACL
        sleep 1
        Write-Progress -Activity "Reverting NTFS Owners" -id 3 -Completed 
    
        $PermIteration++
    }
    Start-Sleep 2
    $Iteration++
}