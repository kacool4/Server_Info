#Server Info

The script is used to check services before and after reboot plus giving some additional information like hostname,last 5 reboots, disk info, network adapters info . 
Running the script it will give you 4 options
# Option 1 -- " Before Reboot Services" 
It will generate 3 files (Before_Services.html, Before_services.csv and vmnic.txt) with services currently running before the reboot plus some extra info like network info.  

# Option 2 -- "After  Reboot Services"  
It will generate 2 files (After_Services.html, After_services.csv) with services currently running after the reboot and compare it with the "before_services" file. 
      If the before // after service is the same then the status will be Green
      If the service was running before reboot and after reboot is stopped then the status will be RED
      If the service was not running before reboot but it runs aftrer reboot then the status will be Orange
It will display before and after the network settings. The script does not check if they are different. It is just showning before and after. It is up to TE to check if they look the same

# Option 3 -- "Generate Info File"      
It will collect all the data and generate 1 file in order to have a final report.

# Option 4 -- "Exit"                    
Terminates the script
#
Owner: Dimitrios Kakoulidis
Author: Dimitrios Kakoulidis
Revision History
Initial Author: Dimitrios Kakoulidis - start
 v1.0 -  Original Version
 v1.5 -  Add Sass scan in order to check which apars are installed and which apars are missing.
 v1.8 -  Removed Sass scan after request by PHC due to time consuming. Added Network information before and after.

 Fill free to change // update // correct the script.
