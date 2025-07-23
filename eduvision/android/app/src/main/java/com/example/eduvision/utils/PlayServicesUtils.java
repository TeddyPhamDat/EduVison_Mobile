package com.example.eduvision.utils;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

/**
 * Helper class to check Google Play Services availability
 */
public class PlayServicesUtils {
    private static final String TAG = "PlayServicesUtils";
    private static final int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

    /**
     * Check if Google Play Services is available and up to date.
     * Show dialog if necessary.
     * 
     * @param activity The activity context to use for resolution dialogs
     * @return true if Google Play Services is available and up to date
     */
    public static boolean checkPlayServices(Activity activity) {
        GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
        int resultCode = apiAvailability.isGooglePlayServicesAvailable(activity);
        
        if (resultCode != ConnectionResult.SUCCESS) {
            Log.d(TAG, "Google Play Services is not available (status=" + resultCode + ")");
            
            if (apiAvailability.isUserResolvableError(resultCode)) {
                Log.d(TAG, "Google Play Services error is resolvable, showing dialog");
                apiAvailability.getErrorDialog(activity, resultCode, PLAY_SERVICES_RESOLUTION_REQUEST)
                        .show();
            } else {
                Log.d(TAG, "Google Play Services error is not resolvable");
                // Direct user to Play Store to install/update
                openPlayServicesInPlayStore(activity);
            }
            
            return false;
        }
        
        Log.d(TAG, "Google Play Services is available and up to date");
        return true;
    }
    
    /**
     * Open Google Play Services page in Play Store app or browser
     * 
     * @param context Context to open the intent
     */
    public static void openPlayServicesInPlayStore(Context context) {
        try {
            context.startActivity(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=com.google.android.gms")));
        } catch (android.content.ActivityNotFoundException e) {
            // Play Store app not installed, use browser
            context.startActivity(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.gms")));
        }
    }
}
