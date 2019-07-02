$ls = Get-Location

Write-Host "Current location: " $ls "`r`n"

$sas = "https://we1dnvglpstgcus0000ep9eh.blob.core.windows.net/foofffffccb804b5-3b55-4392-8d52-dfb02801aa94?sv=2018-03-28&sr=c&sig=tAT2KhdIi39YfduFEx4qo0d%2Fw29PxZ7bYJ1TL0SEziI%3D&st=2019-07-02T07%3A58%3A51Z&se=2019-12-29T08%3A58%3A38Z&sp=rl"
$parse = $sas
$parse.split("{/}")
# Write-Host $parse.GetType()
.\azcopy.exe cp $sas $ls --recursive=true

Read-Host "`r`nPress enter to exit..."
exit