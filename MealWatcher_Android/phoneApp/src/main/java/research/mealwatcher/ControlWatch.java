/**
 <MealWatcher is a phone & watch application to record motion data from a watch and smart ring>
 Copyright (C) <2023>  <James Jolly, Faria Armin, Adam Hoover>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

package research.mealwatcher;

import android.app.ActivityManager;
import android.app.IntentService;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.MediaPlayer;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;


import com.dropbox.core.DbxAuthInfo;
import com.dropbox.core.DbxException;
import com.dropbox.core.DbxRequestConfig;
import com.dropbox.core.json.JsonReader;
import com.dropbox.core.v2.DbxClientV2;
import com.dropbox.core.v2.files.FileMetadata;
import com.dropbox.core.v2.files.WriteMode;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.android.gms.wearable.Asset;
import com.google.android.gms.wearable.ChannelClient;
import com.google.android.gms.wearable.DataClient;
import com.google.android.gms.wearable.DataEvent;
import com.google.android.gms.wearable.DataEventBuffer;
import com.google.android.gms.wearable.DataItem;
import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.DataMapItem;
import com.google.android.gms.wearable.PutDataMapRequest;
import com.google.android.gms.wearable.Wearable;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.GZIPInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import androidx.wear.remote.interactions.RemoteActivityHelper;

import org.json.JSONObject;

public class ControlWatch extends IntentService implements DataClient.OnDataChangedListener {
    private static boolean watchAppStatus; /*To ensure watch app is not restarted if it is already started.*/
    private static boolean watchAppIsOn = false; /*To ensure watch app is still running.*/
    static boolean isDuplicateWatchFileAck = false; /* This variable is to ensure if the phone doesn't receive duplicate acknowledgements from watch. */
    private RemoteActivityHelper remoteActivityHelper;
    static final String record_on_msg = "ON";
    static final String record_off_msg = "OFF";

    static final String startUpload = "Upload to Dropbox";
    static final String uploading = "Uploading";
    static String isFileTransferDone = "True";
    private static NotificationManager notificationManager;
    static Notification notification;
    private static PowerManager.WakeLock wakeLock;
    static final int notificationID = 43;
    private static File directory;
    private static DataClient dataClient;

    static Context context;
    // Handler to check the watch app status
    private final Handler timeoutHandler = new Handler();
    private Runnable timeoutRunnable;
    private static final long TIMEOUT_DURATION_MS = 5000;
//    private static Handler main_ui_thread = new Handler(Looper.getMainLooper());

    static private String dropBoxAccessToken = null;
    static Thread uploadToDropboxThread;
    static private ConnectivityManager connectivityManager;
    static ChannelClient channelClient;
    static ChannelClient.Channel globalChannel;
    static String dropboxFolder;
    static String folderName;
    static int filesFailedUpload = 0;
    static String uploadButton;
    static ExecutorService executor;

    private static LogFunction logFunction;
    private MediaPlayer mediaPlayer;

    private static AccessToken token = new AccessToken();

    public ControlWatch() {
        super("ControlWatch");
    }


    @Override
    public void onCreate() {
        System.out.println("in on create of control watch");
        context = getApplicationContext();
        directory = getExternalFilesDir(null);
        logFunction = new LogFunction();

        //MainActivity.writeToLog("in onCreate of watch service");
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        if (activityManager != null) {
            for (ActivityManager.RunningServiceInfo service : activityManager.getRunningServices(Integer.MAX_VALUE)) {
                System.out.println(service.service.getClassName());
            }
        }
        connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        remoteActivityHelper = new RemoteActivityHelper(this, Executors.newSingleThreadExecutor());
        dataClient = Wearable.getDataClient(this);
        dataClient.addListener(this);

        // Initially watch app is not on.
        watchAppStatus = false;
        isDuplicateWatchFileAck = false;

        executor = Executors.newCachedThreadPool();

        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is not in the Support Library.
        NotificationChannel notificationChannel = new NotificationChannel("calorie_check_notification_channel", "calorie_check", NotificationManager.IMPORTANCE_LOW // Sets the notification as a silent notification.
        );

        notificationManager = getSystemService(NotificationManager.class);
        notificationManager.createNotificationChannel(notificationChannel);

        Intent intent = new Intent(this, ControlWatch.class);
        //intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE);
        notification = new Notification.Builder(ControlWatch.this,
                "calorie_check_notification_channel")
                .setSmallIcon(R.drawable.eatmon_notification_icon)
                .setContentTitle("CalorieCheck notification")
                .setContentText("Recording started!")
                .setWhen(System.currentTimeMillis())
                .setContentIntent(pendingIntent).setOngoing(true).build();
        uploadToDropboxThread = new Thread(new DropboxUploadRunnable());

        timeoutRunnable = new Runnable() {
            @Override
            public void run() {
                watchAppStatus = false;
                // Informing user that connection to watch couldn't be established.
                //Toast.makeText(ControlWatch.this, "Couldn't connect to watch, please try again!", Toast.LENGTH_LONG).show();
                showToast(ControlWatch.this, "Couldn't connect to watch, please try again!", 1);
                LocalDateTime now = LocalDateTime.now();
            }
        };

        PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
        /*
        Wake lock level - PARTIAL_WAKE_LOCK: Ensures that the CPU is running; the screen and keyboard backlight
        will be allowed to go off. If the user presses the power button, then the screen will
        be turned off but the CPU will be kept on until all partial wake locks have been released.
        */
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MealWatcher::WakelockTag");

        super.onCreate();
    }

    // API 34+ callback when 6 hours timeout is reached
    //This is used for safety purpose. In here, when the user opens the app
    // for stopping the recording the 6 hours timer of the dataSync is stopped, and restarted in the next session.
    @Override
    public void onTimeout(int serviceId, int reason) {
        logFunction.error( "FS timed out", serviceId + ", Reason: " + reason);

        if (mediaPlayer == null) {
            mediaPlayer = MediaPlayer.create(this, R.raw.alarm);
            mediaPlayer.setOnCompletionListener(mp -> {
                mp.release();
                mediaPlayer = null;
            });
            mediaPlayer.start();
        }

        // Call stopSelf() quickly to avoid system failure
        stopSelf(serviceId);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        //System.out.println("in handling intent");
        boolean isStickyOn = true;
        if (intent != null) {
            //MainActivity.writeToLog("Got the intent = " + intent.getAction());
            final String action = intent.getAction();
            logFunction.information("Watch_MT", "Current action is executing: " + action);
            if (Objects.nonNull(action)) {
                switch (action) {
                    case "start_service":
                        System.out.println("Watch service started!");
                        break;
                    case "upload_to_dropbox":
                        File[] files = directory.listFiles();
                        if (Objects.nonNull(files) && files.length > 0) {
                            System.out.println("Files exist to upload");
                            //System.out.println("State of thread is " + uploadToDropboxThread.getState());
                            Log.d("DropBoxUpload", "State of the thread: " + uploadToDropboxThread.getState());

                            //MainActivity.writeToLog("Starting the dropbox upload thread.");
                            //LocalDateTime now = LocalDateTime.now();
                            //MainActivity.writeToLogTime("Uploading the remaining files to Dropbox at the beginning at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                            if (uploadToDropboxThread.getState() == Thread.State.NEW) {
                               // MainActivity.writeToLog("Upload thread started!");
                                uploadToDropboxThread.start();
                            } else if (uploadToDropboxThread.getState() == Thread.State.TERMINATED) {
                                uploadToDropboxThread = new Thread(new DropboxUploadRunnable());
                                //MainActivity.writeToLog("Upload thread started!");
                                uploadToDropboxThread.start();
                            }
                        }
                        break;
                    case "start_watch_app":
                        startWatchApp();
                        break;
                    case "set_recording_off":

                        sendDataItem(intent.getStringExtra("path"), intent.getStringExtra("key"), intent.getStringExtra("value"));
                        // Remove the notification from notification bar.
                        cancelNotification();

                        // Remove this service from foreground state and remove the notification from
                        // notification bar.
                        //stopForeground(STOP_FOREGROUND_REMOVE);
                        if (wakeLock.isHeld()) {
                            wakeLock.release();
                        }

                       // System.out.println("service foreground? after recording off = " + MainActivity.isServiceRunningInForeground(this, ControlWatch.class));
                        break;
                    case "Stop_Foreground":
                        //MainActivity.writeToLog("Stopping the foreground watch service");
                        isStickyOn = false;
                        //stopForeground(STOP_FOREGROUND_REMOVE);
                        break;
                    case "inform_watch_about_ring":
                       // MainActivity.writeToLog("Informing watch about ring status");
                        sendDataItem(intent.getStringExtra("path"), intent.getStringExtra("key"), intent.getStringExtra("value"));
                        break;
                }
            }
        }

        /*
        START_STICKY should be returned because the service is explicitly telling the system to
        restart it if it gets terminated by the operating system due to resource constraints (e.g., low memory).
        When sufficient resources become available again, the system will automatically restart
        the service and call onStartCommand() with a null Intent (indicating that no new Intent is
        being delivered).

        The START_STICKY behavior is particularly useful for services that perform background tasks
         or handle long-running operations. By using this return value, you ensure that the service
         keeps running and continues its work even after the system temporarily kills it to free up
          resources.
         */
        if (isStickyOn) {
            return START_STICKY;
        }
        return flags;
    }

    @Override
    protected void onHandleIntent(@Nullable Intent intent) {
    }

    void startWatchApp() {
        // Start the watch app if it is not already started.
        if (!watchAppStatus) {

            logFunction.information("Watch", "Sending intent to start the watch app");
            watchAppStatus = true; // Watch app is started from mobile app.

            // Send a RemoteIntent to WearOS to start the watch application.
            Uri uri1 = Uri.parse("mealwatcher://research.mealwatcher");
            Intent intentAndroid = new Intent(Intent.ACTION_VIEW).addCategory(Intent.CATEGORY_BROWSABLE)
                    // If set, the activity will not be launched if it is already running at the top of the history stack.
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    //.setComponent(ComponentName.unflattenFromString("research.mealwatcher/research.mealwatcher.MainActivity"))
                    .setData(uri1);
            ListenableFuture<Void> listenableFuture = remoteActivityHelper.startRemoteActivity(intentAndroid, null);
            Futures.addCallback(listenableFuture, new FutureCallback<Void>() {
                        @Override
                        public void onSuccess(Void result) {
                            System.out.println("Successfully sent intent!");
                            logFunction.information("Watch","Successfully sent intent!");
                        }

                        public void onFailure(@NonNull Throwable thrown) {
                            System.out.println("Failed to send the intent!");
                            //logFunction.information("Watch","Failed to send the intent!. Reason: " + thrown.toString());
                            thrown.printStackTrace();
                        }
                    },
                    // causes the callbacks to be executed on the main (UI) thread
                    Executors.newSingleThreadExecutor());
        }
    }

    static void sendDataItem(String path, String key, String message) {
        System.out.println("Sending data item!");
        //MainActivity.writeToLog("Sending data item to watch!");
        PutDataMapRequest putDataMapReq = PutDataMapRequest.create(path);
        putDataMapReq.getDataMap().putString(key, message);
        putDataMapReq.getDataMap().putLong("timestamp", System.currentTimeMillis());
        Task<DataItem> putDataTask = dataClient.putDataItem(putDataMapReq.asPutDataRequest().setUrgent());
        putDataTask.addOnSuccessListener(new OnSuccessListener<DataItem>() {
            @Override
            public void onSuccess(DataItem dataItem) {
                //System.out.println("Data Sent Successfully! :)" + key);
                logFunction.information("Watch", "Data Sent Successfully to the watch!. Key: " + key);
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                System.out.println("Data Sent Failed! :(");
                logFunction.error("Watch", "Data sent failed! " + key);
            }
        });
    }

    /*
    Method to listen to the messages/data from the watch app. The messages include the record button status
    to sync between mobile and watch app and the watch application status. And data include the sensor
    data file from watch to store on phone's memory.
     */
    @Override
    public void onDataChanged(@NonNull DataEventBuffer dataEvents) {
        System.out.println("in on data changed in phone!");
        //MainActivity.writeToLog("In onDataChanged of ControlWatch service!");
        for (DataEvent event : dataEvents) {
            if (event.getType() == DataEvent.TYPE_CHANGED) {
                // DataItem changed
                DataItem item = event.getDataItem();
                DataMap dataMap = DataMapItem.fromDataItem(item).getDataMap();
                /*
                Below two use cases of recording on and off are when user starts and stops recording
                from watch.
                 */
                if (item.getUri().getPath().compareTo("/record_button_status") == 0) {
                    if (dataMap.getString("record").equals("on")) {
                        //System.out.println("isFileTransferDone = " + isFileTransferDone);
                        //MainActivity.writeToLog("Record button state on!");
                        //System.out.println("RecordButtonState after watch starts recording initial = " + MainActivity.watchRecordStatus);
                        MainActivity.watchRecordStatus = "true";
                        MainActivity.watchRecordStarted = true ;
                        LocalDateTime now = LocalDateTime.now();
                        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH-mm-ss");
                        logFunction.information("Watch","Get the message from the watch: 'Watch recording started'");

                        //Checking the box
                        MainActivity.startWatchSensors.setChecked(true);
                        MainActivity.stopWatchSensors.setChecked(false);
                        MainActivity.takeBeforeMealPicture.setChecked(false);
                        MainActivity.takeAfterMealPicture.setChecked(false);
                        MainActivity.takeSurvey.setChecked(false);
                        MainActivity.prePictureTaken = "false";
                        MainActivity.postPictureTaken = "false";
//                        MainActivity.startWatchSensors.setBackground(R.drawable.checked_background);

                        MainActivity.setButtonText(MainActivity.watchRecordButton, record_on_msg);
                        // Setting green color indicating the recording started.
                        MainActivity.setButtonColor(MainActivity.watchRecordButton,
                                Color.parseColor("#008000"));

                        //MainActivity.writeToLogTime("Watch sensor is started from watch at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                        displayNotification();
                        isDuplicateWatchFileAck = false;

                        //checkOnWatchStatus();

                        // Start this service as a foreground service and also display the notification
                        // to user informing that recording is started.
                        //startForeground(42, notification);
                        wakeLock.acquire();

                        //System.out.println("RecordButtonState after watch starts recording final = " + MainActivity.watchRecordStatus);
                    } else if (dataMap.getString("record").equals("off")) {
                        MainActivity.watchRecordStatus = "false";
                        MainActivity.setButtonText(MainActivity.watchRecordButton, record_off_msg);
                        MainActivity.setButtonColor(MainActivity.watchRecordButton, Color.parseColor("#FF0000")); // Setting red color indicating the recording stopped.

                        // Recording has stopped but file transfer is not yet completed.
                        isFileTransferDone = "False";

                        MainActivity.startWatchSensors.setChecked(false);
                        MainActivity.stopWatchSensors.setChecked(true);
                        MainActivity.isRecordingDone = true;

                        LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogTime("Watch sensor is closed from watch at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                        logFunction.information("Watch","Got the message from the watch: 'watch sensor is closed'" );

                        // Cancel the display of the notification.
                        cancelNotification();

                        // Remove this service from foreground state. This will remove the notification from notification bar.
                        //stopForeground(STOP_FOREGROUND_REMOVE);
                       // System.out.println("service foreground? after recording off = " + MainActivity.isServiceRunningInForeground(this, ControlWatch.class));
                        if (wakeLock.isHeld()) {
                            wakeLock.release();
                        }
                    }
                }
                if (item.getUri().getPath().compareTo("/file_path") == 0) {
                    // Execute the task on a separate thread
                    if (executor == null || executor.isShutdown()) {
                        executor = Executors.newCachedThreadPool();
                        //System.out.println("Executor is initialized in onDataChange file_path");
                    }
                    executor.execute(() -> {
                        try {
                           // MainActivity.writeToLog("before isDuplicateWatchFileAck = " + isDuplicateWatchFileAck);
                            //MainActivity.writeToLog("Received the sensor file chunk from watch in the byte[] format");
                            Asset asset = dataMap.getAsset("sensors_file");
                            String fileNameReceived = dataMap.getString("fileName");
                            logFunction.information("Watch","Got a file from the watch named: " + fileNameReceived );
                            //MainActivity.writeToLogSync("Got the file named: " + fileNameReceived);

                            String fileName = MainActivity.prev_pid_value + "-" + fileNameReceived;
                            int fileNumber = dataMap.getInt("numOfFiles");
                            File file = new File(directory + "/" + fileName);
                            Task<DataClient.GetFdForAssetResponse> fileDescriptorForAsset = dataClient.getFdForAsset(asset);
                            //Waiting for the task to get completed.
                            DataClient.GetFdForAssetResponse getFdForAssetResponse = Tasks.await(fileDescriptorForAsset);
                            try (InputStream assetInputStream = getFdForAssetResponse.getInputStream();
                                 FileOutputStream fos = new FileOutputStream(file)) {
                                byte[] buffer = new byte[1024];
                                int bytesRead;
                                while ((bytesRead = assetInputStream.read(buffer)) != -1) {
                                    fos.write(buffer, 0, bytesRead);
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                                logFunction.error("Watch", "Got a file but can't write it in the phone storage.");
                            }

                            //MainActivity.writeToLog("Sending msg to phone for sending another file");
                            sendDataItem("/another_recording_file", "send",
                                    (fileNumber - 1) + " " + fileNameReceived);

                            //MainActivity.writeToLogSync("Send a message to the watch: 'Send another files' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));


                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    });
                }
                /*
                Watch app informs phone app that the watch app is started to ensure that the watch app
                is started from phone. So after the watch app is started, we will start the recording.
                 */
                 if (item.getUri().getPath().compareTo("/watch_app_status") == 0) {
                    if (dataMap.getString("app").equals("started")) {
                        //System.out.println("Watch app started!");
                        //MainActivity.writeToLog("Got message form Watch app, that it is started successfully!");
                        //System.out.println("watchAppStatus = " + watchAppStatus);
                        //LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogTime("Watch app started in the watch at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                        //MainActivity.writeToLogSync("Got the message from the watch: 'Watch App is started' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                        /*
                        Note: We don't set the watchAppStatus to true here. Because when ever the
                        watch app is started we don't want to start recording.
                         */
                        // Ensuring that watch app is started from mobile. And to ensure that
                        // sensors recordings are not started without the sensors button on mobile app
                        // is clicked.
                        if (watchAppStatus) {
                            isDuplicateWatchFileAck = false;
                            //checkOnWatchStatus();
                        }
//                        toggleButton.setChecked(true);
                    } else if (dataMap.getString("app").equals("stopped")) {
                        //System.out.println("watch app is stopped");
                        logFunction.information("Watch","Watch app stopped");
                        /*LocalDateTime now = LocalDateTime.now();
                        MainActivity.writeToLogSync("Got a message from the watch:  'Watch app stopped at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
*/
                        if (MainActivity.watchRecordStatus.equals("true")) {
                            //MainActivity.informUser("Watch app is crashed, please start it again.");
                            //mainActivity.showToast("Watch app is crashed, please start it again.",0);
                            showToast(getApplicationContext(), "Watch app is crashed, please start it again.", 0);
                            logFunction.error("Watch","Got the message from watch: 'Watch App is crashed'");

                            //LocalDateTime now1 = LocalDateTime.now();
                            //MainActivity.writeToLogTime("Watch app is crashed at: " + now1.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                            MainActivity.startWatchSensors.setChecked(false);
                            MainActivity.stopWatchSensors.setChecked(true);
                            MainActivity.watchRecordStatus = "false";
                            MainActivity.setButtonText(MainActivity.watchRecordButton, record_off_msg);
                            MainActivity.setButtonColor(MainActivity.watchRecordButton, Color.parseColor("#FF0000")); // Setting red color indication the recording stopped.
                        }
                        watchAppStatus = false; // watch app is stopped.
                    }
                }
                if (item.getUri().getPath().compareTo("/data_transfer_ack") == 0) {
                    if (dataMap.getString("all_files_sent").equals("yes")) {
                        //System.out.println("Ack received!");
                        //MainActivity.writeToLog("Data ack for all files sent from watch is received");
                        //LocalDateTime now = LocalDateTime.now();
                        logFunction.information("Watch","All files sent from watch is received." );
                        //MainActivity.writeToLogSync("Got the message from the watch: 'All the files are received' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                        // Maintaining this variable to ensure that user doesn't start the recording
                        // before all files are being transferred to phone from watch.
                        isFileTransferDone = "True";
                        showToast(ControlWatch.this, "Saved the watch sensor file!", 0);
                        // If already the watch is recording(i.e., second recording is started), don't close the watch app.
                        if (MainActivity.watchRecordStatus.equals("false")) {
                            // Stops the application on the watch after all the sensor data files are saved on mobile.
                            sendDataItem("/app_status", "state", "stop");
                            //LocalDateTime now1 = LocalDateTime.now();
                            //MainActivity.writeToLogSync("Send the message to the watch: 'Stop the watch application as all files are saved' at: " + now1.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                            executor.shutdown();
                        }
                        isDuplicateWatchFileAck = false;

                        //MainActivity.writeToLog("isDuplicateWatchFileAck = " + isDuplicateWatchFileAck);

                        // Maintaining allWatchFilesReceived variable to avoid duplicates.
                        if (!isDuplicateWatchFileAck) {
                            System.out.println("Uploading to dropbox");
                            isDuplicateWatchFileAck = true;
                            //MainActivity.writeToLog("Starting the dropbox upload thread as all the watch files have been received.");
                            //LocalDateTime time_dropbox = LocalDateTime.now();
                            //MainActivity.writeToLogTime("Dropbox upload is started at: " + time_dropbox.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                            if (uploadToDropboxThread.getState() == Thread.State.NEW) {
                                uploadToDropboxThread.start();
                                logFunction.information("Watch_DB","Starting the dropbox upload thread as all the watch files have been received.");
                            } else if (uploadToDropboxThread.getState() == Thread.State.TERMINATED) {
                                uploadToDropboxThread = new Thread(new DropboxUploadRunnable());
                                uploadToDropboxThread.start();
                            }
                        }

                    }
                }
                if(item.getUri().getPath().compareTo("/previous_data_transfer_ack")==0){
                    //LocalDateTime now = LocalDateTime.now();
                    //MainActivity.writeToLogSync("Got all the previous session files from the watch at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                    sendDataItem("/got_previous_files", "all_received","yes");
                    //MainActivity.writeToLogSync("Send the message to the watch app: 'Get all the previous files' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                }
                if (item.getUri().getPath().compareTo("/phone_status_check_for_recording") == 0) {
                    if (dataMap.getString("status").equals("is_on?")) {
                        //MainActivity.writeToLog("informing watch that phone app is running");
                        //LocalDateTime now = LocalDateTime.now();
                        logFunction.information("Watch","Got a message from the watch: ' Is the phone app On for start recording'");

                        sendDataItem("/phone_status_for_recording", "status", "on");
                        logFunction.information("Watch","Send the message to the watch app:  'Phone app is on for start the recording'");
                        //System.out.println("sent that phone app is started.");
                        //LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogTime("Sent the acknowledgement to the watch that phone app is running at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
//                        if (executor == null || executor.isShutdown()) {
//                            executor = Executors.newCachedThreadPool();
//                            System.out.println("Executor is initialized in onDataChange file_path");
//                        }
                    }
                }
                if(item.getUri().getPath().compareTo("/phone_status_check_for_upload") == 0) {
                    if (dataMap.getString("status").equals("is_on?")) {
                       // MainActivity.writeToLog("informing watch that phone app is running");
                        //LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogSync("Got a message from the watch: 'Is the phone app is On for sending files' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                        sendDataItem("/phone_status_for_uploading", "status", "on");
                        //System.out.println("sent that phone app is running for uploading");
                        //MainActivity.writeToLogSync("Send the message to the watch: 'It is on for sending files' at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));

                        //LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogTime("Sent the acknowledgement to the watch that phone app is running at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
//                        if (executor == null || executor.isShutdown()) {
//                            executor = Executors.newCachedThreadPool();
//                            System.out.println("Executor is initialized in onDataChange file_path");
//                        }
                    }
                }
            }
        }
        dataEvents.release();
    }

    private byte[] unzip(byte[] zipData) {
        try (ByteArrayInputStream bis = new ByteArrayInputStream(zipData); GZIPInputStream gzis = new GZIPInputStream(bis); ByteArrayOutputStream bos = new ByteArrayOutputStream()) {

            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = gzis.read(buffer)) != -1) {
                bos.write(buffer, 0, bytesRead);
            }

            return bos.toByteArray();
        } catch (IOException e) {
            logFunction.error("Watch_Fil","Error: " + e.toString() + " decompressing data.");
            return null;
        }
    }

    /*public static int failedToUpload() {
        filesFailedUpload = 0;
        // get list of files and upload
        File[] files = directory.listFiles();
        //System.out.println("files len = " + files.length);

        boolean filesExist = false;
        if (files.length > 0) {
            filesExist = true;
        }

        // MainActivity.fileCount = files.length - 1; // how many to upload (-1 to exclude auth file)
        for (int i = 0; i < files.length; i++) {
            if (files[i].getName().equals("authfile.json") || files[i].getName().endsWith(".txt")) {
                System.out.println("File name which continued: " + files[i].getName());
                continue;       // skip this file
            }
            if (MainActivity.ringRecordingState.equals("true") && files[i].getName().contains("ring.data")) {
                System.out.print("skipping the rile file.");
                continue;      // skip uploading of ring file when upload starts at application start.
            }
            *//*if(files[i].getName().equals(MainActivity.logSyncFileName) || files[i].getName().equals(MainActivity.logFileName) || files[i].getName().equals(MainActivity.logTimeFileName)){
                System.out.println("Skipping the current session's log files"); //skipping uploading current session's log files as this will be closed in OnDestroy step
                continue;
            }*//*
            if(files[i].getName().endsWith(".log")){
                System.out.println("Skipping the log files in the failed upload section"); //skipping uploading current session's log files as this will be closed in OnDestroy step
                continue;
            }
            else {
                System.out.println("File in the failed section: " + files[i].getName());
                filesFailedUpload++; // let user know if any uploads fail
            }
        }
        return filesFailedUpload;
    }*/

    private static void startUploading() {
        //System.out.println("Starting the uploading");
        //MainActivity.writeToLog("Starting dropbox upload!");
        // write out authentication file so we can attach it for dropbox upload
        writeAuthFile(getAccessToken());

        String rootDirectoryPath = MainActivity.applicationContext.getExternalFilesDir(null).getPath();
        String argAuthFile = rootDirectoryPath + "/authfile.json";
        // read auth info file.
        DbxAuthInfo authInfo = null;
       // MainActivity.writeToLog("Reading auth file");
        try {
            authInfo = DbxAuthInfo.Reader.readFromFile(argAuthFile);
        } catch (JsonReader.FileLoadException ex) {
            ex.printStackTrace();
        }

       // MainActivity.writeToLog("Creating the DbxClient");
        // Create a DbxClientV2, which is what you use to make dropbox API calls.
        // Below client identifier which we give to DBXRequestConfig is the Dropbox-API app name.
        DbxRequestConfig requestConfig = new DbxRequestConfig("CaloryChecker");
        DbxClientV2 dbxClient = new DbxClientV2(requestConfig, authInfo.getAccessToken(), authInfo.getHost());

        // 0 to 5 characters contain the participant id.
        // Creating different folder for two locations
        if (MainActivity.prev_pid_value.length() < 5) {
            folderName = "00000".substring(MainActivity.prev_pid_value.length()) + MainActivity.prev_pid_value; // This will ensure that the folder name is four digit based on the PID value
        } else {
            folderName = MainActivity.prev_pid_value;
        }

        if (MainActivity.prev_location_value.equals("South Carolina")) {
            //dropboxFolder = "/WATCH/Clemson/" + files[i].getName().substring(0, 4);
            dropboxFolder = "/WATCH/Clemson/" + folderName;
        } else if (MainActivity.prev_location_value.equals("Rhode Island")) {
            dropboxFolder = "/WATCH/Brown/" + folderName;
        } else if (MainActivity.prev_location_value.equals("None")) {
            dropboxFolder = "/WATCH/No_Location/" + folderName;
        }else if (MainActivity.prev_location_value.equals("Developer")) {
            dropboxFolder = "/WATCH/Developer/" + folderName;
        }
        //dropboxFolder = "/WATCH/" + folderName;

        System.out.println("Targeted folder to upload: " + dropboxFolder);
        logFunction.information("Dropbox","Creating directory for participant with folder name "
                + dropboxFolder);
        try {
            Files.createDirectories(Paths.get(dropboxFolder));
        } catch (Exception e) {
            e.printStackTrace();
            //logFunction.error("Dropbox", "Error: " + e.toString() + " creating directory for the participant");
        }
        // get list of files and upload
        File[] files = directory.listFiles();
       // System.out.println("files len = " + files.length);

        boolean filesExist = false;
        if (files.length > 0) {
            filesExist = true;
//            MainActivity.textViewProgressMessage.setText("Uploading files...");
        }
        //System.out.println("filesExist = " + filesExist);

        // MainActivity.fileCount = files.length - 1; // how many to upload (-1 to exclude auth file)
        for (int i = 0; i < files.length; i++) {
            if (files[i].getName().equals("authfile.json") || files[i].getName().endsWith(".txt")) {
                continue;       // skip this file
            }
            if (MainActivity.ringRecordingState.equals("true") && files[i].getName().contains("ring.data")) {
               // System.out.print("skipping the ring file.");
                continue;      // skip uploading of ring file when upload starts at application start.
            }
            if (files[i].getName().equals(MainActivity.currentLogFileName)) {
                System.out.println("skipping the current session log file");
                //System.out.println("Log file name in the currentLogFile: " + files[i].getName());

                continue;
            }
            if(files[i].getName().equals("ImagesFolder")){
                continue;
            }
            System.out.println("File to upload: " +files[i].getName());
            Log.d("DropBoxUpload", "File to upload: " +files[i].getName());

            String localPath = rootDirectoryPath + "/" + files[i].getName();
            //System.out.println("local path = " + localPath);
            File localFile = new File(localPath);
            //System.out.println("localFile = " + localFile.getName());

            String dropboxPath = dropboxFolder + "/" + files[i].getName();

            //System.out.println("dropbox path = " + dropboxPath);
            //upload the file
            FileMetadata returnMetadata = uploadToDropBox(dbxClient, localFile, dropboxPath);
            if (Objects.nonNull(returnMetadata) && returnMetadata.getSize() == localFile.length()) {
                //LocalDateTime now = LocalDateTime.now();
                //System.out.println("File " + files[i].getName() + " uploaded successfully.");
                logFunction.information("Dropbox", "File " + files[i].getName() + " uploaded successfully.");
                //MainActivity.writeToLogTime("File " + files[i].getName() + " uploaded successfully at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")) );
                // delete file from phone storage
                /*if (!files[i].getName().endsWith(".jpg")) {
                    localFile.delete();
                }*/
                if(MainActivity.newImageFolder.exists()){
                    localFile.delete();
                }else{
                    if(!files[i].getName().endsWith(".jpg")){
                        localFile.delete();
                    }
                }


                // MainActivity.fileCount--;
            } else {
                filesFailedUpload++;
            }
            //MainActivity.textTop.setText(MainActivity.fileCount + "");
            //MainActivity.textBottom.setText(filesFailedUpload + "");
        }
        //System.out.println("Files failed to upload = " + filesFailedUpload);
        logFunction.information("Dropbox", "Files failed to upload = " + filesFailedUpload);

        MainActivity.failedUpload = filesFailedUpload;
        // cleanup -- delete the auth file
        File authFile = new File(argAuthFile);
        authFile.delete();
    }

    private static String getAccessToken() {
        //MainActivity.writeToLog("Getting access token");
        // If already fetched access token is not expired, then use the same access token.
        if (Objects.nonNull(dropBoxAccessToken) && !isExpired(dropBoxAccessToken)) {
            return dropBoxAccessToken;
        }

        //Move the app key, secret key, and refresh token in different file for making the code public.
        String refreshToken = token.getRefreshToken();
        String clientId = token.getClientId();
        String clientSecret = token.getClientSecret();

//        String command = "curl https://api.dropbox.com/oauth2/token -d refresh_token=" + refreshToken + " -d grant_type=refresh_token -d client_id=" + clientId + " -d client_secret=" + clientSecret;
       // System.out.println("Getting the access token");
        try {
            URL url = new URL("https://api.dropbox.com/oauth2/token");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoOutput(true);
            connection.setRequestMethod("POST");

            // Create the request data as a URL-encoded string
            String requestData = encodeParameters(Map.of("refresh_token", refreshToken, "grant_type", "refresh_token", "client_id", clientId, "client_secret", clientSecret));
            try (DataOutputStream outputStream = new DataOutputStream(connection.getOutputStream())) {
                outputStream.writeBytes(requestData);
                outputStream.flush();
            }

            int responseCode = connection.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                InputStream inputStream = connection.getInputStream();
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                String line;
                while ((line = reader.readLine()) != null) {
                    JSONObject jsonObject = new JSONObject(line);
                    dropBoxAccessToken = jsonObject.getString("access_token");
                }
                reader.close();
            } else {
              //  System.out.println("HTTP request failed with response code: " + responseCode);
                logFunction.error("Dropbox","HTTP request failed with response code: " + responseCode);
            }

            connection.disconnect();
        } catch (Exception exception) {
           // System.out.println("Got the exception");
            logFunction.error("Dropbox", "Got exception " + exception);
            exception.printStackTrace();
        }

        //System.out.println("Access token = " + dropBoxAccessToken);
        //MainActivity.writeToLog("Got the access token = " + dropBoxAccessToken);
        return dropBoxAccessToken;
    }

    private static boolean isExpired(String dropBoxAccessToken) {
        //MainActivity.writeToLog("Checking if dropbox access token is expired or not");
        try {
            URL url = new URL("https://api.dropboxapi.com/2/users/get_current_account");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Authorization", "Bearer " + dropBoxAccessToken);

            int responseCode = connection.getResponseCode();
            // Response code 401(HTTP_UNAUTHORIZED) indicates that the "Access Token" is expired.
            if (responseCode == HttpURLConnection.HTTP_UNAUTHORIZED) {
                return true;
            }
        } catch (Exception exception) {
            exception.printStackTrace();
        }
        return false;
    }

    private static String encodeParameters(Map<String, String> params) {
       // MainActivity.writeToLog("Encoding parameters");
        StringBuilder result = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (result.length() > 0) {
                result.append("&");
            }
            result.append(entry.getKey());
            result.append("=");
            result.append(entry.getValue());
        }
        return result.toString();
    }


    private static void writeAuthFile(String accessToken) {
       // MainActivity.writeToLog("Writing access token to auth file");
        String rootDirectoryPath = MainActivity.applicationContext.getExternalFilesDir(null).getPath();
        String argAuthFile = rootDirectoryPath + "/authfile.json";
        try {
            BufferedWriter writer = null;
            writer = Files.newBufferedWriter(new File(argAuthFile).toPath());
            writer.write("{\n" + "  \"access_token\" : \"" + accessToken + "\"\n" + "}");
            writer.close();
        } catch (IOException ex) {
            logFunction.error("Dropbox", "Exception: " + ex.toString() + " writing access token to auth file");
        }
    }

    private static FileMetadata uploadToDropBox(DbxClientV2 dbxClient, File localFile, String dropboxPath) {
       // MainActivity.writeToLog("Performing upload call on DbxClient");
        FileMetadata metadata = null;
        try (InputStream in = new FileInputStream(localFile)) {
            metadata = dbxClient.files().uploadBuilder(dropboxPath)
                    .withMode(WriteMode.ADD)
                    .withClientModified(new Date(localFile.lastModified()))
                    .uploadAndFinish(in);
        } catch (DbxException | IOException ex) {
            //logFunction.error("Dropbox", "Got exception in uploadToDropbox = " + ex);
            //System.out.println("Exception in uploadToDropbox = ");
            ex.printStackTrace();
        }
        return metadata;
    }

    static void displayNotification() {
        //MainActivity.writeToLog("Displaying notification");
        notificationManager.notify(notificationID, notification);
    }

    static void cancelNotification() {
       // MainActivity.writeToLog("cancelling notification");
        notificationManager.cancel(notificationID);
    }

    /*public static class DropboxUploadRunnable implements Runnable {
        public void run() {
            if (connectivityManager != null) {
                filesFailedUpload = 0;
                System.out.println("Connected to wifi so starting uploading.");
                NetworkInfo networkInfo = connectivityManager.getActiveNetworkInfo();
                if (networkInfo != null && networkInfo.getType() == ConnectivityManager.TYPE_WIFI) {

                    System.out.println("Connected to wifi so starting uploading.");
                    MainActivity.writeToLog("Connected to wifi so started uploading.");
                    LocalDateTime now = LocalDateTime.now();
                    MainActivity.writeToLogTime("Connected to wifi and start uploading at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                    startUploading(); // Connected to Wi-Fi
                } else {
                    MainActivity.failedUpload = failedToUpload();
                }
            }
        }
    }*/
    public static class DropboxUploadRunnable implements Runnable {
        public void run() {
            if (connectivityManager != null) {
                filesFailedUpload = 0;
               // System.out.println("Connected to wifi so starting uploading.");
                NetworkInfo networkInfo = connectivityManager.getActiveNetworkInfo();
                if (networkInfo != null) {
                    if(networkInfo.getType() == ConnectivityManager.TYPE_WIFI || networkInfo.getType()==ConnectivityManager.TYPE_MOBILE){
                        //System.out.println("Connected to wifi or mobile net so starting uploading.");
                        logFunction.information("Dropbox", "Connected to wifi or mobile net so started uploading.");
                        //LocalDateTime now = LocalDateTime.now();
                        //MainActivity.writeToLogTime("Connected to wifi or mobile net and start uploading at: " + now.format(DateTimeFormatter.ofPattern("HH-mm-ss")));
                        if(uploadButton == "clicked"){
                            //System.out.println("Upload started");
                            //Toast.makeText(context.getApplicationContext(), "Please connect to an internet connection!", Toast.LENGTH_LONG).show();
                            new Handler(Looper.getMainLooper()).post(new Runnable() {
                                @Override
                                public void run() {
                                    Toast.makeText(context.getApplicationContext(), "Uploading to the Dropbox has started", Toast.LENGTH_SHORT).show();
                                }
                            });
                        }
                        startUploading(); // Connected to Wi-Fi
                    }

                } else {
                    //MainActivity.failedUpload = failedToUpload();
                    if(uploadButton == "clicked"){
                        //System.out.println("Failed to connect internet");
                        uploadButton = "";
                        //This toast message will be shown only when the upload to Dropbox button in the settings is clicked
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                Toast.makeText(context.getApplicationContext(), "Please connect to an internet connection!", Toast.LENGTH_SHORT).show();
                            }
                        });
                    }
                }
            }
        }
    }


    //For increasing the text size of the toast message
    public void showToast(Context context, String message, int duration) {
        // Use the context to create LayoutInflater and show custom toast
        Context appContext = getApplicationContext();
        LayoutInflater inflater = LayoutInflater.from(appContext);
        View layout = inflater.inflate(R.layout.toast_layout, null);

        TextView text = layout.findViewById(R.id.toast_text);
        text.setText(message);

        Toast toast = new Toast(context);
        if (duration == 0) {
            toast.setDuration(Toast.LENGTH_SHORT);
        } else {
            toast.setDuration(Toast.LENGTH_LONG);
        }

        toast.setView(layout);
        toast.show();
    }

}
