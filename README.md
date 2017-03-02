
# Boxstarter Scripts #
## Powershell Script to consolidate package installations from multiple package providers 

### Currently Supported 
* Chocolatey
* NPM
* Yarn 
* VSCode Extensions

### Coming Soon 
* Visual Studio Extensions (VSExtension) 
* EXE Installers (Installer)
* MSI Installers (Installer)
* Zip Files (Zip, ZipInstaller)
* private feed support 
* Custom provider support (Write your own! :D )


### Commands

#### _Install-Package_ #### 

##### Description 
> Directly calls package installer command based on supported -Types 
> Supports pipeline by property on Id and Type 




#### -Id  [string] 

___Required___

> Package Identifier for provideder


#### -Type  

Valid Options 

* NPM 
* Chocolatey 
* Zip 
* ZipInstaller 
* Installer 
* VSCodeExtension 
* VSExtension 
* Yarn 
     
#### -Force
> passes force flag to provider command 
  or attempts to uninstall then reinstall in cases of extensions and exe / msi installers 



Install-Packages


#### _Install-Package_ #### 

##### Description 
> Directly calls package installer command based on supported -Types 
> Supports pipeline by property on Id and Type 


#### -Type  

> Filter Package File by Package Type

_Optional_

##### Valid Options 
* All  (Default) 
* NPM 
* Chocolatey 
* Zip 
* ZipInstaller 
* Installer 
* VSCodeExtension 
* VSExtension 
* Yarn 
     
#### -Force
> passes force flag to provider command 
  or attempts to uninstall then reinstall in cases of extensions and exe / msi installers 





#### _Initialize-PackageInstaller_ #### 

##### Description 
> Directly calls package installer command based on supported -Types 
> Supports pipeline by property on Id and Type 



     
#### -PathToConfig
> path to config xml file 
> defaults to Packages.xml in current working directory 



#### _Install-Chocolatey_ #### 

##### Description 
> Checks if chocolatey is installed and Runs Chocolatey Install script if not present  

#### _Install-NPM_ #### 

##### Description 
> Checks if NPM is installed and installs NodeJS.Install Package from chocolatey feed if not present 

> \* Also Runs Install-Chocolatey Check if NPM is missing  


#### _Install-Yarn_ #### 

##### Description 
> Checks if Yarn is installed and installs Yarn from NPM feed if  not present 
> 
> \* Also Runs Install-NPM Check if Yarn is missing  

#### _Install-VSCode_ #### 

##### Description 
> Checks if Visual Studio Code is installed and installs Yarn from Choclatey feed if  not present 
> 
> \* Also Runs Install-NPM Check if Yarn is missing  





