# MealWatcher_Apple
Apple code for a iOS and WatchOS app used to record motion data from watch and smart ring.

Project created in the lab group of Dr. Adam W. Hoover 
    at Clemson University, Clemson, SC, USA.
Code written by Jimmy Nguyen and James Jolly in Fall of 2023,
    with citations pulled from resources.
Heavily edited and maintain by James Jolly starting in Spring of 2024.

Creating this repository to allow for version control of the code
and to have public release (under GNU GPLv3 License) for other researchers.
Initial upload of this repository is app version 1.3.1 on Feb 27, 2025;
previous versions starting at version 1.1.0 of the app 
are tracked in a private repository to protect Dropbox credentials 
which were previously declared in code. 


BEFORE USING THIS REPO:
- Create a DropBox upload token following the tutorial listed in 
"MealWatcher/MealWatcher/ExampleDropBoxCredentials.swift"
- Update return values in the "MealWatcher/MealWatcher/DropBoxCredentials.swift" file.



KNOWN BUGS:
- FileCount should never hit zero, even after forced DropBox upload,
due to the active log file (current session) never being uploaded.
Count instead should drop to 1 and upload and delete all other files on phone. 


Long Term Improvements
- Permissions check
--- Automatically Re-request permission if user declines a 
    needed permission on first time using app
