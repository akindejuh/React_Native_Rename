# Shell script for updating app configuration

## Initial App Name & Bundle ID:
#### this script would target an app_name of "baseApp" and a bundle_id of "com.baseApp".
#### update the constants with your app_name & bundle_id before running the script.


## Fix Permission issue:
```sh
chmod +x ./scripts/update_app.sh 
```

## How to use 
### 1. Find the current app_name and bundle_id

### 2. Run the script as used below

```sh
./scripts/update_app.sh NewName NewBundleID rgbColorForSplashBackground
```

### 3. Example

```sh
./scripts/update_app.sh yourAppName com.yourAppName.app #121212
```

### 4. To update app_icon
add new app_icon.png with size 1024x1024 to the scripts folder

### 5. To update splash logo
add new splash_logo.png to the scripts folder
