Param(
	[string]$path
)

# --------------------------------------------
# User variables - EDIT BELOW
# --------------------------------------------
$installationFile = "install.ps1"
$intuneWinTool = "%REPLACEME%"

# --------------------------------------------
# Generic variables - DO NOT EDIT
# --------------------------------------------
$path = $path -replace "'", ""
$inventory = gci $path
$tempDir = "$env:TEMP\IntuneCreation_$(Get-Date -f "ddMMyyyy-HHmmss")"

# --------------------------------------------
# Main
# --------------------------------------------
Add-Type -AssemblyName PresentationFramework

try {
	# Check if required files exist
	if (!(Test-Path $intuneWinTool)) {
		throw "IntuneWinAppUtil was not found at '$intuneWinTool'."
	}
	if ($inventory.name -notcontains "install.ps1") {
		throw "Did not find installation file: 'install.ps1'."
	}
	
	# Temporarily move specific files to temp folder
	$exclusionFilter = @(
		"parameter*.txt"
		"detection.ps1"
		"*.bak"
	)
	
	mkdir $tempDir | out-null
	
	Write-Host "Moving filtered items..." -f yellow
	$inventory | % {
		$a = $_
		$exclusionFilter | % {
			if ($a.name -like $_) {
				Write-Host "> Match for $($a.Name) using $($_), moving..." -f cyan
				Move-Item $a.FullName $tempDir -Force
			}
		}
	}
	
	# Actually create intunewin file
	& $intuneWinTool -c $path -s $installationFile -o $path -q
	
	$temp = gci $path | ? Name -like *.intunewin | Select -first 1	
	[System.Windows.MessageBox]::Show("Your file is ready at: $($temp.FullName)", "Done", 'Ok', 'Information') | out-null
} catch {
	[System.Windows.MessageBox]::Show("Could not create intune package: $($_)", "Error - $path", 'Ok', 'Error') | out-null
} finally {
	# Cleanup
	Move-Item $tempDir\* $path -Force -ErrorAction SilentlyContinue
	Remove-Item $tempDir -Recurse -Force  -ErrorAction SilentlyContinue
}