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

import static research.mealwatcher.MainActivity.prev_pid_value;

import android.content.DialogInterface;
import android.os.Bundle;

import androidx.appcompat.app.AlertDialog;

import com.recoveryrecord.surveyandroid.Answer;
import com.recoveryrecord.surveyandroid.DefaultSubmitSurveyHandler;
import com.recoveryrecord.surveyandroid.SubmitSurveyHandler;
import com.recoveryrecord.surveyandroid.SurveyActivity;
import com.recoveryrecord.surveyandroid.condition.CustomConditionHandler;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Calendar;
import java.util.Map;

public class Survey extends SurveyActivity
        implements CustomConditionHandler {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    protected String getSurveyTitle() {
        return "CalorieCheck Survey!";
    }

    @Override
    protected String getJsonFilename() {
        return "SurveyQuestions.json";
    }

    @Override
    protected CustomConditionHandler getCustomConditionHandler() {
        return this;
    }

    @Override
    public boolean isConditionMet(Map<String, Answer> answers, Map<String, String> extra) {
        String id = extra.get("id");
        if (id != null && id.equals("check_age")) {
            if (answers.get("birthyear") == null || answers.get("age") == null || extra.get("wiggle_room") == null) {
                return false;
            }
            String birthYearStr = answers.get("birthyear").getValue();
            Integer birthYear = Integer.valueOf(birthYearStr);
            String ageStr = answers.get("age").getValue();
            Integer age = Integer.valueOf(ageStr);
            Integer wiggleRoom = Integer.valueOf(extra.get("wiggle_room"));
            Calendar calendar = Calendar.getInstance();
            int currentYear = calendar.get(Calendar.YEAR);
            return Math.abs(birthYear + age - currentYear) > wiggleRoom;
        } else {
            return false;
        }
    }

    @Override
    public void onBackPressed() {
        if (!getOnSurveyStateChangedListener().scrollBackOneQuestion()) {
            new AlertDialog.Builder(this)
                    .setTitle(com.recoveryrecord.surveyandroid.R.string.close_survey)
                    .setMessage(com.recoveryrecord.surveyandroid.R.string.are_you_sure_you_want_to_close)
                    .setNeutralButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            dialog.dismiss();
                        }
                    }).setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            Survey.super.onBackPressed();
                            MainActivity.takeSurvey.setChecked(false);
                        }
                    }).show();
        }
    }

    @Override
    public SubmitSurveyHandler getSubmitSurveyHandler() {
        return new DefaultSubmitSurveyHandler(this) {
            @Override
            public void submit(String url, String jsonQuestionAnswerData) {
                MainActivity.takeSurvey.setChecked(true);
                /*
                Here local indicates that answers should be stored in local file system of the phone.
                 */
                if(url.equals("local")) {
                    File directory = getExternalFilesDir(null);
                    String filePrefix = null;
                    if(prev_pid_value.length()<5){
                        filePrefix   = "00000".substring(MainActivity.prev_pid_value.length()) + MainActivity.prev_pid_value + "-"; // This will ensure that the folder name is four digit based on the PID value
                    }else{
                        filePrefix = prev_pid_value + "-";
                    }
                    LocalDateTime now = LocalDateTime.now();
                    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd-HH-mm-ss");
                    filePrefix += now.format(formatter) + "-survey";

                    JSONObject json = null;
                    String path = directory.toString() + "/" + filePrefix + ".json";
                    try (BufferedWriter writer = new BufferedWriter(new FileWriter(path))) {
                        json = new JSONObject(jsonQuestionAnswerData);
                        writer.write(json.toString(4));

                        // Uploading to dropbox at the end of the survey.
                        Thread thread = ControlWatch.uploadToDropboxThread;
                        if (thread.getState() == Thread.State.NEW) {
                            thread.start();
                        } else if (thread.getState() == Thread.State.TERMINATED) {
                            ControlWatch.uploadToDropboxThread = new Thread(new ControlWatch.DropboxUploadRunnable());
                            ControlWatch.uploadToDropboxThread.start();
                        }
                    } catch (JSONException | IOException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
        };
    }
}
