#!/bin/bash
ANDROID_APP_FOLDER="$(pwd)/../testui"
# Create symbolic link makes flutter_native_splash:create think that we have android app
mkdir android && ln -s $ANDROID_APP_FOLDER android/app
flutter pub run flutter_native_splash:create
rm android/app
rmdir android
# Cleanup generated styles.xml which we don't need
# Base theme that contain splash properties are instead placed in themes.xml
find $ANDROID_APP_FOLDER/src/main/res -name "styles.xml" -exec rm {} \;
