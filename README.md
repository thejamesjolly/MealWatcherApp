# MealWatcher_Apple

Apple code for a iOS and WatchOS app used to record motion data from watch and smart ring.


Project created in the lab group of Dr. Adam W. Hoover 
    at Clemson University, Clemson, SC, USA.
Apple code written by Jimmy Nguyen and James Jolly in Fall of 2023,
    with citations pulled from resources;
heavily edited and maintain by James Jolly starting in Spring of 2024.
Android code written by Faria Armin, Lakshmi G Rangaraju, Adam Hoover, and James Jolly;
maintained and primarily developed by Faria Armin starting in Summer of 2024.

Creating this repository to allow for version control of the code
and to have public release (under GNU GPLv3 License) for other researchers.
For Apple, initial upload to this repository is app version 1.3.1 on Feb 27, 2025;
    previous versions of the app starting at v1.1.0
    are tracked in a private repository. 
For Android, initial upload to this repository is app version 1.3.2;
    previous versions of the app starting at "v1.2.3 B(00)"
    are tracked in a private repository.
    

BEFORE USING THIS REPO:
- DropBox Credentials are needed to upload the data from the app to a cloud server
- IN APPLE:
    - Create a DropBox upload token following the tutorial listed in 
        "MealWatcher_Apple/MealWatcher/ExampleDropBoxCredentials.swift"
    - Update return values in the "MealWatcher_Apple/MealWatcher/DropBoxCredentials.swift" file.
- IN ANDROID:
    - Create return values of tokens and place them in 
    "MealWatcher_Android/phoneApp/src/main/java/research/mealwatcher/AccessToken.java" file


