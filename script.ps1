function getAzcopy {
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

$ls = Get-Location
Write-Host "`r`nCurrent location: " $ls "`r`n"

getAzcopy $ls

$sas = "https://we1dnvglpstgcus0000ep9eh.blob.core.windows.net/foofffffccb804b5-3b55-4392-8d52-dfb02801aa94/someDir?sv=2018-03-28&sr=c&sig=tAT2KhdIi39YfduFEx4qo0d%2Fw29PxZ7bYJ1TL0SEziI%3D&st=2019-07-02T07%3A58%3A51Z&se=2019-12-29T08%3A58%3A38Z&sp=rl"

$temp = $sas
$temp = $temp.split("{?}")[0]

$regex = "https://(.+)$"
$temp -match $regex | Out-Null
$temp = $matches[1]

$regex2 = ".+?/(.+/?)+"
$temp -match $regex2 | Out-Null

$azurePath = $matches[1]
Write-Host "Azure Path: " $azurePath "`r`n"
$guidLength = 36
$containerName = ""
$downloadName = ""
if ($azurePath.Contains("/")) {
    $splitted = $azurePath.split("{/}")
    $containerName = $splitted[0].Substring(0, $splitted[0].Length - $guidLength)
    for ($i = 1; $i -lt $splitted.Count; $i++) {
        $containerName += "/" + $splitted[$i]
    }
    $downloadName = $splitted[$splitted.Count - 1]
    Write-Host $containerName
}
else{
    $containerName = $azurePath.Substring(0, $azurePath.Length - $guidLength)
    $downloadName = $azurePath
    Write-Host $containerName

}

.\azcopy.exe cp $sas $ls --recursive=true
#  Rename-Item "$ls/$downloadName" "/$ls/$containerName"
$downloadPath = "$ls\$downloadName"
$containerPath = "$ls\$containerName"
Rename-Item -path $downloadPath -newName $containerPath

Remove-Item "azcopy.exe"

Read-Host "`r`nPress enter to exit..."
exit