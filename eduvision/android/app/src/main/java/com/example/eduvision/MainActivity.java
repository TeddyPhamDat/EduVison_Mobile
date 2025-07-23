package com.example.eduvision;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.os.Build;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import com.example.eduvision.utils.PlayServicesUtils;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.eduvision/debug";
    private static final String TAG = "MainActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Check Google Play Services on startup
        try {
            boolean playServicesAvailable = PlayServicesUtils.checkPlayServices(this);
            Log.d(TAG, "Play Services available: " + playServicesAvailable);
        } catch (Exception e) {
            Log.e(TAG, "Error checking Play Services", e);
        }
    }
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("getSigningInfo")) {
                    try {
                        Map<String, String> signingInfo = getSigningInfo();
                        result.success(signingInfo);
                    } catch (Exception e) {
                        result.error("SIGNING_INFO_ERROR", e.getMessage(), null);
                    }
                } else if (call.method.equals("checkPlayServices")) {
                    try {
                        boolean playServicesAvailable = PlayServicesUtils.checkPlayServices(this);
                        Map<String, Object> resultMap = new HashMap<>();
                        resultMap.put("isAvailable", playServicesAvailable);
                        result.success(resultMap);
                    } catch (Exception e) {
                        result.error("PLAY_SERVICES_ERROR", e.getMessage(), null);
                    }
                } else if (call.method.equals("getPlayServicesVersion")) {
                    try {
                        Map<String, Object> resultMap = new HashMap<>();
                        try {
                            PackageInfo packageInfo = getPackageManager().getPackageInfo("com.google.android.gms", 0);
                            resultMap.put("version", packageInfo.versionName);
                            resultMap.put("versionCode", packageInfo.getLongVersionCode());
                            resultMap.put("isUpdated", true); // Assume it's updated if we can get the version
                        } catch (Exception e) {
                            resultMap.put("error", "Failed to get Play Services version: " + e.getMessage());
                        }
                        result.success(resultMap);
                    } catch (Exception e) {
                        result.error("PLAY_SERVICES_VERSION_ERROR", e.getMessage(), null);
                    }
                } else if (call.method.equals("getPlayServicesStatus")) {
                    try {
                        Map<String, Object> resultMap = new HashMap<>();
                        try {
                            GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
                            int resultCode = apiAvailability.isGooglePlayServicesAvailable(this);
                            boolean isAvailable = resultCode == ConnectionResult.SUCCESS;
                            
                            resultMap.put("isAvailable", isAvailable);
                            resultMap.put("statusCode", resultCode);
                            resultMap.put("statusMessage", apiAvailability.getErrorString(resultCode));
                            resultMap.put("isUserResolvable", apiAvailability.isUserResolvableError(resultCode));
                        } catch (Exception e) {
                            resultMap.put("error", "Failed to check Play Services status: " + e.getMessage());
                        }
                        result.success(resultMap);
                    } catch (Exception e) {
                        result.error("PLAY_SERVICES_STATUS_ERROR", e.getMessage(), null);
                    }
                } else {
                    result.notImplemented();
                }
            });
    }
    
    private Map<String, String> getSigningInfo() {
        Map<String, String> signingInfo = new HashMap<>();
        
        try {
            PackageInfo packageInfo;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo = getPackageManager().getPackageInfo(
                    getPackageName(), 
                    PackageManager.GET_SIGNING_CERTIFICATES
                );
                Signature[] signatures = packageInfo.signingInfo.getApkContentsSigners();
                
                for (Signature signature : signatures) {
                    String sha1 = getSHA1(signature);
                    String sha256 = getSHA256(signature);
                    
                    signingInfo.put("sha1", sha1);
                    signingInfo.put("sha256", sha256);
                    
                    Log.d("MainActivity", "SHA-1: " + sha1);
                    Log.d("MainActivity", "SHA-256: " + sha256);
                }
            } else {
                packageInfo = getPackageManager().getPackageInfo(
                    getPackageName(), 
                    PackageManager.GET_SIGNATURES
                );
                Signature[] signatures = packageInfo.signatures;
                
                for (Signature signature : signatures) {
                    String sha1 = getSHA1(signature);
                    String sha256 = getSHA256(signature);
                    
                    signingInfo.put("sha1", sha1);
                    signingInfo.put("sha256", sha256);
                    
                    Log.d("MainActivity", "SHA-1: " + sha1);
                    Log.d("MainActivity", "SHA-256: " + sha256);
                }
            }
        } catch (Exception e) {
            Log.e("MainActivity", "Error getting signing info", e);
            signingInfo.put("error", e.getMessage());
        }
        
        return signingInfo;
    }
    
    private String getSHA1(Signature signature) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-1");
            digest.update(signature.toByteArray());
            byte[] signatureBytes = digest.digest();
            
            StringBuilder hexString = new StringBuilder();
            for (byte signatureByte : signatureBytes) {
                String hex = Integer.toHexString(0xff & signatureByte);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
                hexString.append(':');
            }
            
            if (hexString.length() > 0) {
                hexString.deleteCharAt(hexString.length() - 1);
            }
            
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            Log.e("MainActivity", "Unable to get SHA-1", e);
            return null;
        }
    }
    
    private String getSHA256(Signature signature) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(signature.toByteArray());
            byte[] signatureBytes = digest.digest();
            
            StringBuilder hexString = new StringBuilder();
            for (byte signatureByte : signatureBytes) {
                String hex = Integer.toHexString(0xff & signatureByte);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
                hexString.append(':');
            }
            
            if (hexString.length() > 0) {
                hexString.deleteCharAt(hexString.length() - 1);
            }
            
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            Log.e("MainActivity", "Unable to get SHA-256", e);
            return null;
        }
    }
}
