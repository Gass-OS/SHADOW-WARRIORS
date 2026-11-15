cat << 'EOF' > .github/workflows/android-build.yml
name: Build Android APK (Godot 4.7.2)

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-android:
    runs-on: ubuntu-latest
    env:
      GODOT_VERSION: "4.7.2"

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Install Android SDK Build-Tools & Platform 35
        run: |
          yes | sdkmanager --licenses > /dev/null || true
          sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.1"

      - name: Download Godot 4.7.2 & Android Export Templates
        run: |
          wget -q https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          unzip -q Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
          sudo mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot
          sudo chmod +x /usr/local/bin/godot

          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          wget -q https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
          unzip -q Godot_v${GODOT_VERSION}-stable_export_templates.tpz -d templates_tmp
          mv templates_tmp/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable/
          rm -rf templates_tmp Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip Godot_v${GODOT_VERSION}-stable_export_templates.tpz

      - name: Generate Debug Keystore & Configure Godot Android Settings
        run: |
          keytool -genkey -v -keystore "${{ github.workspace }}/debug.keystore" \
            -storepass android -alias androiddebugkey -keypass android \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -dname "CN=ShadowWarriors,O=Tunisia,C=TN"

          mkdir -p ~/.config/godot
          cat <<CFG > ~/.config/godot/editor_settings-4.tres
          [gd_resource type="EditorSettings" format=3]

          [resource]
          export/android/android_sdk_path = "${ANDROID_HOME}"
          export/android/debug_keystore = "${{ github.workspace }}/debug.keystore"
          export/android/debug_keystore_user = "androiddebugkey"
          export/android/debug_keystore_pass = "android"
          CFG
          cp ~/.config/godot/editor_settings-4.tres ~/.config/godot/editor_settings-4.7.tres

          sed -i 's|keystore/debug=""|keystore/debug="${{ github.workspace }}/debug.keystore"|' export_presets.cfg

      - name: Import Project & Export Android APK
        run: |
          mkdir -p build
          godot --headless --import || true
          godot --headless --verbose --export-debug "Android" build/ShadowWarriorsTunisia.apk
          ls -lh build/ShadowWarriorsTunisia.apk

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: ShadowWarriorsTunisia-APK
          path: build/ShadowWarriorsTunisia.apk
          if-no-files-found: error
EOF