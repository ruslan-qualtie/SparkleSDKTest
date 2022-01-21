#!/bin/zsh

# For more details see articles:
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
# https://developer.apple.com/forums/thread/128166
# https://blog.macadmin.me/posts/apple-notarytool/
# https://lessons.livecode.com/m/4071/l/1120307-codesigning-and-notarizing-your-lc-standalone-as-dmg-for-distribution-outside-the-mac-appstore

# Required Environment variables
# Sparta\ Scan
APP_NAME=SparkleSDKTest
ARCHIVE=build/archive.xcarchive
EXPORT_OPTIONS=SparkleSDKTest/export-options.plist
# Developer ID Application: Sparta Software Corporation (GB9B5L6A6K)
CODE_SIGN_IDENTITY='Developer ID Application: Penny Ventures LLC (MRSFQSP9T5)'
TEAM_ID=MRSFQSP9T5
EXPORT_DIR=build/export
APP_PATH=$EXPORT_DIR/$APP_NAME
DEVELOPER_ID_LOGIN=rsoldatenko@sfdev.com
DEVELOPER_ID_PASSWORD=rUS03031974
BUNDLE_ID=com.example.sparkle.sdk.test

xcodebuild \
  -workspace SparkleSDKTest.xcworkspace \
  -scheme SparkleSDKTest \
  -configuration Release \
  -derivedDataPath build/derived \
  -archivePath build/archive \
  archive

xcodebuild \
  -exportArchive \
  -archivePath $ARCHIVE \
  -exportOptionsPlist $EXPORT_OPTIONS \
  -exportPath $EXPORT_DIR

codesign $APP_PATH.app \
  --sign $TEAM_ID \
  --force \
  --timestamp \
  --options runtime

ditto $APP_PATH.app $APP_PATH/$APP_NAME.app
cd $EXPORT_DIR/$APP_NAME
ln -sfn /Applications
cd -

hdiutil create $APP_PATH.dmg \
  -quiet \
  -ov \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -imagekey zlib-level=9 \
  -format UDZO \
  -volname $APP_NAME \
  -srcfolder $APP_PATH

codesign $APP_PATH.dmg \
  --sign $TEAM_ID \
  --force \
  --timestamp \
  --options runtime
echo 'xcrun notarytool submit'
xcrun notarytool submit $APP_PATH.dmg \
  --apple-id $DEVELOPER_ID_LOGIN \
  --password $DEVELOPER_ID_PASSWORD \
  --team-id $TEAM_ID \
  --output-format json > $EXPORT_DIR/SubmitResponse.json

upload_message=$(jq -r .message $EXPORT_DIR/SubmitResponse.json)

if [[ $upload_message != "Successfully uploaded file" ]]; then exit 1; fi

submit_id=$(jq -r .id $EXPORT_DIR/SubmitResponse.json)
echo Notarization Request ID: $submit_id

xcrun notarytool wait $submit_id \
  --apple-id $DEVELOPER_ID_LOGIN \
  --password $DEVELOPER_ID_PASSWORD \
  --team-id $TEAM_ID \
  --output-format json > $EXPORT_DIR/WaitResponse.json

submit_status=$(jq -r .status $EXPORT_DIR/WaitResponse.json)
echo Notarization Status: $submit_status

if [[ $submit_status != "Accepted" ]]; then exit 1; fi

codesign --verify $APP_PATH.dmg
spctl -a -t open --context context:primary-signature -v $APP_PATH.dmg
xcrun stapler staple $APP_PATH.dmg
xcrun stapler validate $APP_PATH.dmg

codesign --verify $APP_PATH.app
spctl -a -v $APP_PATH.app
xcrun stapler staple $APP_PATH.app
xcrun stapler validate $APP_PATH.app

ditto -c -k --keepParent $APP_PATH.app $APP_PATH.zip
