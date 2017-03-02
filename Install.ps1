param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory=$true,
               Position=0,
               ParameterSetName="Path",
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to one or more locations.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ConfigPath, 
    
    [string] $id
)

Import-Module -Force ".\PackageInstaller.psm1" 
Initialize-PackageInstaller $ConfigPath


#if chocolatey not already present install it 
Get-ExecutionPolicy -List | Where-Object { -not ($_.Scope -in "MachinePolicy", "UserPolicy")  } | ForEach-Object { Set-ExecutionPolicy -Scope $_.Scope -ExecutionPolicy Unrestricted}

Install-Chocolatey -Verbose

Install-Packages 



