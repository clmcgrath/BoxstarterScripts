function Disable-UAC{

    Write-Output "Disabling UAC"
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA  -Value 0

}

function Enable-RemoteDesktop{
        param(
        [switch]$DoNotRequireUserLevelAuthentication
    )
    
    Write-Output "Enabling Remote Desktop..."
    $obj = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace root\cimv2\terminalservices
    if($obj -eq $null) {
        Write-Message "Unable to locate terminalservices namespace. Remote Desktop is not enabled"
        return
    }
    try {
        $obj.SetAllowTsConnections(1,1) | out-null
    }
    catch {
        throw "There was a problem enabling remote desktop. Make sure your operating system supports remote desktop and there is no group policy preventing you from enabling it."
    }

    $obj2 = Get-WmiObject -class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -ComputerName . -Filter "TerminalName='RDP-tcp'"
    
    if($obj2.UserAuthenticationRequired -eq $null) {
        Write-Output "Unable to locate Remote Desktop NLA namespace. Remote Desktop NLA is not enabled"
        return
    }
    try {
        if($DoNotRequireUserLevelAuthentication) {
            $obj2.SetUserAuthenticationRequired(0) | out-null
            Write-Output "Disabling Remote Desktop NLA ..."
        }
        else {
			$obj2.SetUserAuthenticationRequired(1) | out-null
            Write-Output "Enabling Remote Desktop NLA ..."    
        }
    }
    catch {
        throw "There was a problem enabling Remote Desktop NLA. Make sure your operating system supports Remote Desktop NLA and there is no group policy preventing you from enabling it."
    }	
}

function Set-TaskbarOptions {
    	[CmdletBinding(DefaultParameterSetName='unlock')]
	param(
        [Parameter(ParameterSetName='lock')]
        [switch]$Lock,
        [Parameter(ParameterSetName='unlock')]
        [switch]$UnLock,
		[ValidateSet('Small','Large')]
		$Size,
		[ValidateSet('Top','Left','Bottom','Right')]
		$Dock,
		[ValidateSet('Always','Full','Never')]
		$Combine
	)

	$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
	$dockingKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects2'

	if(-not (Test-Path -Path $dockingKey)) {
		$dockingKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
	}

	if(Test-Path -Path $key) {
		if($Lock)
		{
			Set-ItemProperty $key TaskbarSizeMove 0
        }
        if($UnLock){
			Set-ItemProperty $key TaskbarSizeMove 1
		}

		switch ($Size) {
			"Small" { Set-ItemProperty $key TaskbarSmallIcons 1 }
			"Large" { Set-ItemProperty $key TaskbarSmallIcons 0 }
		}

		switch($Combine) {
			"Always" { Set-ItemProperty $key TaskbarGlomLevel 0 }
			"Full" { Set-ItemProperty $key TaskbarGlomLevel 1 }
			"Never" { Set-ItemProperty $key TaskbarGlomLevel 2 }
		}

		Restart-Explorer
	}

	if(Test-Path -Path $dockingKey) {
		switch ($Dock) {
			"Top" { Set-ItemProperty -Path $dockingKey -Name Settings -Value ([byte[]] (0x28,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0x02,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x07,0x00,0x00,0x2e,0x00,0x00,0x00)) }
			"Left" { Set-ItemProperty -Path $dockingKey -Name Settings -Value ([byte[]] (0x28,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0xb0,0x04,0x00,0x00)) }
			"Bottom" { Set-ItemProperty -Path $dockingKey -Name Settings -Value ([byte[]] (0x28,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0x02,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x82,0x04,0x00,0x00,0x80,0x07,0x00,0x00,0xb0,0x04,0x00,0x00)) }
			"Right" { Set-ItemProperty -Path $dockingKey -Name Settings -Value ([byte[]] (0x28,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x3e,0x00,0x00,0x00,0x2e,0x00,0x00,0x00,0x42,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x07,0x00,0x00,0xb0,0x04,0x00,0x00)) }
		}

		Restart-Explorer
	}
}

function Set-ExplorerOptions{
    [CmdletBinding()]
    param(
        [switch]$EnableShowHiddenFilesFoldersDrives,
        [switch]$DisableShowHiddenFilesFoldersDrives,
        [switch]$EnableShowProtectedOSFiles,
        [switch]$DisableShowProtectedOSFiles,
        [switch]$EnableShowFileExtensions,
        [switch]$DisableShowFileExtensions,
        [switch]$EnableShowFullPathInTitleBar,
        [switch]$DisableShowFullPathInTitleBar,
        [switch]$EnableExpandToOpenFolder,
        [switch]$DisableExpandToOpenFolder,
        [switch]$EnableOpenFileExplorerToQuickAccess,
        [switch]$DisableOpenFileExplorerToQuickAccess,
        [switch]$EnableShowRecentFilesInQuickAccess,
        [switch]$DisableShowRecentFilesInQuickAccess,
        [switch]$EnableShowFrequentFoldersInQuickAccess,
        [switch]$DisableShowFrequentFoldersInQuickAccess
    )

    $PSBoundParameters.Keys | % {
        if($_-like "En*"){ $other="Dis" + $_.Substring(2)}
        if($_-like "Dis*"){ $other="En" + $_.Substring(3)}
        if($PSBoundParameters[$_] -and $PSBoundParameters[$other]) {
            throw new-Object -TypeName ArgumentException "You may not set both $_ and $other. You can only set one."
        }
    }

    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    $advancedKey = "$key\Advanced"
    $cabinetStateKey = "$key\CabinetState"

    Write-Output "Setting Windows Explorer options..."

    if(Test-Path -Path $key) {
        if($EnableShowRecentFilesInQuickAccess) {Set-ItemProperty $key ShowRecent 1}
        if($DisableShowRecentFilesInQuickAccess) {Set-ItemProperty $key ShowRecent 0}

        if($EnableShowFrequentFoldersInQuickAccess) {Set-ItemProperty $key ShowFrequent 1}
        if($DisableShowFrequentFoldersInQuickAccess) {Set-ItemProperty $key ShowFrequent 0}
    }

    if(Test-Path -Path $advancedKey) {
        if($EnableShowHiddenFilesFoldersDrives) {Set-ItemProperty $advancedKey Hidden 1}
        if($DisableShowHiddenFilesFoldersDrives) {Set-ItemProperty $advancedKey Hidden 0}

        if($EnableShowFileExtensions) {Set-ItemProperty $advancedKey HideFileExt 0}
        if($DisableShowFileExtensions) {Set-ItemProperty $advancedKey HideFileExt 1}

        if($EnableShowProtectedOSFiles) {Set-ItemProperty $advancedKey ShowSuperHidden 1}
        if($DisableShowProtectedOSFiles) {Set-ItemProperty $advancedKey ShowSuperHidden 0}

        if($EnableExpandToOpenFolder) {Set-ItemProperty $advancedKey NavPaneExpandToCurrentFolder 1}
        if($DisableExpandToOpenFolder) {Set-ItemProperty $advancedKey NavPaneExpandToCurrentFolder 0}

        if($EnableOpenFileExplorerToQuickAccess) {Set-ItemProperty $advancedKey LaunchTo 2}
        if($DisableOpenFileExplorerToQuickAccess) {Set-ItemProperty $advancedKey LaunchTo 1}
    }

    if(Test-Path -Path $cabinetStateKey) {
        if($EnableShowFullPathInTitleBar) {Set-ItemProperty $cabinetStateKey FullPath  1}
        if($DisableShowFullPathInTitleBar) {Set-ItemProperty $cabinetStateKey FullPath  0}
    }

    Restart-Explorer        
}

function Restart-Explorer {

    try{
        Write-BoxstarterMessage "Restarting the Windows Explorer process..."
        $user = Get-CurrentUser
        try { $explorer = Get-Process -Name explorer -ErrorAction stop -IncludeUserName } 
        catch {$global:error.RemoveAt(0)}
        
        if($explorer -ne $null) { 
            $explorer | ? { $_.UserName -eq "$($user.Domain)\$($user.Name)"} | Stop-Process -Force -ErrorAction Stop | Out-Null
        }

        Start-Sleep 1

        if(!(Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            $global:error.RemoveAt(0)
            start-Process -FilePath explorer
        }
    } catch {$global:error.RemoveAt(0)}
}

function Set-CornerNavigationOptions{
    	[CmdletBinding()]
	param(
		[switch]$EnableUpperRightCornerShowCharms,
		[switch]$DisableUpperRightCornerShowCharms,
		[switch]$EnableUpperLeftCornerSwitchApps,
		[switch]$DisableUpperLeftCornerSwitchApps,
		[switch]$EnableUsePowerShellOnWinX,
		[switch]$DisableUsePowerShellOnWinX
	)

	$PSBoundParameters.Keys | % {
        if($_-like "En*"){ $other="Dis" + $_.Substring(2)}
        if($_-like "Dis*"){ $other="En" + $_.Substring(3)}
        if($PSBoundParameters[$_] -and $PSBoundParameters[$other]) {
            throw new-Object -TypeName ArgumentException "You may not set both $_ and $other. You can only set one."
        }
    }

	$edgeUIKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell\EdgeUi'
	$advancedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

	if(Test-Path -Path $edgeUIKey) {
		if($EnableUpperRightCornerShowCharms) { Set-ItemProperty -Path $edgeUIKey -Name 'DisableTRCorner' -Value 0 }
		if($DisableUpperRightCornerShowCharms) { Set-ItemProperty -Path $edgeUIKey -Name 'DisableTRCorner' -Value 1 }

		if($EnableUpperLeftCornerSwitchApps) { Set-ItemProperty -Path $edgeUIKey -Name 'DisableTLCorner' -Value 0 }
		if($DisableUpperLeftCornerSwitchApps) { Set-ItemProperty -Path $edgeUIKey -Name 'DisableTLCorner' -Value 1 }
	}

	if(Test-Path -Path $advancedKey) {
		if($EnableUsePowerShellOnWinX) { Set-ItemProperty -Path $advancedKey -Name 'DontUsePowerShellOnWinX' -Value 0 }
		if($DisableUsePowerShellOnWinX) { Set-ItemProperty -Path $advancedKey -Name 'DontUsePowerShellOnWinX' -Value 1 }
    }
}

function Set-StartScreenOptions{

  [CmdletBinding()]
	param(
		[switch]$EnableBootToDesktop,
		[switch]$DisableBootToDesktop,
		[switch]$EnableDesktopBackgroundOnStart,
		[switch]$DisableDesktopBackgroundOnStart,
		[switch]$EnableShowStartOnActiveScreen,
		[switch]$DisableShowStartOnActiveScreen,
		[switch]$EnableShowAppsViewOnStartScreen,
		[switch]$DisableShowAppsViewOnStartScreen,
		[switch]$EnableSearchEverywhereInAppsView,
		[switch]$DisableSearchEverywhereInAppsView,
		[switch]$EnableListDesktopAppsFirst,
		[switch]$DisableListDesktopAppsFirst
	)

    $PSBoundParameters.Keys | %{
        if($_-like "En*"){ $other="Dis" + $_.Substring(2)}
        if($_-like "Dis*"){ $other="En" + $_.Substring(3)}
        if($PSBoundParameters[$_] -and $PSBoundParameters[$other]){
            throw new-Object -TypeName ArgumentException "You may not set both $_ and $other. You can only set one."
        }
    }

	$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    $startPageKey = "$key\StartPage"
    $accentKey = "$key\Accent"

	if(Test-Path -Path $startPageKey) {
		if($enableBootToDesktop) { Set-ItemProperty -Path $startPageKey -Name 'OpenAtLogon' -Value 0 }
		if($disableBootToDesktop) { Set-ItemProperty -Path $startPageKey -Name 'OpenAtLogon' -Value 1 }

		if($enableShowStartOnActiveScreen) { Set-ItemProperty -Path $startPageKey -Name 'MonitorOverride' -Value 1 }
		if($disableShowStartOnActiveScreen) { Set-ItemProperty -Path $startPageKey -Name 'MonitorOverride' -Value 0 }

		if($enableShowAppsViewOnStartScreen) { Set-ItemProperty -Path $startPageKey -Name 'MakeAllAppsDefault' -Value 1 }
		if($disableShowAppsViewOnStartScreen) { Set-ItemProperty -Path $startPageKey -Name 'MakeAllAppsDefault' -Value 0 }

		if($enableSearchEverywhereInAppsView) { Set-ItemProperty -Path $startPageKey -Name 'GlobalSearchInApps' -Value 1 }
		if($disableSearchEverywhereInAppsView) { Set-ItemProperty -Path $startPageKey -Name 'GlobalSearchInApps' -Value 0 }

		if($enableListDesktopAppsFirst) { Set-ItemProperty -Path $startPageKey -Name 'DesktopFirst' -Value 1 }
		if($disableListDesktopAppsFirst) { Set-ItemProperty -Path $startPageKey -Name 'DesktopFirst' -Value 0 }
	}

	if(Test-Path -Path $accentKey) {
		if($EnableDesktopBackgroundOnStart) { Set-ItemProperty -Path $accentKey -Name 'MotionAccentId_v1.00' -Value 219 }
		if($DisableDesktopBackgroundOnStart) { Set-ItemProperty -Path $accentKey -Name 'MotionAccentId_v1.00' -Value 221 }
    }
}

function Move-DocumentsDirectory {
        [CmdletBinding()]
        param(
        [Parameter(Mandatory=$true)]
        [string]$LibraryName, 
        [Parameter(Mandatory=$true)]
        [string]$NewPath,
        [switch]$DoNotMoveOldContent
    )
    #why name the key downloads when you can name it {374DE290-123F-4565-9164-39C4925E467B}? duh.
    if($LibraryName.ToLower() -eq "downloads") {$LibraryName="{374DE290-123F-4565-9164-39C4925E467B}"}
    $shells = (Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders')
    if(-not ($shells.Property -Contains $LibraryName)) {
        throw "$LibraryName is not a valid Library"
    }
    $oldPath =  (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -name "$libraryName")."$libraryName"
    if(-not (test-path "$NewPath")){
        New-Item $NewPath -type directory
    }
    if((resolve-path $oldPath).Path -eq (resolve-path $NewPath).Path) {return}
    Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' $LibraryName $NewPath
    Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' $LibraryName $NewPath
    Restart-Explorer
    if(!$DoNotMoveOldContent) { Move-Item -Force $oldPath/* $NewPath -ErrorAction SilentlyContinue}
}

function Get-LibraryNames {

    $shells = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
    $retVal = @()
    (Get-Item $shells).Property | ForEach-Object {
        $property = ( Get-ItemProperty -Path $shells -Name $_ )
        $retVal += @{ "$_"=$property."$_" }
    }
    return $retVal
}

function Install-WindowsUpdate {
  
    param(
        [switch]$getUpdatesFromMS, 
        [switch]$acceptEula, 
        [switch]$SuppressReboots,
        [string]$criteria="IsHidden=0 and IsInstalled=0 and Type='Software' and BrowseOnly=0"
    )

    try{
        $searchSession=Start-TimedSection "Checking for updates..."        
        $updateSession =new-object -comobject "Microsoft.Update.Session"
        $Downloader =$updateSession.CreateUpdateDownloader()
        $Installer =$updateSession.CreateUpdateInstaller()
        $Searcher =$updatesession.CreateUpdateSearcher()
        if($getUpdatesFromMS) {
            $Searcher.ServerSelection = 2 #2 is the Const for the Windows Update server
        }
        $wus=Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'"
        $origStatus=$wus.State
        $origStartupType=$wus.StartMode
        Write-BoxstarterMessage "Update service is in the $origStatus state and its startup type is $origStartupType" -verbose
        if($origStartupType -eq "Auto"){
            $origStartupType = "Automatic"
        }
        if($origStatus -eq "Stopped"){
            if($origStartupType -eq "Disabled"){
                Set-Service wuauserv -StartupType Automatic
            }
            Out-BoxstarterLog "Starting windows update service" -verbose
            Start-Service -Name wuauserv
        }
        else {
            # Restart in case updates are running in the background
            Out-BoxstarterLog "Restarting windows update service" -verbose
            Remove-BoxstarterError { Restart-Service -Name wuauserv -Force -WarningAction SilentlyContinue }
        }

        $Result = $Searcher.Search($criteria)
        Stop-TimedSection $searchSession
        $totalUpdates = $Result.updates.count

        If ($totalUpdates -ne 0)
        {
            Out-BoxstarterLog "$($Result.updates.count) Updates found"
            $currentCount = 0
            foreach($update in $result.updates) {
                ++$currentCount
                if(!($update.EulaAccepted)){
                    if($acceptEula) {
                        $update.AcceptEula()
                    }
                    else {
                        Out-BoxstarterLog " * $($update.title) has a user agreement that must be accepted. Call Install-WindowsUpdate with the -AcceptEula parameter to accept all user agreements. This update will be ignored."
                        continue
                    }
                }

                $Result= $null
                if ($update.isDownloaded -eq "true" -and ($update.InstallationBehavior.CanRequestUserInput -eq $false )) {
                    Out-BoxstarterLog " * $($update.title) already downloaded"
                    $result = install-Update $update $currentCount $totalUpdates
                }
                elseif($update.InstallationBehavior.CanRequestUserInput -eq $true) {
                    Out-BoxstarterLog " * $($update.title) Requires user input and will not be downloaded"
                }
                else {
                    Download-Update $update
                    $result = Install-Update $update $currentCount $totalUpdates
                }
            }

            if($result -ne $null -and $result.rebootRequired) {
                if($SuppressReboots) {
                    Write-Warning "A Restart is Required."
                } else {
                    $Rebooting=$true
                    Write-Warning "Restart Required. Restarting now..."
                    Stop-TimedSection $installSession
                    if(test-path function:\Invoke-Reboot) {
                        return Invoke-Reboot
                    } else {
                        Restart-Computer -force
                    }
                }
            }
        }
        else{Out-BoxstarterLog "There is no update applicable to this machine"}    
    }
    catch {
        Out-BoxstarterLog "There were problems installing updates: $($_.ToString())"
        throw
    }
    finally {
        if($origAUVal){
            Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWuServer -Value $origAUVal -ErrorAction SilentlyContinue
        }
        if($origStatus -eq "Stopped")
        {
            Out-BoxstarterLog "Stopping win update service and setting its startup type to $origStartupType" -verbose
            Set-Service wuauserv -StartupType $origStartupType
            Remove-BoxstarterError { stop-service wuauserv -WarningAction SilentlyContinue }
        }
    }
}

function Download-Update($update) {
    $downloadSession=Start-TimedSection "Download of $($update.Title)"
    $updates= new-Object -com "Microsoft.Update.UpdateColl"
    $updates.Add($update) | out-null
    $Downloader.Updates = $updates
    $Downloader.Download() | Out-Null
    Stop-TimedSection $downloadSession
}

function Install-Update($update, $currentCount, $totalUpdates) {
    $installSession=Start-TimedSection "Install $currentCount of $totalUpdates updates: $($update.Title)"
    $updates= new-Object -com "Microsoft.Update.UpdateColl"
    $updates.Add($update) | out-null
    $Installer.updates = $Updates
    try { $result = $Installer.Install() } catch {
        if(!($SuppressReboots) -and (test-path function:\Invoke-Reboot)){
            if(Test-PendingReboot){
                $global:error.RemoveAt(0)            
                Invoke-Reboot
            }
        }
        # Check for WU_E_INSTALL_NOT_ALLOWED  
        if($_.Exception.HResult -eq -2146233087) {
            Out-BoxstarterLog "There is either an update in progress or there is a pending reboot blocking the install."
            $global:error.RemoveAt(0)
        }
        else { throw }
    }
    Stop-TimedSection $installSession
    return $result
}

function Enable-MicrosoftUpdate {
 
	if(!(Get-IsMicrosoftUpdateEnabled)) {
		Write-Output "Microsoft Update is currently disabled."
		Write-Output "Enabling Microsoft Update..."
		
		$serviceManager = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
		$serviceManager.ClientApplicationID = "Boxstarter"
		$serviceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
	}
	else {
		Write-Output "Microsoft Update is already enabled, no action will be taken."
	}
}

function Disable-MicrosoftUpdate {

	if(Get-IsMicrosoftUpdateEnabled) {
		Write-BoxstarterMessage "Microsoft Update is currently enabled."
		Write-BoxstarterMessage "Disabling Microsoft Update..."

			$serviceManager = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
			$serviceManager.ClientApplicationID = "Boxstarter"
			$serviceManager.RemoveService("7971f918-a847-4430-9279-4a52d1efe18d")
	}
	else {
		Write-BoxstarterMessage "Microsoft Update is already disabled, no action will be taken."
	}
}

function Disable-InternetExplorerEnhancedSecurityConfiguration {

    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    if(Test-Path $AdminKey){
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        $disabled = $true
    }
    if(Test-Path $UserKey) {
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        $disabled = $true
    }
    if($disabled) {
        Restart-Explorer
        Write-Output "IE Enhanced Security Configuration (ESC) has been disabled."
    }
}

function Disable-GameBarTips {

    $path = "HKCU:\SOFTWARE\Microsoft\GameBar"
    if(!(Test-Path $path)) {
        New-Item $path
    }

    New-ItemProperty -LiteralPath $path -Name "ShowStartupPanel" -Value 0 -PropertyType "DWord" -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $path -Name "ShowStartupPanel" -Value 0

    Write-Output "GameBar Tips have been disabled."
}

function Disable-BingSearchFromExplorer {

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"

    if(!(Test-Path $path)) {
        New-Item $path
    }

    New-ItemProperty -LiteralPath $path -Name "BingSearchEnabled" -Value 0 -PropertyType "DWord" -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $path -Name "BingSearchEnabled" -Value 0
}

function Enable-Chrometana {
    [CmdletBinding()]
    param (
        [switch] $EdgeDeflectorOnly
    )
    
    Write-Warning "Feature Not Yet Implemented"
    
    Write-Warning "FUTURE: Install Edge Deflector"
    if (-not $EdgeDeflectorOnly){
        Write-Warning "FUTURE: Install Chrometana Chrome Extension"
    }
}

function Install-WindowsFeature{

}

function Uninstall-WindowsFeature{
    [CmdletBinding()]
    param(
        # Windows Feature Name
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $FeatureName,

        # Windows Feature Name
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $PackageName
    
    )
}

function Get-WindowsFeature{ 
    [CmdletBinding()]
    param(
        [switch] $Online,
        [string] $Name
    )
    $params = @{}
    if ($FeatureName)
    {
        $params.Add("FeatureName", $FeatureName)
    }
    
    if ($PackageName)
    {
        $params.Add("PackageName", $PackageName)
    }
    
    $features = Get-WindowsOptionalFeature -Online:$Online
    $features = $features | Where-Object {$_.State –eq "Disabled" } | Format-Table 
}

function Get-InstalledFeatures{
    Get-WindowsFeature | Where-Object { $_.State -eq "Enabled"}
}






