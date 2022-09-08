# Register an explorer.exe context menu option to package intunewin packages.
# V. Klopfenstein - September 2022

Param(
	[switch] $UseAlternateFilePath,
	[string] $InstallationTarget = "C:\Support"
)

$baseReg = "HKCR:\Directory\Background\shell\"

# Trim last character from $IntallationTarget if it's a \
if ($InstallationTarget[-1] -eq '\') {
	$InstallationTarget = $InstallationTarget.substring(0, $InstallationTarget.length -1)
}

try {
	# Check if is elevated
	$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if (!($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
		throw "Script not elevated."
	}
	
	Write-Host "[i] Files will be installed into '$InstallationTarget'" -f cyan
	
    # Install data
    if (!(Test-Path $InstallationTarget)) {
        Write-host "Creating $InstallationTarget..." -f yellow
        mkdir $InstallationTarget | out-null
    }

    <# Unzip shit
		Write-Host "Extracting data to $InstallationTarget..." -f yellow
		Expand-Archive .\data.zip $InstallationTarget -Force | out-null
	#>
	
	# Verify contents of data dir, copy afterwards
	if (Test-Path .\data) {
		@("contextIcon.ico", "contextScript.ps1") | % {
			if (!(Test-path ".\data\$($_)")) {
				throw "Did not find required file '$($_)' in data dir."
			} else {
				$temp = Copy-item ".\data\$($_)" $InstallationTarget -Force | out-null
			}
		}
	} else {
		throw "Data dir not found in location."
	}
	
	
	# Add $InstallationTarget to contextScript.ps1
	$target = "$InstallationTarget\contextScript.ps1"
    Write-Host "Adjusting '$target'..." -f yellow
	$t = (Get-Content "$target") -replace "%REPLACEME%", "$InstallationTarget\IntuneWinAppUtil.exe"
	$t | Out-File $target -Encoding UTF8

    Write-Host "Mapping HKCR..." -f yellow
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | out-null

    Write-Host "Creating reg keys..." -f yellow
	if (!(Test-Path "$baseReg\IntuneCreation")) {
		New-Item $baseReg -name "IntuneCreation" | out-null
	}
	if (!(Test-Path "$baseReg\IntuneCreation\command")) {
		New-Item "$baseReg\IntuneCreation" -name "command" | out-null
	}

    # Transform $InstallationTarget so that backslashes get properly escaped in CMD
    $InstallationTarget = $InstallationTarget -replace [regex]::escape('\'), [regex]::escape('\')
    
    Write-Host "Setting properties..." -f yellow
    Write-Host "> NOTE: If powershell suddendly exits, launch this script with -UseAlternateFilePath." -f yellow
	if ($UseAlternateFilePath.IsPresent) {
		$fileVar = "\`"${InstallationTarget}\\contextScript.ps1\`""
	} else {
		$fileVar = "`"${InstallationTarget}\\contextScript.ps1`""
	}
	
    Set-ItemProperty "$baseReg\IntuneCreation" -name "(Default)" -value "Create intunewin package"
    Set-ItemProperty "$baseReg\IntuneCreation" -name "Icon" -value "$InstallationTarget\contextIcon.ico"
    Set-ItemProperty "$baseReg\IntuneCreation\command" -name "(Default)" -value "powershell.exe -noprofile -executionpolicy bypass -command $fileVar -path '%V'"

    Write-Host "All done" -f green
} catch {
    Write-Host "Error encountered: $_" -f red
}