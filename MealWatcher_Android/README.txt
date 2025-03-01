app design:

MainActivity.java
-----------------
MainActivity extends WearableActivity
MainActivity is the main class of the app
WearableActivity is a wearOS default library
we override two functions and use the default for all the rest

onCreate() -- overriding default function
initializes app, including the following steps
(a) creates notification channel and object
    (a notification is required to be displayed when an app runs
     continuously so that the user can see it is running)
(b) initializes display
    (button and textbox widgets)
(c) event handler functions for buttons:
    startButton (on pressing, the following is done):
      creates "intent" (service message)
      sends intent to service to start it
    stopButton (on pressing, the following is done):
      stops service

onContentChanged() -- overriding default function
(a) sets the callback functions for the buttons;
    this has to be done every time the display layout is changed
(b) a lot of interesting stuff goes into each callback function (see code)

init() -- our function
(a) creates the callback functions for all buttons for all layouts

switchView() -- our function
(a) changes the display layout (either main or microphone)


ControlWatch.java
------------------
Communicate with the watch app, and send all the recorded files after getting the watch recording files to the DropBox.

## Note
--------
For using the API of the DropBox, the API key, secret key, and the refresh token 
of the app from the Dashboard need to be included in the code. However, we can not 
make our app's API key, Secret Key, and Refresh Token of the DropBox in public platform. 
GitHub will inactive the codes. So, these keys are stored in different file, "AccessToken.java" 
and this file isn't included in the GitHub reprository.

Here is the step by step to get all the key to use DropBox API for uploading the files to the DropBox:
 
1. Go to the App Console (https://www.dropbox.com/developers/apps) of the DropBox developer, and select the intended app
2. You will get the "App Key", "Secret Key" of your app in here.
3. For getting the "Refresh Token":
	a) Get the autherization code: 

   - Make the OAuth app authorization URL like this: (plug in the app key in place of "App_Key_Here"): 
https://www.dropbox.com/oauth2/authorize?client_id=App_Key_Here&response_type=code&token_access_type=offline

   - Paste this link to a browser
   - Browse to that page in your browser while signed in to your account and click "Allow" to authorize it.
   - You will get an authorization code.
		
	b)  Get the authorization code for an access token and refresh token like this, e.g., using curl on the command line:
      (insert the authorization code from step 3.a in place of "Authorization_Code_Here", the app key in place of "App_Key_Here", 
      and the app secret in place of "App_Secret_Here"):
   
   	curl https://api.dropbox.com/oauth2/token \
   	-d code=Authorization_Code_Here \
   	-d grant_type=authorization_code \
   	-u App_Key_Here:App_Secret_Here
   
4. Copy the resulting refresh_token key.

After getting all the keys, create a file "AccessToken.java" inside the "phoneApp" and add the below code. MealWatcher app will 
upload all the files to your DropBox after this. 

public class AccessToken {
      private String refreshToken = "Your_Refresh_Token_key";
      private String clientId = "Your_APP_Key"; 
      private String clientSecret = "Your_APP_Secret_Key"; 
  
      public String getRefreshToken() {
          return refreshToken;
      }
  
      public String getClientId() {
          return clientId;
      }
  
      public String getClientSecret() {
          return clientSecret;
    }
  }


StayAwake.java
--------------
StayAwake extends IntentService
StayAwake creates a java worker thread for our app; it uses an IntentService
  so it can run continuously (called the foreground in Android)
IntentService is a wearOS default library
we override two functions

onCreate() -- overriding default function
puts service in foreground state, displays notification

onHandleIntent() -- overriding default function
Note: this is the "main" loop of the worker thread, continuously reading
sensors and processing the sensor data.
(a) use wakelock to keep CPU active so app can run continuously
(b) turn on sensors, configure sampling rates
(c) create callback functions for sensors, called when new readings available
(d) go into loop of wait/notify
    wait is used in this loop to go to sleep until new sensor reading
    notify is called in sensor callback function to wake up and continue
    (wait/notify is still to be implemented, it might save more power)
(e) if app "stop" button is pressed, loop exits and cleans up:
    turn off sensors
    turn off wakelock


