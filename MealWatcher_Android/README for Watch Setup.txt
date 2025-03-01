Device connections
------------------
Smartwatches cannot connect directly to computers (laptops).
They connect to phones which then connect to computers.
The typical method is:
smartwatch <= BlueTooth => phone
phone <= WiFi (fixed network; either hotspot or private) => laptop/computer
Note that using eduroam or other public networks makes this hard because
the computer and phone and watch might not all be on the same subnet;
this is why a hotspot or private network is preferred.

Watch setup and debugging
-------------------------
BlueTooth is always used to set up the smartwatch initially,
  using the wearOS app (from Google play store) installed on the phone.
Subsequently the smartwatch can be put on WiFi.
  [settings -> connectivity => WiFi]

Debugging is done using WiFi and the "adb" toolset:
https://developer.android.com/training/wearables/apps/debugging
Debugging can also be done over BlueTooth but I have not tried it.
For debugging, the watch needs to be put into developer mode.
  [settings -> system -> about -> tap "build number" 7 times]
Subsequently turn on ADB debugging on watch.
  [settings -> developer options -> ADB debugging]
  [settings -> developer options -> debug over WiFi]

Project organization
--------------------
Android projects have a LOT of folders and sub-folders.
Overview of organization: https://developer.android.com/studio/projects
The primary folder for source code is [project]/[module]/src/main/.
  [java] holds the java side code.
  [res] holds the GUI widget definitions.
  [c-code] holds the C code.
  AndroidManifest.xml describes the dependencies, libraries, "activites"

Mixing C and Java
-----------------
The core eating detection algorithm is written in C.  All android apps
are written in Java.  To combine them:
https://developer.android.com/studio/projects/add-native-code

JNI (Java native interface) is used to call C functions from within Java.
JNI Tutorial:  https://nachtimwald.com/2017/06/06/wrapping-a-c-library-in-java/
JNI is vendor independent; it is a programming language specification.

NDK is the Android toolset that integrates the two code types.
NDK getting started:  https://developer.android.com/ndk/guides
NDK includes a set of C functions (library) and compile and debug tools.

There are two ways to control compiling of mixed C/Java:  running ndk-build
in a DOS shell outside of Android Studio, or using CMake with gradle to
run it automatically within Android Studio.  The latter is preffered.
Instructions on how to configure:
https://developer.android.com/studio/projects/configure-cmake
The two config files are app/build.gradle and app/CMakeLists.txt.

JNI wrapper function names correspond to C function names using a convention:
https://stackoverflow.com/questions/32470463/is-the-naming-convention-for-java-native-interface-method-and-module-name
The escape sequence _1 corresponds to _ (so don't include the 1 in searches)

Compiling and installing on watch
---------------------------------
in a shell, type the following two commands:
first we should pair the laptop to the watch using command "adb pair 192.168.0.xx".
adb connect 192.168.1.89	[must tap OK on watch]
adb devices			[confirm watch is in attached list as "device"]
				[watch should show up in Android Studio]

click green play triangle in Android Studio	[to compile and install]
    [gradle build and install progress displayed in bottom of Android Studio]
    [may have to tap OK on watch to allow debugging]
if anything goes wrong, type "adb kill-server" and start over
if still going wrong, disable/re-enable "adb debugging" on watch

can also execute "Run->Debug [wear]" in Android Studio	[to compile/install]
    [this will show more debugging info if app is crashing]

to run app
----------
settings -> apps -> permissions -> EatMon2 	[turn all accesses on]
tap EatMon2					[starts app]

to pull files off app
---------------------
adb pull "storage/emulated/0/Android/data"
  [pulls an entire folder by having quotes around it]
adb shell ls storage/emulated/0/Android/data/research.eatmon2/files
  [to get list of files on the device]
adb shell rm storage/emulated/0/Android/data/research.eatmon2/files/*.*
  [to delete all files that the app stored on the device]

to install release version?
---------------------------
adb install ?  [I have not studied this yet.]
  [common ADB commands] https://devhints.io/adb


coordinate systems
------------------
Our coordinate system was defined in Yujie Dong's dissertation (figs 1.1, 1.4).
The android coordinate system is defined in their documentation:
https://developer.android.com/guide/topics/sensors/sensors_overview (fig 1).

Note that android gyro axes are called x, y, z referring to rotations about
those axes, whereas in our coordinate system we specifically identify yaw,
pitch, roll and they do not correspond to rotations about our x, y, z axes.

Converion is as follows (ours = android):
+x = +y
+y = -x
+z = +z
yaw = rotation about z axis
pitch = rotation about y axis
roll = rotation about x axis

apk signing
-----------
key store path password:  eatmon-keystore
key password:  eatmon-key0

cloning a project
-----------------
https://stackoverflow.com/questions/57102684/how-to-copy-and-rename-a-project-in-android-studio-3-4

(Not in Android Studio) Make a copy of the existing 'OldProject' directory.
(Not in Android Studio) Rename the copied directory to 'NewProject'.
Start Android Studio 3.4.
Select 'Open an existing Android Studio project'.
Navigate to the 'NewProject' directory, select it and click 'Open'.
Build -> Clean project.
File -> Sync project with gradle file.
Click the '1:Project' side tab and choose Android from the drop-down menu.
Expand the app -> java folder.
Right-click com.example.android.oldproject and select Refactor -> Rename.
Give a new name to the new project in the Rename dialog.
** Enter "research.new" into dialog box, not just "new"
** This will unfortunately cause "research.research" in some places (fix below)
Select 'Search in comments and strings' and 'Search for text occurrences'.
Click Refactor.
The 'Find: Refactoring Preview' pane appears, click 'Do Refactor'.
Expand the res -> values folder and double-click the strings.xml file.
Change the app_name string value to "New Project".

In Project pane, expand Gradle Scripts and open build.gradle (Module: app).
In android -> defaultConfig -> applicationId check that the value of the
	applicationID key is "com.example.android.newproject".
	If the value isn't correct, change it manually.
File -> Sync project with gradle file

Expand the app -> manifests folder and double click AndroidManifest.xml.
Check that the 'package' name is correct.
It should be "com.example.android.newproject". If not, change it manually.
Also check the 'service' and 'activity' names, fixing any "research.research".

In classifier.c, fix 3 occurrences of "research.research" in filenames.
Rename the "eatmon2" portion of the 3 function names to the new name.

In MainActivity.java, fix 1 occurrence of "research.research" in filename.

