function Get-Azcopy {
    param([string]$currentPath)

    if (Test-Path "azcopyv10.zip" -PathType Leaf) {
        Remove-Item azcopyv10.zip
    }
    Invoke-WebRequest https://azcopyvnext.azureedge.net/release20190517/azcopy_windows_amd64_10.1.2.zip -OutFile azcopyv10.zip
    
    if (Test-Path "azcopy_windows_amd64_10.1.2" -PathType Leaf) {
        Remove-Item azcopy_windows_amd64_10.1.2
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("azcopyv10.zip", $currentPath)
    Remove-Item azcopyv10.zip
    
    if (Test-Path "azcopy.exe" -PathType Leaf) {
        Remove-Item "azcopy.exe"
    }
    Copy-Item -Path "azcopy_windows_amd64_10.1.2/azcopy.exe" -Destination "." 
    Remove-Item "azcopy_windows_amd64_10.1.2" -Recurse    
}

function Get-Folder {
    param ($initalFolder)

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $folderBrowserdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserdialog.Description = "Select a folder to download your container"
    $folderBrowserdialog.rootfolder = "MyComputer"
    $result = $folderBrowserdialog.ShowDialog(
        (New-Object System.Windows.Forms.Form -Property @{ TopMost = $true })
    )
    $folder = $initalFolder
    if ($result -eq "OK") {
        Write-Host $folderBrowserdialog.SelectedPath
        $folder = $folderBrowserdialog.SelectedPath
    }
    return $folder
}

function Get-Azure-Path-From-SAS {
    param ([string]$sasKey)

    $temp = $sasKey
    $temp = $temp.split("{?}")[0]

    $regexRemoveHttp = "https://(.+)$"
    $temp -match $regexRemoveHttp | Out-Null
    $temp = $matches[1]

    $regexParsePath = ".+?/(.+/?)+"
    $temp -match $regexParsePath | Out-Null
    $azurePath = $matches[1]

    return $azurePath
}

function Get-Folder-Name-From-Azure-Path {
    param ([string]$azurePath, [int]$guidLength)
    
    $containerName = ""
    if ($azurePath.Contains("/")) {
        $splitted = $azurePath.split("{/}")
        $containerName = $splitted[0].Substring(0, $splitted[0].Length - $guidLength)
        for ($i = 1; $i -lt $splitted.Count; $i++) {
            $containerName += "-" + $splitted[$i]
        }
    }
    else {
        $containerName = $azurePath.Substring(0, $azurePath.Length - $guidLength)
    }
    return $containerName
}

function Get-Download-Name-From-Azure-Path {
    param ([string]$azurePath)
    $downloadName = $azurePath
    if ($azurePath.Contains("/")) {
        $splitted = $azurePath.split("{/}")
        $downloadName = $splitted[$splitted.Count - 1]
    }
    return $downloadName
}


######################################
# Script start
$currentLocation = Get-Location
Write-Host "`r`n Script running at: " $currentLocation "`r`n"

Write-Host "The script will download your countainer to $currentLocation"
Write-Host "Do you want to use another another location?"
$userSelectDownloadLocation = Read-Host "Y for yes    N for no"

while ((-not $userSelectDownloadLocation.equals("Y")) -and (-not $userSelectDownloadLocation.equals("y")) -and (-not $userSelectDownloadLocation.equals("N")) -and (-not $userSelectDownloadLocation.equals("n"))) {
    Write-Host "Your answered $userSelectDownloadLocation"
    $userSelectDownloadLocation = Read-Host "Y for yes    N for no"
}

$downloadFolder = $currentLocation
if ($userSelectDownloadLocation.equals("Y") -or $userSelectDownloadLocation.equals("y")) {
    $downloadFolder = Get-Folder $currentLocation
}

Write-Host "Downloading to " $downloadFolder
Get-Azcopy $currentLocation

$sas = "https://we1dnvglpstgcus0000ep9eh.blob.core.windows.net/foofffffccb804b5-3b55-4392-8d52-dfb02801aa94/someDir?sv=2018-03-28&sr=c&sig=tAT2KhdIi39YfduFEx4qo0d%2Fw29PxZ7bYJ1TL0SEziI%3D&st=2019-07-02T07%3A58%3A51Z&se=2019-12-29T08%3A58%3A38Z&sp=rl"

$azurePath = Get-Azure-Path-From-SAS $sas
Write-Host "Azure Path: " $azurePath "`r`n"

$guidLength = 36
$containerName = Get-Folder-Name-From-Azure-Path $azurePath $guidLength
$downloadName = Get-Download-Name-From-Azure-Path $azurePath

# Run azcopy
.\azcopy.exe cp $sas $downloadFolder --recursive=true

$downloadPath = "$downloadFolder\$downloadName"
$containerPath = "$downloadFolder\$containerName"
Write-Host "Renaming $downloadPath to $containerPath"
Rename-Item -path $downloadPath -newName $containerPath

Remove-Item "azcopy.exe"

Read-Host "`r`nPress enter to exit..."
exit