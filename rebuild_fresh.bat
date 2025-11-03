@echo off
echo ================================================
echo  Fresh Rebuild - Mobile Presence App
echo ================================================
echo.

echo [1/5] Uninstalling old app...
adb uninstall com.example.monitoring_project
echo.

echo [2/5] Cleaning Flutter build...
call flutter clean
echo.

echo [3/5] Getting dependencies...
call flutter pub get
echo.

echo [4/5] Building fresh APK...
call flutter build apk --debug
echo.

echo [5/5] Installing fresh app...
call flutter install
echo.

echo ================================================
echo  Done! App installed successfully.
echo  Please login again to test.
echo ================================================
pause
