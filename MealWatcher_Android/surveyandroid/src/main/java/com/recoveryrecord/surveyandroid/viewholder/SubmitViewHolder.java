package com.recoveryrecord.surveyandroid.viewholder;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Build;
import android.view.View;
import android.widget.Button;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.recoveryrecord.surveyandroid.AnswerProvider;
import com.recoveryrecord.surveyandroid.R;
import com.recoveryrecord.surveyandroid.SubmitSurveyHandler;
import com.recoveryrecord.surveyandroid.question.QuestionsWrapper.SubmitData;

public class SubmitViewHolder extends RecyclerView.ViewHolder {

    private Button submitButton;
    private Activity activity;

    public SubmitViewHolder(Activity surveyActivity, @NonNull View itemView) {
        super(itemView);
        activity = surveyActivity;
        submitButton = itemView.findViewById(R.id.submit_button);
    }

    public void bind(final SubmitData submitData, final AnswerProvider answerProvider, final SubmitSurveyHandler submitSurveyHandler) {
        submitButton.setText(submitData.buttonTitle);
        submitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                submitSurveyHandler.submit(submitData.url, answerProvider.allAnswersJson());

                AlertDialog.Builder builder1 = new AlertDialog.Builder(activity);
                builder1.setMessage("Survey Submitted Successfully!");
                builder1.setCancelable(true);

                builder1.setPositiveButton(
                        "OK",
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int id) {
                                dialog.cancel();
                                System.out.println("is activity = " + (activity instanceof Activity));
                                if (activity instanceof Activity) {
                                    System.out.println("inside if");
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        activity.finishAndRemoveTask();
                                    }
                                }
                            }
                        });

                AlertDialog alert11 = builder1.create();
                alert11.show();
            }
        });
    }
}
