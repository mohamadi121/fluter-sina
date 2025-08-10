#!/bin/bash

# Set DNS servers (همان DNS های شما)
echo -e "nameserver 178.22.122.100\nnameserver 185.51.200.2" | sudo tee /etc/resolv.conf

# دایرکتوری موقت برای نصب Flutter
TEMP_DIR="/tmp/flutter_build"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# دانلود و نصب Flutter
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

# تنظیم متغیرهای محیطی
export PATH="$TEMP_DIR/flutter/bin:$PATH"

# نمایش نسخه Flutter
flutter --version || echo "Flutter initialization failed"

# کپی پروژه به محل موقت
echo "Copying project..."
mkdir -p $TEMP_DIR/app
cp -r /home/devops/projects/fluter-sina/* $TEMP_DIR/app/
cd $TEMP_DIR/app

# نصب وابستگی‌ها و ساخت APK
echo "Building APK..."
flutter pub get
flutter build apk --release

# کپی APK به محل اصلی
echo "Copying APK to original location..."
mkdir -p /home/devops/projects/fluter-sina/build/app/outputs/flutter-apk/
cp -f build/app/outputs/flutter-apk/app-release.apk /home/devops/projects/fluter-sina/app-release.apk

echo "Build completed. APK is at /home/devops/projects/fluter-sina/app-release.apk"
