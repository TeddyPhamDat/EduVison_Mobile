#!/usr/bin/env pwsh
# Convert EduVision Flutter app to iOS-only
# This script will update the remaining screens and widgets to use Cupertino (iOS) instead of Material (Android)

Write-Host "Starting conversion to iOS-only app..." -ForegroundColor Green

# 1. Delete any remaining Android-specific files (if any were missed)
$androidFiles = @(
    "android"
)

foreach ($file in $androidFiles) {
    if (Test-Path $file) {
        Write-Host "Removing $file..." -ForegroundColor Yellow
        Remove-Item -Path $file -Recurse -Force
    }
}

# 2. Create a backup of the lib folder
Write-Host "Creating backup of lib folder..." -ForegroundColor Yellow
Copy-Item -Path "lib" -Destination "lib_backup" -Recurse -Force

# 3. Update all screens to use Cupertino widgets
# List of files to update (we'll process them one by one)
$screenFiles = @(
    "lib\screens\login_screen.dart",
    "lib\screens\signup_screen.dart",
    "lib\screens\forgot_password_screen.dart",
    "lib\screens\profile_settings_screen.dart",
    "lib\screens\video_list_screen.dart",
    "lib\screens\create_video_screen.dart"
)

Write-Host "Updating screen files to use Cupertino widgets..." -ForegroundColor Yellow
foreach ($file in $screenFiles) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content -Path $file -Raw
        
        # Replace Material imports with Cupertino
        $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/cupertino.dart';"
        $content = $content -replace "import 'package:flutter/material.dart' as material;", "import 'package:flutter/cupertino.dart' as cupertino;"
        
        # Remove duplicate imports if both Material and Cupertino were imported
        $content = $content -replace "import 'package:flutter/material.dart';\s*import 'package:flutter/cupertino.dart';", "import 'package:flutter/cupertino.dart';"
        
        # Replace Material widgets with Cupertino equivalents
        $replacements = @{
            "Scaffold\(" = "CupertinoPageScaffold("
            "AppBar\(" = "CupertinoNavigationBar("
            "FloatingActionButton\(" = "CupertinoButton("
            "ElevatedButton\(" = "CupertinoButton.filled("
            "TextButton\(" = "CupertinoButton("
            "OutlinedButton\(" = "CupertinoButton("
            "IconButton\(" = "CupertinoButton("
            "MaterialPageRoute\(" = "CupertinoPageRoute("
            "LinearProgressIndicator\(" = "CupertinoActivityIndicator("
            "CircularProgressIndicator\(" = "CupertinoActivityIndicator("
            "TextField\(" = "CupertinoTextField("
            "Drawer\(" = "Container("
            "BottomNavigationBar\(" = "CupertinoTabBar("
            "TabBar\(" = "CupertinoTabBar("
            "Colors\.white" = "CupertinoColors.white"
            "Colors\.black" = "CupertinoColors.black"
            "Colors\.grey" = "CupertinoColors.systemGrey"
            "Colors\.blue" = "CupertinoColors.activeBlue"
            "Colors\.red" = "CupertinoColors.systemRed"
            "Colors\.green" = "CupertinoColors.systemGreen"
            "Colors\.yellow" = "CupertinoColors.systemYellow"
            "Colors\.orange" = "CupertinoColors.systemOrange"
            "Colors\.deepPurple" = "CupertinoColors.systemPurple"
            "Colors\.transparent" = "CupertinoColors.systemBackground.withOpacity(0)"
            "Icons\.person" = "CupertinoIcons.person"
            "Icons\.email" = "CupertinoIcons.mail"
            "Icons\.lock" = "CupertinoIcons.lock"
            "Icons\.visibility" = "CupertinoIcons.eye"
            "Icons\.visibility_off" = "CupertinoIcons.eye_slash"
            "Icons\.phone" = "CupertinoIcons.phone"
            "Icons\.home" = "CupertinoIcons.home"
            "Icons\.search" = "CupertinoIcons.search"
            "Icons\.settings" = "CupertinoIcons.settings"
            "Icons\.account_circle" = "CupertinoIcons.person_circle"
            "Icons\.video_library" = "CupertinoIcons.film"
            "Icons\.book" = "CupertinoIcons.book"
            "Icons\.arrow_back" = "CupertinoIcons.back"
            "Icons\.play_circle_fill" = "CupertinoIcons.play_circle_fill"
            "Icons\.info" = "CupertinoIcons.info"
            "Icons\.warning" = "CupertinoIcons.exclamationmark_triangle"
            "Icons\.error" = "CupertinoIcons.exclamationmark_circle"
            "Icons\.check" = "CupertinoIcons.check_mark"
            "Icons\.add" = "CupertinoIcons.plus"
            "Icons\.edit" = "CupertinoIcons.pencil"
            "Icons\.delete" = "CupertinoIcons.delete"
            "Icons\.share" = "CupertinoIcons.share"
            "Icons\.save" = "CupertinoIcons.floppy_disk"
            "Theme\.of\(context\)" = "CupertinoTheme.of(context)"
            "ThemeData\(" = "CupertinoThemeData("
            "Icon\(" = "Icon("
            "BorderRadius\.circular\(" = "BorderRadius.circular("
        }

        foreach ($key in $replacements.Keys) {
            $content = $content -replace $key, $replacements[$key]
        }
        
        # Save updated content
        Set-Content -Path $file -Value $content
    }
}

# 4. Update widgets
$widgetFiles = @(
    "lib\widgets\custom_header.dart",
    "lib\widgets\custom_footer.dart",
    "lib\widgets\video_card.dart",
    "lib\widgets\subject_dropdown.dart",
    "lib\widgets\subject_filter.dart",
    "lib\widgets\slides_preview_section.dart"
)

Write-Host "Updating widget files to use Cupertino widgets..." -ForegroundColor Yellow
foreach ($file in $widgetFiles) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content -Path $file -Raw
        
        # Check if the file already has logic to handle both platforms
        if ($content -match "isIOS|TargetPlatform\.iOS") {
            # If it has platform-specific logic, modify it to always use iOS
            $content = $content -replace "final bool isIOS = Theme\.of\(context\)\.platform == TargetPlatform\.iOS;", "final bool isIOS = true;"
            $content = $content -replace "if \(isIOS\) {([^}]+)} else {([^}]+)}", "// iOS-only: $1"
        } else {
            # Otherwise, apply same replacements as for screens
            $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/cupertino.dart';"
            $content = $content -replace "import 'package:flutter/material.dart';\s*import 'package:flutter/cupertino.dart';", "import 'package:flutter/cupertino.dart';"
            
            # Replace Material widgets with Cupertino equivalents (same as for screens)
            $replacements = @{
                "Scaffold\(" = "CupertinoPageScaffold("
                "AppBar\(" = "CupertinoNavigationBar("
                "FloatingActionButton\(" = "CupertinoButton("
                "ElevatedButton\(" = "CupertinoButton.filled("
                "TextButton\(" = "CupertinoButton("
                "OutlinedButton\(" = "CupertinoButton("
                "IconButton\(" = "CupertinoButton("
                "MaterialPageRoute\(" = "CupertinoPageRoute("
                "LinearProgressIndicator\(" = "CupertinoActivityIndicator("
                "CircularProgressIndicator\(" = "CupertinoActivityIndicator("
                "TextField\(" = "CupertinoTextField("
                "Drawer\(" = "Container("
                "BottomNavigationBar\(" = "CupertinoTabBar("
                "TabBar\(" = "CupertinoTabBar("
                "Colors\.white" = "CupertinoColors.white"
                "Colors\.black" = "CupertinoColors.black"
                "Colors\.grey" = "CupertinoColors.systemGrey"
                "Colors\.blue" = "CupertinoColors.activeBlue"
                "Colors\.red" = "CupertinoColors.systemRed"
                "Colors\.green" = "CupertinoColors.systemGreen"
                "Colors\.yellow" = "CupertinoColors.systemYellow"
                "Colors\.orange" = "CupertinoColors.systemOrange"
                "Colors\.deepPurple" = "CupertinoColors.systemPurple"
                "Colors\.transparent" = "CupertinoColors.systemBackground.withOpacity(0)"
                "Icons\.person" = "CupertinoIcons.person"
                "Icons\.email" = "CupertinoIcons.mail"
                "Icons\.lock" = "CupertinoIcons.lock"
                "Icons\.visibility" = "CupertinoIcons.eye"
                "Icons\.visibility_off" = "CupertinoIcons.eye_slash"
                "Icons\.phone" = "CupertinoIcons.phone"
                "Icons\.home" = "CupertinoIcons.home"
                "Icons\.search" = "CupertinoIcons.search"
                "Icons\.settings" = "CupertinoIcons.settings"
                "Icons\.account_circle" = "CupertinoIcons.person_circle"
                "Icons\.video_library" = "CupertinoIcons.film"
                "Icons\.book" = "CupertinoIcons.book"
                "Icons\.arrow_back" = "CupertinoIcons.back"
                "Icons\.play_circle_fill" = "CupertinoIcons.play_circle_fill"
                "Icons\.info" = "CupertinoIcons.info"
                "Icons\.warning" = "CupertinoIcons.exclamationmark_triangle"
                "Icons\.error" = "CupertinoIcons.exclamationmark_circle"
                "Icons\.check" = "CupertinoIcons.check_mark"
                "Icons\.add" = "CupertinoIcons.plus"
                "Icons\.edit" = "CupertinoIcons.pencil"
                "Icons\.delete" = "CupertinoIcons.delete"
                "Icons\.share" = "CupertinoIcons.share"
                "Icons\.save" = "CupertinoIcons.floppy_disk"
                "Theme\.of\(context\)" = "CupertinoTheme.of(context)"
                "ThemeData\(" = "CupertinoThemeData("
                "Icon\(" = "Icon("
                "BorderRadius\.circular\(" = "BorderRadius.circular("
            }

            foreach ($key in $replacements.Keys) {
                $content = $content -replace $key, $replacements[$key]
            }
        }
        
        # Save updated content
        Set-Content -Path $file -Value $content
    }
}

# 5. Update services
$serviceFiles = @(
    "lib\services\auth_service.dart",
    "lib\services\video_service.dart"
)

Write-Host "Updating service files to remove any Material dependencies..." -ForegroundColor Yellow
foreach ($file in $serviceFiles) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content -Path $file -Raw
        
        # Replace Material imports with Cupertino if needed
        $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/cupertino.dart';"
        
        # Save updated content
        Set-Content -Path $file -Value $content
    }
}

# 6. Remove split_view.dart since we're no longer using it
if (Test-Path "lib\widgets\split_view.dart") {
    Write-Host "Removing split_view.dart..." -ForegroundColor Yellow
    Remove-Item -Path "lib\widgets\split_view.dart" -Force
}

Write-Host "Conversion completed successfully!" -ForegroundColor Green
Write-Host "You may need to manually fix any remaining issues." -ForegroundColor Yellow
Write-Host "A backup of your lib folder was created at lib_backup" -ForegroundColor Yellow