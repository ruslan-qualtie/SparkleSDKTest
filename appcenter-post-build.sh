#!/bin/sh

BUNDLE_IDENTIFIER=com.example.sparkle.sdk.test
DISTRIBUTION_FILE=$APPCENTER_OUTPUT_DIRECTORY/SparkleSDKTest_distribution.zip
xcrun altool --notarize-app --primary-bundle-id $BUNDLE_IDENTIFIER --username $AC_USERNAME --password $AC_PASSWORD --file $DISTRIBUTION_FILE
