# The script is used to check services before and after reboot plus giving some additional information like hostname,last 5 reboots, disk info, network adapters info . 
# Running the script it will give you 4 options
#
# Option 1 -- " Before Reboot Services" : It will generate 3 files (Before_Services.html, Before_services.csv and vmnic.txt) with services currently running before the reboot plus some extra info like network info.  
#
# Option 2 -- "After  Reboot Services"  : It will generate 2 files (After_Services.html, After_services.csv) with services currently running after the reboot and compare it with the "before_services" file. 
#                                         If the before // after service is the same then the status will be Green
#                                         If the service was running before reboot and after reboot is stopped then the status will be RED
#                                         If the service was not running before reboot but it runs aftrer reboot then the status will be Orange
#                                         It will display before and after the network settings. The script does not check if they are different. It is just showning before and after. It is up to TE to check if they look the same
#
# Option 3 -- "Generate Info File"      : It will collect all the data and generate 1 file in order to have a final report.
#
# Option 4 -- "Exit"                    : Terminates the script
#
# Owner: Dimitrios Kakoulidis
# Author: Dimitrios Kakoulidis
#
# Revision History
# Initial Author: Dimitrios Kakoulidis - start
#
# v1.0 -  Original Version
# v1.5 -  Add Sass scan in order to check which apars are installed and which apars are missing.
# v1.8 -  Removed Sass scan after request by PHC due to time consuming. Added Network information before and after.
#
#
# Fill free to change // update // correct the script.


##  Create Style menu  ######
 $Style = "
<style>
    BODY{background-color:#b0c4de;}
    TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
    TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}
    TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    tr:nth-child(odd) { background-color:#d3d3d3;} 
    tr:nth-child(even) { background-color:white;}    
</style>
"


# Bypass  policy #############
$Bypass = Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$Bypass
####################################################################

## Initial values for checking Before, After and Sass scan ##########

$CheckBefore = 'Not Done'
$CheckAfter = 'Not Done'
$CheckSASS = 'Not Done'
$CopyFile = 'Not Done'
$CopyCab = 'Not Done'

####################################################################


## Take system info ##########
$Reboots = Get-WinEvent -FilterHashtable @{logname='system';id=6005} -MaxEvents 5| Select Message, TimeCreated  |ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Last 5 Reboots</h2>'|Out-String
$cpunum = Get-Process | Sort-Object CPU -desc | Select-Object -first 10 -Property ID,ProcessName,CPU |  ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Top Services</h2>'|Out-String 
$nmsrv = '<H1> Hostname :' + $env:computername + '</H1>'
$errormsg = "Error"
$netinfo= Get-WmiObject Win32_NetworkAdapterConfiguration  -Filter IPEnabled=TRUE -ComputerName . | Select-Object Description,@{Name='IpAddress';Expression={$_.IpAddress -join '; '}}, 
        @{Name='IpSubnet';Expression={$_.IpSubnet -join '; '}}, 
        @{Name='DefaultIPgateway';Expression={$_.DefaultIPgateway -join '; '}}, 
        @{Name='DNSServerSearchOrder';Expression={$_.DNSServerSearchOrder -join '; '}} |  ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Netowrk Info</h2>'|Out-String
$DiskInfo = Get-WMIObject Win32_Logicaldisk -ComputerName $env:computername | Select @{Name="Computer";Expression={$env:computername}}, DeviceID,@{Name="SizeGB";Expression={$_.Size/1GB -as [int]}},@{Name="FreeGB";Expression={[math]::Round($_.Freespace/1GB,2)}}|  ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Disk Info</h2>'|Out-String

####################################################################

##  Create menu  ############
function menu {
 cls
   Write-Host "================================================" 
   Write-Host "  Server Info . version 1.6"
   Write-Host "================================================
    Please provide number for required action 
   -------------------------------------------
     1. Before Reboot Services
     2. After Reboot Services
     3. Scanning Apars
     4. Generate Info File
     5. Exit 
   ------------"
 }
 ####################################################################

function back_menu {
  Start-Sleep -s 3
  mainmenu
}
#####Start of Script ############

##################################

##  Main menu  ######
function mainmenu{
menu 
$Choice = Read-Host -Prompt "Choice" 
  If ($Choice -eq "1") {
       before
 }
 ElseIf ($Choice -eq "2") {
       after
 }
 ElseIf ($Choice -eq "3") {
       Scan_Info
 }
 ElseIf ($Choice -eq "4") {
       Info_File
 }ElseIf ($Choice -eq "5") {
       Write-Host "================================================" 
       Write-Host "Thank you" 
       return
 }
  Else {
    error
 }
}

 ## 1. Before Reboot ############
 Function before {
Get-service | Select-Object status,Name,DisplayName,starttype | export-csv ".\Sass\Before_Services.csv" -NoTypeInformation
$CheckBefore = 'Done'

#Cell Color - Logic
$StatusColor = @{Stopped = ' bgcolor="Red">Stopped<';Running = ' bgcolor="Green">Running<';}

#Service Status
$GService = Get-service | Where-Object {$_.status} | Select DisplayName, Status | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Before Services</h2>'|Out-String 

#Cell Color - Find\Replace
$StatusColor.Keys | foreach { $GService = $GService -replace ">$_<",($StatusColor.$_) }


#Save the HTML Web Page
ConvertTo-HTML -head $Style -PostContent $cpunum,$DiskInfo,$netinfo,$Reboots,$GService -PreContent '<h1>Check Before Reboot Services </h1> ',$nmsrv |Out-File .\Sass\Before_Services.html
#Open TableHTML.html
Invoke-Item .\Sass\Before_Services.html
back_menu
 }
 ####################################################################

 ## 2. After Reboot ############
  Function after {
   
$path = '.\Sass\Before_Services.csv'

If (Test-Path $path) {
   $CheckBefore = 'Done'
   $CheckAfter = 'Done'
   Get-service | Select-Object status,Name,DisplayName,starttype | export-csv ".\Sass\After_Services.csv" -NoTypeInformation
   $services = import-csv ".\Sass\Before_Services.csv"
   $currentServices = get-service | Select-Object Status,Name,DisplayName,starttype 

   $services_all = for($i=0; $i -lt $services.count; $i ++){

   if(Compare-Object -ReferenceObject $services[$i].status -DifferenceObject $currentServices[$i].status){ 	
     
     if ($services[$i].status -eq 'RUNNING'){
         [pscustomobject]@{service=$services[$i].displayname;PreviousStatus=$services[$i].Status; CurrentStatus=$currentServices[$i].status;Status="WARNING_RUNBEFORE"}
     } else {
         [pscustomobject]@{service=$services[$i].displayname;PreviousStatus=$services[$i].Status; CurrentStatus=$currentServices[$i].status;Status="WARNING_STOPBEFORE"}
     }
    }else{
        [pscustomobject]@{service=$services[$i].displayname;PreviousStatus=$services[$i].Status;CurrentStatus=$currentServices[$i].status;Status="OK"}
    } #else
   } # for
   
    
   $sw = $services_all | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Comparing Services</h2>'|Out-String 


   #Cell Color - Logic
   $StatusColor = @{Stopped = ' bgcolor="Red">Stopped<';Running = ' bgcolor="Green">Running<';}
   $StatusClr = @{WARNING_RUNBEFORE = ' bgcolor="Red">It was Running Before<'; WARNING_STOPBEFORE = ' bgcolor="Orange">It was stopped before<';OK = ' bgcolor="Green">OK<';}

   #Service Status
   $GService = Get-service | Where-Object {$_.status} | Select DisplayName, Status | ConvertTo-HTML -AS Table -Fragment -PreContent '<h1>After Reboot Services </h1>',$nmsrv|Out-String 

   #Cell Color - Find\Replace
   $StatusColor.Keys | foreach { $GService = $GService -replace ">$_<",($StatusColor.$_) }
   $StatusClr.Keys | foreach  { $sw = $sw -replace ">$_<",($StatusClr.$_) } 

    #Save the HTML Web Page
    ConvertTo-HTML -head $Style -PostContent $cpunum,$DiskInfo,$netinfo,$Reboots,$sw -PreContent '<h1>Check After Reboot Services </h1> ',$nmsrv|Out-File .\Sass\After_Services.html
    #Open file
    Invoke-Item .\Sass\After_Services.html
    back_menu
  } else {   
      Write-Host "Please first run the Before Services"
      Start-Sleep -s 2
      mainmenu
  }
}
 
####################################################################

 ## 3. Scan Server ############
function Scan_Info {
 $sassfile = '.\Sass\Sass_'+$env:computername+'.txt'
 $CheckSass = 'Done'
 $copyNeed = 'FALSE'
 $source = '\\tsclient\m\wsusscn2.cab'
 $target = 'c:\ibm_apar\Sass\wsusscn2.cab'

## Check if files exists or if it is different  ############
 If (Test-Path $target) {
   $sizeGBSource = (Get-Item $source).Length
   $sizeGBTarget = (Get-Item $target).Length
   if ($sizeGBSource -eq $sizeGBTarget) {
      Write-Host 'File already exists. Skipping copy'          
    }else {
      $copyNeed = 'TRUE'
    }
  }else {
     $copyNeed = 'TRUE'
  }


if ($copyNeed  -eq 'TRUE'){
   Write-Host 'Copying wsusscn2.cab file please wait...'
      cmd.exe /c "xcopy /y \\tsclient\m\wsusscn2.cab c:\ibm_apar\Sass"
      Write-Host 'Done!'
      Start-Sleep -s 2
      Write-Host 'Copying sass.exe file please wait...'
      cmd.exe /c "xcopy /y \\tsclient\m\sass.exe c:\ibm_apar\Sass"
      Write-Host 'Done!'
      Start-Sleep -s 2
      $CopyCab = 'Done'
}



##  Executing Sass scan ########################
Write-Host 'Executing Sass scan....'
cmd.exe /c ".\Sass\sass.exe -i C:\ibm_apar\Sass\wsusscn2.cab -o $sassfile"
Write-Host 'Done! Opening html file...'
Start-Sleep -s 3

##  Check sass file for Installed and Not installed apars
$Sass_New_File = Get-Content $sassfile

$NotInstalled = @()
Foreach ($Line in $Sass_New_File) { 
  if ($Line -like '*!m!*'){
     $MyObject = New-Object -TypeName PSObject
     Add-Member -InputObject $MyObject -Type NoteProperty -Name Apars_Not_Installed -Value $Line
     $myStringNot = $MyObject
     $arrNot = ' ' + $myStringNot
     $msgNotInstArr = $arrNot.Split('!')
     $msgNotInst = $msgNotInstArr[2] + ' (' + $msgNotInstArr[3] + ') ' + $msgNotInstArr[6]
     $NotInstalled = $NotInstalled + $msgNotInst
  } 
}

$Installed = @()
Foreach ($Line_1 in $Sass_New_File) { 
  if ($Line_1 -like '*!i!*'){
     $MyObject_1 = New-Object -TypeName PSObject
     Add-Member -InputObject $MyObject_1 -Type NoteProperty -Name Apars_Installed -Value $Line_1
     $myStringInst = $MyObject_1
     $arrInst = ' ' + $MyObject_1
     $msgInstArr = $arrInst.Split('!')
     $msgInst = $msgInstArr[2] + ' (' + $msgInstArr[3] + ') ' + $msgInstArr[6]
     $Installed += $msgInst

  } 
}

## Convert to strings in order to add in the table as text.
$stringNotInst = @($NotInstalled)
$newstringsNotInst = ($stringNotInst | ForEach-Object  { new-object -TypeName PSObject -Property @{"Text" = $_.ToString() } } )

$stringInst = @($Installed)
$newstringsInst = ($stringInst | ForEach-Object  { new-object -TypeName PSObject -Property @{"Text" = $_.ToString() } } )



$notins = $newstringsNotInst | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2>Not Installed Apars </h2>'|Out-String
$inst = $newstringsInst | ConvertTo-HTML -AS Table -Fragment -PreContent '<h2> Installed Apars</h2>'|Out-String

ConvertTo-HTML -head $Style -PostContent $inst,$notins -PreContent '<h1>Sass Scan Analysis </h1>',$nmsrv|Out-File .\Sass\Sass_File.html 
Invoke-Item .\Sass\Sass_File.html
Stop-Service wuauserv
back_menu
}

####################################################################

##### 4.Info File ############
function Info_File {
#Save the HTML Web Page
$Report = 'Report_'+$env:computername+'.html'
$pathBefore = '.\Sass\Before_Services.csv'
If (Test-Path $pathBefore) {
   $CheckBefore = 'Done'
}
# Check if all checks are done

If ($CheckBefore -eq 'Done' -And  $CheckAfter -eq 'Done' -And $CheckSass -eq 'Done') {
    ConvertTo-HTML -head $Style -PostContent $cpunum,$DiskInfo,$netinfo,$Reboots, $sw, $inst, $notins  -PreContent '<h1> Report for Services and Apars </h1> ',$nmsrv|Out-File $Report 
    #Open TableHTML.html
    Invoke-Item $Report
    back_menu
  } else {
          Write-Host "One of the following was not performed" 
          Write-Host "Before Services Status : ",$CheckBefore 
          Write-Host "After Services  Status : ",$CheckAfter
          Write-Host "Sass scan       Status : ",$CheckSass          
          Start-Sleep -s 3
          mainmenu
    }
 }

#################################################################

#  Invalid menu option  ######

function error {
  Write-Host  "Invalid menu option. Please try again"
  Start-Sleep -s 2
  mainmenu
}

#################################################################### 

##  Start the script with menu #######################
mainmenu
####################################################################
