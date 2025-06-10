#!/bin/bash
# Example: ./update_app.sh yourAppName com.yourAppName.app #ffffff

NEW_APP_ICON="app_icon.png"
NEW_APP_ICON_BETA="app_icon_beta.png"

PRINT_ERROR() {
  local message="$*"
  echo -e "\033[0;31m${message}\033[0m"
}

PRINT_SUCCESS() {
  local message="$*"
  echo -e "\033[0;32m${message}\033[0m"
}

# Function to create circular icon with alpha transparency
CREATE_CIRCULAR_ICON() {
  local input_file="$1"
  local output_file="$2"
  local size="$3"
  
  # Create circular icon with transparent background
  magick -size "${size}x${size}" xc:none \
    -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),1" \
    "$input_file" -resize "${size}x${size}" \
    -compose SrcIn -composite \
    "$output_file"
}

INIT_CHECKS() {
  if ! command -v magick &> /dev/null; then
    PRINT_ERROR "ImageMagick not found. Attempting installation..."
    if [ "$(uname)" == "Linux" ]; then
      if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y imagemagick
      else
        PRINT_ERROR "apt-get not found. Please install ImageMagick manually."
        exit 1
      fi
    elif [ "$(uname)" == "Darwin" ]; then
      if command -v brew &> /dev/null; then
        brew install imagemagick
      else
        PRINT_ERROR "Homebrew not found. Please install Homebrew and then ImageMagick."
        exit 1
      fi
    else
      PRINT_ERROR "Unsupported OS. Please install ImageMagick manually."
      exit 1
    fi
  else
    PRINT_SUCCESS "ImageMagick is installed."
  fi
}

INIT_CHECKS

# Check if five arguments are passed
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 NewAppName new.bundle.id \"#RRGGBB\""
  exit 1
fi

# New values from arguments
NEW_NAME="$1"
NEW_BUNDLE_ID="$2"

# *** IMPORTANT ***
# Set these to match your current (old) app name and bundle id in your project:
OLD_NAME="baseApp"
OLD_BUNDLE_ID="com.baseApp"

# New color value (hex)
NEW_SPLASH_COLOR="$3"

echo "Renaming app from '$OLD_NAME' to '$NEW_NAME'"
echo "Changing bundle ID from '$OLD_BUNDLE_ID' to '$NEW_BUNDLE_ID'"

# Determine OS to set the correct sed in-place option
if [ "$(uname)" == "Darwin" ]; then
  # macOS (BSD sed)
  SED_INPLACE() { sed -i "" "$@"; }
else
  # Linux (GNU sed)
  SED_INPLACE() { sed -i "$@"; }
fi


########################? iOS START ##############################
#############################
# iOS => App Name
#############################
IOS_PLIST="../ios/baseApp/Info.plist"
if [ -f "$IOS_PLIST" ]; then
  SED_INPLACE "s/<string>$OLD_NAME<\/string>/<string>$NEW_NAME<\/string>/g" "$IOS_PLIST"
  SED_INPLACE "s/<string>\$(PRODUCT_BUNDLE_IDENTIFIER)<\/string>/<string>$NEW_BUNDLE_ID<\/string>/g" "$IOS_PLIST"
  SED_INPLACE "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" "$IOS_PLIST"
  PRINT_SUCCESS "Updated $IOS_PLIST"
else
  PRINT_ERROR "File $IOS_PLIST not found. Check your iOS project path."
fi

#############################
# iOS => App Bundle ID
#############################
IOS_PROJECT="../ios/baseApp.xcodeproj/project.pbxproj"
if [ -f "$IOS_PROJECT" ]; then
  SED_INPLACE "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" "$IOS_PROJECT"
  PRINT_SUCCESS "Updated $IOS_PROJECT"
else
  PRINT_ERROR "File $IOS_PROJECT not found."
fi

#############################
# iOS => Splash Color
#############################
IOS_STORYBOARD="../ios/LaunchScreen.storyboard" 
if [ -f "$IOS_STORYBOARD" ]; then
  hex=${NEW_SPLASH_COLOR#\#}
  
  red_hex=${hex:0:2}
  green_hex=${hex:2:2}
  blue_hex=${hex:4:2}
  
  red_dec=$(printf "%d" 0x$red_hex)
  green_dec=$(printf "%d" 0x$green_hex)
  blue_dec=$(printf "%d" 0x$blue_hex)
  
  red_norm=$(awk "BEGIN {printf \"%.15f\", $red_dec/255}")
  green_norm=$(awk "BEGIN {printf \"%.15f\", $green_dec/255}")
  blue_norm=$(awk "BEGIN {printf \"%.15f\", $blue_dec/255}")
  
  SED_INPLACE "s/\(red=\)\"[^\"]*\"/\1\"$red_norm\"/" "$IOS_STORYBOARD"
  SED_INPLACE "s/\(green=\)\"[^\"]*\"/\1\"$green_norm\"/" "$IOS_STORYBOARD"
  SED_INPLACE "s/\(blue=\)\"[^\"]*\"/\1\"$blue_norm\"/" "$IOS_STORYBOARD"
  
  SED_INPLACE "s/baseApp Company Name/$NEW_NAME/g" "$IOS_STORYBOARD"
  PRINT_SUCCESS "Updated background color in $IOS_STORYBOARD"
else
  PRINT_ERROR "File $IOS_STORYBOARD not found."
fi

#############################
# iOS => Splash Logo
#############################
IOS_LOGO_SRC="./splash_logo.png"
IOS_LOGO_DEST="../ios/baseApp/Images.xcassets/logo.imageset/nq_logo.png"
if [ -f "$IOS_LOGO_SRC" ]; then
  cp "$IOS_LOGO_SRC" "$IOS_LOGO_DEST"
  PRINT_SUCCESS "Copied splash_logo.png to $IOS_LOGO_DEST"
else
  PRINT_ERROR "File $IOS_LOGO_SRC not found in the root directory."
fi

#############################
# iOS => App Icon
#############################
if [ -f "$NEW_APP_ICON" ]; then
  if ! command -v magick &> /dev/null; then
    PRINT_ERROR "ImageMagick is required but not installed. Aborting app icon update."
  else
    ICON_NAMES=("40" "58" "60" "80" "87" "120_60" "120" "180" "1024")
    ICON_SIZES=(40 58 60 80 87 120 120 180 1024)

    IOS_RES_DIR="../ios/baseApp/Images.xcassets/AppIcon.appiconset"

    for i in "${!ICON_NAMES[@]}"; do
      name="${ICON_NAMES[$i]}"
      size="${ICON_SIZES[$i]}"
      dest_dir="$IOS_RES_DIR"
      mkdir -p "$dest_dir"
      magick "$NEW_APP_ICON" -resize "${size}x${size}" "$dest_dir/$name.png"
      PRINT_SUCCESS "Updated icon for $IOS_RES_DIR/$name to ${size}x${size}"
    done
  fi
else
  PRINT_ERROR "File $NEW_APP_ICON not found in the root directory."
fi

#############################
# iOS => App Icon Beta
#############################
if [ -f "$NEW_APP_ICON_BETA" ]; then
  if ! command -v magick &> /dev/null; then
    PRINT_ERROR "ImageMagick is required but not installed. Aborting app icon update."
  else
    ICON_NAMES=("40" "58" "60" "80" "87" "120_60" "120" "180" "1024")
    ICON_SIZES=(40 58 60 80 87 120 120 180 1024)

    IOS_RES_DIR="../ios/baseApp/Images.xcassets/AppIconBeta.appiconset"

    for i in "${!ICON_NAMES[@]}"; do
      name="${ICON_NAMES[$i]}"
      size="${ICON_SIZES[$i]}"
      dest_dir="$IOS_RES_DIR"
      mkdir -p "$dest_dir"
      magick "$NEW_APP_ICON_BETA" -resize "${size}x${size}" "$dest_dir/$name.png"
      PRINT_SUCCESS "Updated icon for $IOS_RES_DIR/$name to ${size}x${size}"
    done
  fi
else
  PRINT_ERROR "File $NEW_APP_ICON_BETA not found in the root directory."
fi
########################? iOS END ################################



########################? ANDROID START ##########################
#############################
# Android => App Name
#############################
ANDROID_STRINGS="../android/app/src/main/res/values/strings.xml"
if [ -f "$ANDROID_STRINGS" ]; then
  SED_INPLACE "s/<string name=\"app_name\">$OLD_NAME<\/string>/<string name=\"app_name\">$NEW_NAME<\/string>/g" "$ANDROID_STRINGS"
  SED_INPLACE "s/baseApp Company Name/$NEW_NAME/g" "$ANDROID_STRINGS"
  PRINT_SUCCESS "Updated $ANDROID_STRINGS"
else
  PRINT_ERROR "File $ANDROID_STRINGS not found."
fi

#############################
# Android => App Bundle ID
#############################
ANDROID_BUILD="../android/app/build.gradle"
if [ -f "$ANDROID_BUILD" ]; then
  SED_INPLACE "s/applicationId \"$OLD_BUNDLE_ID\"/applicationId \"$NEW_BUNDLE_ID\"/g" "$ANDROID_BUILD"
  PRINT_SUCCESS "Updated $ANDROID_BUILD"
else
  PRINT_ERROR "File $ANDROID_BUILD not found."
fi

#############################
# Android => Splash Color
#############################
LAUNCH_SCREEN="../android/app/src/main/res/layout/launch_screen.xml"
if [ -f "$LAUNCH_SCREEN" ]; then
  SED_INPLACE "s/android:background\s*=\s*\"#[^\"]*\"/android:background=\"$NEW_SPLASH_COLOR\"/g" "$LAUNCH_SCREEN"
  PRINT_SUCCESS "Updated background color in $LAUNCH_SCREEN"
else
  PRINT_ERROR "File $LAUNCH_SCREEN not found."
fi

#############################
# Android => Splash Logo
#############################
ANDROID_LOGO_SRC="./splash_logo.png"
ANDROID_LOGO_DEST="../android/app/src/main/res/drawable/nq_logo.png"
if [ -f "$ANDROID_LOGO_SRC" ]; then
  cp "$ANDROID_LOGO_SRC" "$ANDROID_LOGO_DEST"
  PRINT_SUCCESS "Copied splash_logo.png to $ANDROID_LOGO_DEST"
else
  PRINT_ERROR "File $ANDROID_LOGO_SRC not found in the root directory."
fi

#############################
# Android => App Icon
#############################
if [ -f "$NEW_APP_ICON" ]; then
  if ! command -v magick &> /dev/null; then
    PRINT_ERROR "ImageMagick is required but not installed. Aborting app icon update."
  else
    # mdpi: 48x48, hdpi: 72x72, xhdpi: 96x96, xxhdpi: 144x144, xxxhdpi: 192x192
    ICON_FOLDERS=("mipmap-mdpi" "mipmap-hdpi" "mipmap-xhdpi" "mipmap-xxhdpi" "mipmap-xxxhdpi")
    ICON_SIZES=(48 72 96 144 192)

    ANDROID_RES_DIR="../android/app/src/main/res"

    for i in "${!ICON_FOLDERS[@]}"; do
      folder="${ICON_FOLDERS[$i]}"
      size="${ICON_SIZES[$i]}"
      dest_dir="$ANDROID_RES_DIR/$folder"
      mkdir -p "$dest_dir"
      
      # Create regular launcher icon
      magick "$NEW_APP_ICON" -resize "${size}x${size}" "$dest_dir/ic_launcher.png"
      
      # Create circular launcher icon with alpha transparency
      CREATE_CIRCULAR_ICON "$NEW_APP_ICON" "$dest_dir/ic_launcher_round.png" "$size"
      
      PRINT_SUCCESS "Updated icon for $folder to ${size}x${size}"
    done
  fi
else
  PRINT_ERROR "File $NEW_APP_ICON not found in the root directory."
fi

#############################
# Android => App Icon Beta
#############################
if [ -f "$NEW_APP_ICON_BETA" ]; then
  if ! command -v magick &> /dev/null; then
    PRINT_ERROR "ImageMagick is required but not installed. Aborting app icon update."
  else
    # mdpi: 48x48, hdpi: 72x72, xhdpi: 96x96, xxhdpi: 144x144, xxxhdpi: 192x192
    ICON_FOLDERS=("mipmap-mdpi" "mipmap-hdpi" "mipmap-xhdpi" "mipmap-xxhdpi" "mipmap-xxxhdpi")
    ICON_SIZES=(48 72 96 144 192)

    ANDROID_RES_DIR="../android/app/src/beta/res"

    for i in "${!ICON_FOLDERS[@]}"; do
      folder="${ICON_FOLDERS[$i]}"
      size="${ICON_SIZES[$i]}"
      dest_dir="$ANDROID_RES_DIR/$folder"
      mkdir -p "$dest_dir"

      # Create regular launcher icon
      magick "$NEW_APP_ICON_BETA" -resize "${size}x${size}" "$dest_dir/ic_launcher.png"
      
      # Create circular launcher icon with alpha transparency
      CREATE_CIRCULAR_ICON "$NEW_APP_ICON_BETA" "$dest_dir/ic_launcher_round.png" "$size"

      PRINT_SUCCESS "Updated icon for $folder to ${size}x${size}"
    done
  fi
else
  PRINT_ERROR "File $NEW_APP_ICON_BETA not found in the root beta directory."
fi
########################? ANDROID END #############################

PRINT_SUCCESS "Modification complete!"
