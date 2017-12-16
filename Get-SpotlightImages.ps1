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
    [string] $PhoneTemp,

    [Parameter()]
    [string] $Rejected,

    [Parameter()]
    [switch] $Sort
)

# Copy over files from spotlight source if they are over 100kb in size
Get-ChildItem $Source | Where-Object { $_.Length -gt 100000 } | Copy-Item -Destination $Destination

$NewPics = Get-ChildItem $Destination
$count = 10
# Cycle through the pics and rename them with the date and a png extension
foreach( $pic in $NewPics ){
    Rename-Item -Path $pic.FullName -NewName "$( Get-Date -Format M.d.yy )-$count.png"; $count++
}

# This sorts out the pics that are vertical for phone backgrounds
#TODO: Check for duplicates on the phoneBgs
if ( $Sort ) {
    # Import tools for getting picture meta data
    . $PSScriptRoot\Get-FileMetaDataReturnObject.ps1

    # Get picture meta data
    $Data = Get-FileMetaData -folder $Destination

    # Move images to apporiate folder based on desktop for phone width
    $Data | Where-Object { $_.Width -match "1080 pixels" } | Move-Item -Destination $PhoneTemp -Force
}

# Get the hash for existing pics and new pics, compare the two and delete the rejects
$BadHash = Get-ChildItem $Rejected | Get-FileHash
$NewHash = Get-ChildItem $Destination | Get-FileHash
$OldHash = Get-ChildItem $BackgroundDir | Get-FileHash

# First compare the new pictures with a list of pictures we don't want, then create a list of new good pictures.
# Then compare the new good pictures with the existing pictures and copy over ones that don't already exsist.
$NewGoodHash = Compare-Object $NewHash $BadHash -Property Hash -PassThru | Where-Object { $_.SideIndicator -eq '<=' }

foreach( $hash in $NewGoodHash ){ 
    Compare-Object $hash.Hash $OldHash -Property Hash -PassThru |
        Where-Object { $_.SideIndicator -eq '<='  } |
            ForEach-Object -Process {
                Copy-Item $_.Path -Destination $BackgroundDir
            }
}

# Clean up temp directory
Get-ChildItem $Destination | Remove-Item -Force
