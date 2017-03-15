enum PackageType {
    All
    NPM 
    Chocolatey
    Zip
    ZipInstaller
    Installer
    VSCodeExtension
    VSExtension
    Yarn
}

function Initialize-PackageInstaller{
    param(
        [Parameter(Mandatory, Position=0)]
        [string]
        $PathToConfig
    )
    $script:ConfigPath = $PathToConfig
    Remove-Variable script:PackageConfig -ErrorAction SilentlyContinue 
    

}

function Install-Package {
    [CmdletBinding()]
    param(
        # id of package to install
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Id,
        # Type of package to install ie npm, chocolatey etc  
        [Parameter(ValueFromPipelineByPropertyName)]
        [PackageType]
        $Type,
        [switch] $Force
    )
    process{
        switch ($Type) {
            "NPM" {
                Install-NPMPackage -Name $Id -Force:$Force 
            }
            "Chocolatey" {
                Install-ChocolateyPackage -Name $Id -Force:$Force 
            }
            "Zip" {
                Write-Warning "$Type not yet implemented" 
            }
            "ZipInstaller" {
                Write-Warning "$Type not yet implemented"   
            }
            "Installer" {
                Write-Warning "$Type not yet implemented"   
            }
            "VSCodeExtension" {
                Install-VSCodeExtension -Name $Id -Force:$Force 
            }
            "VSExtension" {
                Install-VSExtension -Name $Id -Force:$Force 
            }
            "Yarn" {
                Install-NPMPackage -UseYarn -Name $Id -Force:$Force 
            }
            Default {
                Write-Error "Invalid Package Type $Type Specified "
            }
        }
    }
}

function Install-Packages {
    [CmdletBinding()]
    param(
        # Name of package to install
        [PackageType]
        $Type = [PackageType]::All , 
        [string] $Id
    )
    process{
        $packages = Get-Packages -id $Id -type $Type
        $packages | Install-Package 
    }
}

function Get-Packages($Id, [PackageType] $Type = [PackageType]::All  ){
    Get-PackageConfigSection package -type $Type -id $id
}

function Get-HttpPackageConfig ($Uri){
    
    $cachePath = Join-Path "$env:TEMP\PackageInstaller\" "$(Get-Date -Format "u")\Packages.xml"
    
    $script:ConfigPath = $cachePath

    Invoke-WebRequest -Uri $Uri -UseBasicParsing -OutFile $cachePath 
    $content = ([xml] (Get-Content $script:ConfigPath)).packages
     
    Write-Host "Downloaded packaged configuration from $Uri"
    return $content
}


function Get-PackageConfig{
    if (-not (Test-Path variable:script:PackageConfig)) {
        $content = $null
        if ($script:ConfigPath -match "^https?://") {
            $content = (Get-HttpPackageConfig -Uri $script:ConfigPath)
        }
        else {
            $content = ([xml] (Get-Content $script:ConfigPath)).packages
        }
    }
    
    $script:PackageConfig
}

function IsDisabled($element){

    if ($element) { 
        $result = ($element.disabled -eq "true")
        $result
    }
    else {
        $false
    }

}

function Enable-RemoteDesktop ([switch] $AddFirewallRule, [switch] $EnableSecureAuthentication ){
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1  
}

function Get-PackageConfigSection($section = "package", $type, $id, [switch] $IncludeDisabled, $keyProperty = 'id', $ThrowOnError ){
    $config = Get-PackageConfig
    $sections = $config.$section

    if(-not $type -eq [PackageType]::All ){
        $sections = $sections | Where-Object { $_.type -eq $type.ToString() }
    }

    #include config items marked disabled 
    if (-not $IncludeDisabled.IsPresent) {
        $temp = $sections | Where-Object {-not (IsDisabled $_) }
        $sections = $temp
    }
    
    #if -id specified return section by id 
    if ($id){
        $section = $sections | Where-Object {$_.$keyProperty -eq $id}
        Assert-HasValue -Value $section -ThrowOnError:$ThrowOnError  -ErrorMessage "No Environment $type Section with id '$id' found in environment file"
        
        return $section 
    }
    else {
        if($ThrowOnError){
            Assert-HasValue -Value $sections -ThrowOnError:$ThrowOnError  -ErrorMessage "No Environment $type Sections found in environment file"
        }
        return $sections
    
    }
}
#Install Package Systems

    #Installs Chocolatey Package Manager if not already installed
    function Install-Chocolatey([switch] $Verbose){

        if(-not (Test-Path -Path env:ChocolateyPath)) {
            Write-Warning "Chocolatey Not Installed..."
            Write-Warning "Installing..."
            Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        }elseif ($Verbose) {
            Write-Host -ForegroundColor Yellow "Chocolatey already installed skipping..."
        }
    }

    #Installs NPM Package Manager if not already installed
    function Install-NPM([switch] $Verbose){
        $version = Get-NPMVersion
        
        if(-not ($version)) {
            Write-Warning "NPM Not Installed..."
            Write-Warning "Installing NodeJs via Chocolatey"
            Install-Chocolatey -Verbose
            Install-ChocolateyPackage -Name "NodeJs.Install"
        }elseif ($Verbose) {
            Write-Host -ForegroundColor Yellow "NPM already installed, Skipping..."
        }
    }
    
    #Installs Visual Studio Code if not already installed
    function Install-VSCode([switch] $Verbose){
        [version] $version = Get-VSCodeVersion
        if(-not ($version)) {

            Write-Warning "Visual Studio Code Not Installed..."
            Write-Warning "Installing VsCode via Chocolatey"
            Install-Chocolatey -Verbose
            Install-ChocolateyPackage -Name "VisualStudioCode"
        
        }elseif ($Verbose) {
            Write-Host -ForegroundColor Yellow "Visual Studio Code already installed, Skipping..."
        }
    }

    #Installs Yarn Package Manager if not already installed
    function Install-Yarn([switch] $Verbose){
        $version = Get-YarnVersion
        
        if(-not ($version)) {
            Write-Warning "Yarn Not Installed..."
            Write-Warning "Installing Yarn via NPM"
        
            Install-NPM -Verbose
            Install-NPMPackage -Name "Yarn"

        }elseif ($Verbose) {
            Write-Host -ForegroundColor Yellow "Yarn already installed, Skipping..."
        }
    }







##Package Installers 

    #Installs a package from Chocolatey Gallery
    function Install-ChocolateyPackage{
        param(
            # Name of Package to install 
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [string]
            $Name,
            [switch] $Force
        )

        process{
            Write-Header "Installing $type Package $name" 
            $forceCommand = if ($Force) {
                " --force"
            } else {
                ""
            }
            $command = "choco install $Name $forceCommand"
            Invoke-Expression -Command $command
        } 
    }
    
    #Installs a package from NPM feed 
    function Install-NPMPackage{
        param(
            # Name of Package to install 
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [string]
            $Name,
            [switch] $UseYarn,
            [switch] $Force
        )
        process{

            if ($UseYarn){

                $forceCommand = if ($Force) {
                    " --force"
                } else {
                    ""
                }
                $command = "yarn add global $Name $forceCommand"
                Write-Warning "-UseYarn Specified Installing with Yarn"
                Install-Yarn

            }else{

                Install-NPM
                $forceCommand = if ($Force) {
                    " --force"
                } else {
                    ""
                }
                $command = "npm install -g $Name $forceCommand"

            }

            Write-Header "Installing $type Package $name"

            Invoke-Expression -Command $command
        } 
    }
    #Installs an extension from Visual Studio Gallery
    function Install-VSCodeExtension {
        param(
            # Name of Package to install 
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [string]
            $Name,
            [switch] $Force
        )
        
        process{
            Write-Header "Installing $type Package $name" 
            Install-VSCode
        
            $verboseCommand = if($Verbose) {
                " --verbose "
            } 
        
            if ($Force) {
                $extension = (Invoke-Expression -Command "code --list-extensions" | Where-Object { $_ -eq "felipecaputo.git-project-manager" })
                
                if ($extension){
                    
                    $command = "code --disable-extension $Name $verboseCommand"
                    Invoke-Expression $command

                    $command = "code --uninstall-extension $Name $verboseCommand"
                    Invoke-Expression $command

                }

            }

            $command = "code --install-extension $Name $verboseCommand"
            Invoke-Expression $command 

        }

    }

    #Installs an extension from Visual Studio Gallery 
    function Install-VSExtension{
        param(
            # Name of Package to install 
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [string]
            $Name,
            [switch] $Force
        )

        process{
            Write-Header "Installing $type Package $name" 

        } 
    }

    #Invokes Defined Installer Command 
    function Invoke-Installer{
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true,
                Position=0,
                ParameterSetName="Path",
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                HelpMessage="Path to one or more locations.")]
            $Path
        )

        process{
            Write-Header "Installing $type Package $name" 
        }

    }





##Tools
    
    #Install new Environment Variable if not set 
    function Add-EnvironmentVariable{
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string] $Name, 
            [Parameter(Mandatory)]
            [string] $Value, 
            [EnvironmentVariableTarget] $Scope = [EnvironmentVariableTarget]::User, 
            [switch] $Force
        )

        try { $old_value = [Environment]::GetEnvironmentVariable($Name, $Scope) }catch {}

        if ($old_value) {
            Write-Warning "Environment variable $Name already exists with value $old_value use -force to override current value"
        }

        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    }

    function Write-Header {
        [CmdletBinding()]
        param(
            # Text to display in header output 
            [Parameter(Mandatory, Position=0)]
            [string]
            $HeaderText,
            # Text Color of header 
            [Parameter()]
            [System.ConsoleColor]
            $ForegroundColor = [System.ConsoleColor]::Cyan
        )
        process{

            Write-Host -ForegroundColor $ForegroundColor  "========================================================================"
            Write-Host -ForegroundColor $ForegroundColor  "$HeaderText"
            Write-Host -ForegroundColor $ForegroundColor  "========================================================================"
            
        }
    }
    function Get-ChocolateyVersion{
        try { 
            if(-not $script:chocolateyVersion){
                $script:chocolateyVersion = (choco -v) 
            }

            $script:chocolateyVersion
        }
        catch {
            $null 
        }
    }

    function Get-VSCodeVersion{
        try {

            if(-not $script:vsCodeVersion){
                $script:vsCodeVersion = (npm -version) 
            }
            
            $script:vsCodeVersion
        }
        catch {
            $null 
        }
    }

    function Get-NPMVersion{
        try {

            if(-not $script:npmVersion){
                $script:npmVersion = (npm -version) 
            }
            
            $script:npmVersion
        }
        catch {
            $null 
        }
    }

    function Get-YarnVersion{
        try {

            if(-not $script:yarnVersion){
                $script:yarnVersion = (yarn --version) 
            }
            
            $script:yarnVersion
        }
        catch {
            $null 
        }
    }