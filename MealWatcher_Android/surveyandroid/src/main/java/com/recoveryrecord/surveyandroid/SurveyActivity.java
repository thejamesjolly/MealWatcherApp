package com.recoveryrecord.surveyandroid;

import android.content.DialogInterface;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.LayoutRes;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.recoveryrecord.surveyandroid.condition.CustomConditionHandler;
import com.recoveryrecord.surveyandroid.validation.DefaultValidator;
import com.recoveryrecord.surveyandroid.validation.FailedValidationListener;
import com.recoveryrecord.surveyandroid.validation.Validator;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public abstract class SurveyActivity extends AppCompatActivity implements FailedValidationListener {
    private static final String TAG = SurveyActivity.class.getSimpleName();

    public static final String JSON_FILE_NAME_EXTRA = "json_filename";
    public static final String SURVEY_TITLE_EXTRA = "survey_title";

    private SurveyState mState;
    static String surveyStartTime;
    private OnSurveyStateChangedListener mOnSurveyStateChangedListener;
    private RecyclerView mRecyclerView;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(getLayoutResId());
        setTitle(getSurveyTitle());

        SurveyQuestions surveyQuestions = createSurveyQuestions();
        Log.d(TAG, "Questions = " + surveyQuestions);

        mState = createSurveyState(surveyQuestions);
        setupRecyclerView();

        LocalDateTime now = null;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            now = LocalDateTime.now();
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd-HH-mm-ss");
            surveyStartTime = now.format(formatter);
        }
    }

    // This method is executed when the exist button in survey layout is clicked.
    public void existButtonClicked(View view) {
        new AlertDialog.Builder(SurveyActivity.this)
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
//                                Thread thread = ControlWatch.uploadToDropboxThread;
//                                if (thread.getState() == Thread.State.NEW) {
//                                    thread.start();
//                                }
                        SurveyActivity.super.onBackPressed();
                    }
                }).show();
    }

    protected @LayoutRes int getLayoutResId() {
        return R.layout.activity_survey;
    }

    protected SurveyQuestions createSurveyQuestions() {
        return SurveyQuestions.load(this, getJsonFilename());
    }

    protected void setupRecyclerView() {
        mRecyclerView = findViewById(R.id.recycler_view);
        mRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        mRecyclerView.addItemDecoration(new SpaceOnLastItemDecoration(getDisplayHeightPixels()));
        mRecyclerView.setItemAnimator(new SurveyQuestionItemAnimator());
        mRecyclerView.setAdapter(new SurveyQuestionAdapter(this, mState));
    }

    protected SurveyState createSurveyState(SurveyQuestions surveyQuestions) {
        return new SurveyState(surveyQuestions)
                .setValidator(getValidator())
                .setCustomConditionHandler(getCustomConditionHandler())
                .setSubmitSurveyHandler(getSubmitSurveyHandler())
                .initFilter();
    }

    private int getDisplayHeightPixels() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        return displayMetrics.heightPixels;
    }

    @Override
    protected void onStart() {
        super.onStart();
        mState.addOnSurveyStateChangedListener(getOnSurveyStateChangedListener());
    }

    @Override
    protected void onStop() {
        super.onStop();
        mState.removeOnSurveyStateChangedListener(getOnSurveyStateChangedListener());
    }

    protected String getSurveyTitle() {
        if (getIntent().hasExtra(SURVEY_TITLE_EXTRA)) {
            return getIntent().getStringExtra(SURVEY_TITLE_EXTRA);
        }
        return null;
    }

    protected String getJsonFilename() {
        if (getIntent().hasExtra(JSON_FILE_NAME_EXTRA)) {
            return getIntent().getStringExtra(JSON_FILE_NAME_EXTRA);
        }
        return null;
    }

    protected Validator getValidator() {
        return new DefaultValidator(this);
    }

    // Subclasses should return a non-null if they are using custom show_if conditions.
    protected CustomConditionHandler getCustomConditionHandler() {
        return null;
    }

    protected AnswerProvider getAnswerProvider() {
        return mState;
    }

    public void validationFailed(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    public SubmitSurveyHandler getSubmitSurveyHandler() {
        return new DefaultSubmitSurveyHandler(this);
    }

    public RecyclerView getRecyclerView() {
        return mRecyclerView;
    }

    public OnSurveyStateChangedListener getOnSurveyStateChangedListener() {
        if (mOnSurveyStateChangedListener == null) {
            mOnSurveyStateChangedListener = new DefaultOnSurveyStateChangedListener(this, getRecyclerView());
        }
        return mOnSurveyStateChangedListener;
    }

    public void setOnSurveyStateChangedListener(OnSurveyStateChangedListener listener) {
        mOnSurveyStateChangedListener = listener;
    }
}
