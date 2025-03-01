
/*
** This code implements the eating detector of Dong et. al.
** The implementation allows real-time processing.  It reads
** one sensor reading at a time from accelerometers and gyroscopes,
** smoothes it, checks for peaks, and upon finding a peak
** classifies the peak-to-peak period of data.
**
** The memory footprint is kept small by maintaining a
** buffer of data since the last peak, and upon classifying a
** peak-to-peak period, shifting the buffer to start at the new peak.
**
** This code is intended to integrate with Java code for an
** Android smartwatch within an Android Studio project.
** More details about the whole design can be found in its README.
**
** Note:  max time between analyses is 1 hour even if peak not found
**
** The C code exported to the Java side consists of 3 functions:
** (1) InitClassifier()
**	allocates memory for buffers
**	opens file for writing data
**	calculates smoothing kernel
**	initializes counters
** (2) NewData()
**	takes as input new sensor reading
**	writes data to file
**	looks for peaks
**	if peak found, analyze
**	if analysis = eating, return 1
**	all other paths return 0
** (3) CloseClassifier()
**	releases memory
**	closes data file
*/

#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>

/* macros for constants */
#define    MAX_DATA 24*60*60*15    /* 24 hours of 15 Hz data */
#define    MAX_SEG  1*60*60*15    /* 1 hour of 15 Hz data */
/* if M_E not defined in library, uncomment line below */
// #define	M_E 2.71828182845904523536	/* used for smoothing */
#define    SMOOTH_SIGMA 10.0    /* units are relative to window size */
#define    SUM_WINDOW 900        /* 1 minute at 15 Hz */
#define    SQR(x) ((x)*(x))
#define    NUM_FEAT 4
#define    VERY_SMALL 0.000001    /* used for testing equality to zero */
#define    REG_ROLL_THRESH    10.0    /* deg/sec */
#define    REAL_TIME_DELAY 450    /* 30 sec delay between offline and realtime */
#define    SAVE_FILE_FORMAT 0    /* 0 => .anw binary, 1=> .txt file */

/* function prototypes -- internal to C side */
int FindPeak(float *, int);

void CalculateFeatures(float *buffer[6], int, int, double *);

int Classify(double feat[NUM_FEAT]);

/* global variables -- internal to C side */
FILE *fptw;            /* for writing live sensor data to file */
FILE *fpte;            /* for writing events file */
float sensors[6];        /* latest sensor readings */
int TotalData;        /* counter of all data received */
float raw_data[6][15];    /* 1 sec buffer of most recent 15 raw data */
float *smoothed_buffer[6];    /* buffer (up to 1 hour) of smoothed data */
int TotalSmoothedData;    /* counter of data in smoothed buffer */
float kernel[15];        /* used for smoothing */
float denominator;        /* used for smoothing */
float *sum_accel;        /* equal in length to smoothed buffer */
float total_accel;        /* running count simplifies calculation */
int BufferStart;        /* offset of current buffer start relative
				** to when classifier initialized
				** (units are indices @ 15 Hz) */
int StartAnalysis;        /* buffer needs to maintain enough data to
				** calculate sum(accel) (1 minute) and to
				** finish last peak detected (arbitrary).
				** This indicates where in current buffer
				** the last classifier analysis finished
				** and hence where to start next analysis. */


/*******************************************************/
/* the following 3 functions are exported to Java side */
/*******************************************************/

JNIEXPORT void JNICALL Java_research_eatmon2_StayAwake_InitClassifier(
        JNIEnv *env,
        jobject thisObj) {
    int a, i;
    struct tm *local;
    time_t t;
    char filename[320], fileprefix[80];

    /* allocate memory */
    for (a = 0; a < 6; a++)
        smoothed_buffer[a] = (float *) calloc(MAX_SEG, sizeof(float));
    sum_accel = (float *) calloc(MAX_SEG, sizeof(float));
    /* initialize raw data buffer (1 sec) to zero for first smoothing */
    for (i = 0; i < 15; i++)
        for (a = 0; a < 6; a++)
            raw_data[a][i] = 0.0;

    /* calculate Gaussian kernel weights */
    denominator = 0.0;
    for (i = 0; i < 15; i++) {
        kernel[14 - i] = pow(M_E, (0.0 - SQR(i)) / (2.0 * SQR(SMOOTH_SIGMA)));
        denominator += kernel[14 - i];
    }

    /* get the localtime to use for filenames and events */
    t = time(NULL);
    local = localtime(&t);
    sprintf(fileprefix, "%d-%02d-%02d_%02d_%02d_%02d",
            local->tm_year + 1900, local->tm_mon + 1, local->tm_mday,
            local->tm_hour, local->tm_min, local->tm_sec);

    /* Should be checking that file opened successfully.
    ** If not, app will just crash with no feedback. */
    if (SAVE_FILE_FORMAT == 0)
        sprintf(filename, "storage/emulated/0/Android/data/research.mealwatcher/files/%s.anw",
                fileprefix);
    else
        sprintf(filename, "storage/emulated/0/Android/data/research.mealwatcher/files/%s.txt",
                fileprefix);
    fptw = fopen(filename, "wb");

    sprintf(filename, "storage/emulated/0/Android/data/research.mealwatcher/files/%s-events.txt",
            fileprefix);
    fpte = fopen(filename, "wb");
    fprintf(fpte, "START %d-%02d-%02d %02d:%02d:%02d\n",
            local->tm_year + 1900, local->tm_mon + 1, local->tm_mday,
            local->tm_hour, local->tm_min, local->tm_sec);
    fflush(fpte);

    TotalData = 0;        /* amount of data written to file */
    TotalSmoothedData = 0;    /* amount of data currently in buffer */
    BufferStart = 0;        /* global index (in day) of beginning of buffer */
    StartAnalysis = 0;    /* buffer position to start analysis */
}


JNIEXPORT jint JNICALL Java_research_eatmon2_StayAwake_NewData(
        JNIEnv *env,
        jobject thisObj,
        jdouble accx,    /* all axes assumed to fit Yujie's model here */
        jdouble accy,    /* see Java code for android->Yujie transform */
        jdouble accz,    /* units assumed to be G (accel) and deg/sec (gyro) */
        jdouble yaw,
        jdouble pitch,
        jdouble roll) {
    int a, i;
    float sum;
    int FoundPeak, DataToKeep;
    double features[NUM_FEAT];
    int MD;


    if (1)    /* the while(1) loop is on the Java side, so just do it */
    {
        /* shift previous 14 sensor readings backward in array */
        for (i = 0; i < 14; i++)
            for (a = 0; a < 6; a++)
                raw_data[a][i] = raw_data[a][i + 1];

        /* new sensor reading goes into array index [14] (15th position) */
        raw_data[0][14] = (float) accx;    /* x accel */
        raw_data[1][14] = (float) accy;    /* y accel */
        raw_data[2][14] = (float) accz;    /* z accel */
        raw_data[3][14] = (float) yaw;    /* yaw */
        raw_data[4][14] = (float) pitch;    /* pitch */
        raw_data[5][14] = (float) roll;    /* roll */

        /* write sensor readings to file */
        if (SAVE_FILE_FORMAT == 0) {
            fwrite(&(raw_data[0][14]), 4, 1, fptw);
            fwrite(&(raw_data[1][14]), 4, 1, fptw);
            fwrite(&(raw_data[2][14]), 4, 1, fptw);
            fwrite(&(raw_data[3][14]), 4, 1, fptw);
            fwrite(&(raw_data[4][14]), 4, 1, fptw);
            fwrite(&(raw_data[5][14]), 4, 1, fptw);
        } else {
            fprintf(fptw, "%f %f %f %f %f %f\n",
                    raw_data[0][14], raw_data[1][14], raw_data[2][14],
                    raw_data[3][14], raw_data[4][14], raw_data[5][14]);
        }

        TotalData++;
        if (TotalData >= MAX_DATA)
            return (2);    /* let app know that it should close because it has been
		** running for more than 24 hours */

        /* smooth data -- first 1 sec does not match desktop but
        ** simplifies code and uses very little memory */
        for (a = 0; a < 6; a++) {
            sum = 0.0;
            for (i = 0; i < 15; i++)
                sum += (raw_data[a][14 - i] * kernel[i] / denominator);
            smoothed_buffer[a][TotalSmoothedData] = sum;
        }
        TotalSmoothedData++;

        /* calculate sum(accel), window centered on datum */
        if (TotalSmoothedData <= SUM_WINDOW) {
            total_accel = 0;  /* calculate brute force for first minute */
            for (i = 0; i < TotalSmoothedData; i++)
                total_accel += (fabs(smoothed_buffer[0][i]) +
                                fabs(smoothed_buffer[1][i]) + fabs(smoothed_buffer[2][i]));
            sum_accel[TotalSmoothedData - 1] = total_accel / (float) (TotalSmoothedData);
            return (0);    /* less than 1 min data, nothing more to do yet */
        }

        /* total_accel keeps running sum, from which we add/subtract */
        total_accel -= (fabs(smoothed_buffer[0][TotalSmoothedData - SUM_WINDOW - 1]) +
                        fabs(smoothed_buffer[1][TotalSmoothedData - SUM_WINDOW - 1]) +
                        fabs(smoothed_buffer[2][TotalSmoothedData - SUM_WINDOW - 1]));
        total_accel += (fabs(smoothed_buffer[0][TotalSmoothedData - 1]) +
                        fabs(smoothed_buffer[1][TotalSmoothedData - 1]) +
                        fabs(smoothed_buffer[2][TotalSmoothedData - 1]));
        sum_accel[TotalSmoothedData - 1] = total_accel / (float) (SUM_WINDOW);

        if (TotalData % 900 != 0)
            return (0);    /* only test for eating once per minute to save calculations */

        /* check for peak */
        FoundPeak = FindPeak(sum_accel, TotalSmoothedData);
        if (FoundPeak < 0 && TotalSmoothedData < MAX_SEG)
            return (0);    /* wait for peak or max data to analyze */
        FoundPeak = FoundPeak - REAL_TIME_DELAY;    /* back up 30 sec to match offline */

        /* analyze data */
        CalculateFeatures(smoothed_buffer, StartAnalysis, FoundPeak, features);
        MD = Classify(features);

        /* flush buffers keeping data since last detected peak */
        DataToKeep = TotalSmoothedData - FoundPeak;
        StartAnalysis = 0;
        if (TotalSmoothedData - FoundPeak < SUM_WINDOW) {    /* check if we have at least 1 min */
            StartAnalysis = SUM_WINDOW - (TotalSmoothedData - FoundPeak);
            DataToKeep = SUM_WINDOW;    /* must be minimum of 1 min */
        }
        for (i = 0; i < DataToKeep; i++) {
            sum_accel[i] = sum_accel[TotalSmoothedData - DataToKeep + i];
            for (a = 0; a < 6; a++)
                smoothed_buffer[a][i] =
                        smoothed_buffer[a][TotalSmoothedData - DataToKeep + i];
        }
        BufferStart += TotalSmoothedData - DataToKeep;
        TotalSmoothedData = DataToKeep;

        if (MD == 0)
            return (1);    /* detected eating */
        else
            return (0);
    }

}


JNIEXPORT void JNICALL Java_research_eatmon2_StayAwake_CloseClassifier(
        JNIEnv *env,
        jobject thisObj) {
    int a;
    struct tm *local;
    time_t t;

    fclose(fptw);    /* file pointer writing live sensor data to file */

    /* get the localtime and write to events file */
    t = time(NULL);
    local = localtime(&t);
    fprintf(fpte, "END %d-%02d-%02d %02d:%02d:%02d\n",
            local->tm_year + 1900, local->tm_mon + 1, local->tm_mday,
            local->tm_hour, local->tm_min, local->tm_sec);
    fclose(fpte);

    /* we could analyze remaining data in buffer... */
/*
CalculateFeatures(smoothed_buffer,StartAnalysis,TotalSmoothedData,features);
MD=Classify(features);
if (MD == 0)
  printf("Eating suspected %d...%d\n",
	StartAnalysis+BufferStart,
	TotalSmoothedData+BufferStart);
*/

    /* cleanup */
    for (a = 0; a < 6; a++)
        free(smoothed_buffer[a]);
    free(sum_accel);
}


/*************************************************************/
/* the following functions are interal to the C side library */
/*************************************************************/


int FindPeak(float *sum_accel,
             int TotalData) {
    float PeakMaxValue, T1, T2;
    float HysteresisRatio = 2.0;
    float T1_min = 0.02;
    int t, t_left, t_mid;

    /* use hysteresis approach to find peak */
    for (t = SUM_WINDOW; t < TotalData; t++) {
        T1 = sum_accel[t];    /* set initial thresholds based upon first value */
        if (T1 < T1_min)
            T1 = T1_min;
        T2 = HysteresisRatio * T1;
        /* the signal has to go 2x larger than its previous minimum */
        while (sum_accel[t] < T2) {
            if (sum_accel[t] < T1)  /* if signal goes lower, adjust thresholds down */
            {
                T1 = sum_accel[t];
                if (T1 < T1_min)
                    T1 = T1_min;
                T2 = HysteresisRatio * T1;
            }
            t++;
            if (t >= TotalData)
                break;
        }
        if (t >= TotalData)
            break;

        t_left = t;    /* left side of peak */
        PeakMaxValue = sum_accel[t];

        while (sum_accel[t] > T1 &&
               t < TotalData) {    /* peak lasts while larger than the minimum */
            if (sum_accel[t] > PeakMaxValue) {
                t_mid = t;
                PeakMaxValue = sum_accel[t];
                /* readjust lower bound as peak gets higher */
                T1 = PeakMaxValue / HysteresisRatio;
            }
            t++;
        }
        break;    /* only looking for one peak, end here */
    }

    if (t >= TotalData)
        return (-1);    /* no peak found, or peak hasn't ended yet */

    return (t_mid);    /* return index of max value in peak */
}


void CalculateFeatures(float *Smoothed[6],    /* smoothed data buffer */
                       int StartIndex,        /* start analysis */
                       int EndIndex,        /* end analysis */
                       double Feature[NUM_FEAT])    /* returned */

{
    int i, b, t, time_moving, stopped_moving, valid_data;
    double mean_roll;

    /* [0] calculate mean absolute deviation of roll */
    mean_roll = 0.0;
    valid_data = EndIndex - StartIndex;
    for (t = StartIndex; t < EndIndex; t++) {    /* assume all data is valid (device was on) */
        mean_roll += Smoothed[5][t];
    }
    mean_roll /= (double) valid_data;
    Feature[0] = 0.0;
    for (t = StartIndex; t < EndIndex; t++)
        Feature[0] += fabs(Smoothed[5][t] - mean_roll);
    Feature[0] /= (double) valid_data;

    /* [1] calculate regularity of roll */
    time_moving = 0;
    for (t = StartIndex; t < EndIndex; t++) {
        if (Smoothed[5][t] > REG_ROLL_THRESH) {
            while (t < EndIndex && Smoothed[5][t] > REG_ROLL_THRESH) {
                t++;
                time_moving++;
            }
            stopped_moving = t;
            while (t < EndIndex &&
                   t - stopped_moving < 15 * 8) {        /* 8 seconds after stopped moving */
                t++;
                time_moving++;
            }
        }
    }
    Feature[1] = (double) time_moving / (double) valid_data;

    /* [2] calculate avg sum_accel */
    Feature[2] = 0.0;
    for (t = StartIndex; t < EndIndex; t++)
        Feature[2] += (fabs(Smoothed[0][t]) + fabs(Smoothed[1][t]) + fabs(Smoothed[2][t]));
    Feature[2] /= (double) valid_data;

    /* [3] calculate ratio of rotational motion to linear motion */
    b = 0;
    Feature[3] = 0.0;
    for (t = StartIndex; t < EndIndex; t++)
        if (fabs(Smoothed[0][t]) + fabs(Smoothed[1][t]) + fabs(Smoothed[2][t])
            > VERY_SMALL)  /* avoid numeric instability */
        {
            Feature[3] += ((fabs(Smoothed[3][t]) + fabs(Smoothed[4][t]) +
                            fabs(Smoothed[5][t])) /
                           (fabs(Smoothed[0][t]) + fabs(Smoothed[1][t]) + fabs(Smoothed[2][t])));
            b++;
        }
    Feature[3] /= (double) b;

}


/* returns 0 if p(EA) > p(non), else 1 */

int Classify(double features[NUM_FEAT]) {
    int f;
    double prob[NUM_FEAT][2], total_prob[2];
    int MD;
    double feature_mean[4][2] = {{13.54, 9.48}, {0.6554, 0.4506}, \
                {0.0409, 0.0457}, {881, 575}};
    double feature_var[4][2] = {{23.63, 65.43}, {0.0182, 0.0770}, \
                {0.0004, 0.0021}, {43902, 57190}};

    for (f = 0; f < NUM_FEAT; f++) {
        prob[f][0] = (1.0 / sqrt(2.0 * M_PI * feature_var[f][0])) *
                     pow(M_E, 0.0 - SQR(features[f] - feature_mean[f][0]) /
                                    (2.0 * feature_var[f][0]));
        prob[f][1] = (1.0 / sqrt(2.0 * M_PI * feature_var[f][1])) *
                     pow(M_E, 0.0 - SQR(features[f] - feature_mean[f][1]) /
                                    (2.0 * feature_var[f][1]));
    }
    total_prob[0] = 0.5;
    total_prob[1] = 1.0 - total_prob[0];
    for (f = 0; f < NUM_FEAT; f++) {
        total_prob[0] *= prob[f][0];
        total_prob[1] *= prob[f][1];
    }
    if (total_prob[0] > total_prob[1])
        MD = 0;    /* EA */
    else
        MD = 1;    /* nonEA */

    return (MD);
}

