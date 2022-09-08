# Register a filex explorer context menu entry for a FOLDER.
# V. Klopfenstein - September 2022

Param(
	[switch] $UseAlternateFilePath
)

$baseReg = "HKCR:\Directory\Background\shell\"
$installationSource = "C:\Support"
# IMPORTANT: DO NOT ADD A \ TO THE END OF THE PATH

try {
	# Check if is elevated
	$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if (!($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
		throw "Script not elevated."
	}
	
	Write-Host "[i] Files will be installed to '$installationSource'" -f cyan
	if ((Read-Host "Continue? (y/N)") -ne "y") {
		throw "User has aborted the installation."
	}
	
    # Install data
    if (!(Test-Path $installationSource)) {
        Write-host "Creating $installationSource..." -f yellow
        mkdir $installationSource | out-null
    }

    # Unzip shit
    Write-Host "Extracting data to $installationSource..." -f yellow
    Expand-Archive .\data.zip $installationSource -Force | out-null
	
	# Add $installationSource to contextScript.ps1
	$target = "$installationSource\contextScript.ps1"
    Write-Host "Adjusting '$target'..." -f yellow
	$t = (Get-Content "$target") -replace "%REPLACEME%", "$installationSource\IntuneWinAppUtil.exe"
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

    # Transform $installationSource so that backslashes get properly escaped in CMD
    $installationSource = $installationSource -replace [regex]::escape('\'), [regex]::escape('\')
    
    Write-Host "Setting properties..." -f yellow
    Write-Host "> NOTE: If powershell reports illegal characters in -file, launch this script with -UseAlternateFilePath." -f yellow
	if ($UseAlternateFilePath.IsPresent) {
		$fileVar = "`"${installationSource}\\contextScript.ps1`""
	} else {
		$fileVar = "\`"${installationSource}\\contextScript.ps1\`""
	}
	
    Set-ItemProperty "$baseReg\IntuneCreation" -name "(Default)" -value "Create intunewin package from here"
    Set-ItemProperty "$baseReg\IntuneCreation" -name "Icon" -value "$installationSource\contextIcon.ico"
    Set-ItemProperty "$baseReg\IntuneCreation\command" -name "(Default)" -value "powershell.exe -noexit -executionpolicy bypass -file $fileVar '%V''"

    Write-Host "All done" -f green
} catch {
    Write-Host "Error encountered: $_" -f red
}