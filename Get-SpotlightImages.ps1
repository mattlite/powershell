# Script that copies and renames windows spotlight images

[CmdletBinding()]
param
(
	[Parameter()]
    [string] $Source = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets",
    
    [Parameter()]
    [string] $Destination,

    [Parameter()]
    [string] $BackgroundDir,

    [Parameter()]
    [string] $BgTemp,

    [Parameter()]
    [string] $PhoneTemp,

    [Parameter()]
    [switch] $Sort
)

# Copy over files from spotlight source if they are over 100kb in size
Get-ChildItem $Source | Where-Object { $_.Length -gt 100000 } | Copy-Item -Destination $Destination
$NewPics = Get-ChildItem $Destination
$count = 0 

# Cycle through the pics and rename them with the date and a png extension
foreach( $pic in $NewPics ){
    Rename-Item -Path $pic.FullName -NewName "$( Get-Date -Format M.d.yy )-$count.png"; $count++
}

if ( $Sort ) {
    # Import tools for getting picture meta data
    . $PSScriptRoot\Get-FileMetaDataReturnObject.ps1

    # Get picture meta data
    $Data = Get-FileMetaData -folder $Destination

    # Move images to apporiate folder based on desktop for phone width
    $Data | Where-Object { $_.Width -match "1920 pixels" } | Move-Item -Destination $BgTemp
    $Data | Where-Object { $_.Width -match "1080 pixels" } | Move-Item -Destination $PhoneTemp
}
