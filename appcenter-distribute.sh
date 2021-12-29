#!/usr/bin/env bash

# Environment Variables created by App Center
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_SOURCE_DIRECTORY

# Custom Environment Variables set in Build configuration
# $API_TOKEN
# $OWNER_NAME
# $APP_NAME
# $DISTRIBUTION_GROUP
# $PACKAGE_NAME
# $BUNDLE_IDENTIFIER
# $AC_USERNAME
# $AC_PASSWORD
# $SPARKLE_KEY

# Vars to simplify frequently used syntax
MIME_JSON='application/json'
MIME_BINARY='application/octet-stream'
ACCEPT_JSON="Accept: $MIME_JSON"
CONTENT_JSON="Content-Type: $MIME_JSON"
CONTENT_BINARY="Content-Type: $MIME_BINARY"

UPLOAD_DOMAIN="https://file.appcenter.ms/upload"
API_URL="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME"
AUTH="X-API-Token: $API_TOKEN"
APP_PACKAGE="$APPCENTER_OUTPUT_DIRECTORY/$PACKAGE_NAME"
SPARKLE="$APPCENTER_SOURCE_DIRECTORY/Pods/Sparkle"

# Body - Step 1/8
echo "------------------------------------------------------------------------------"
echo "Notarize app (1/8)"
xcrun altool --notarize-app \
  --primary-bundle-id $BUNDLE_IDENTIFIER \
  --username $AC_USERNAME \
  --password $AC_PASSWORD \
  --file $APP_PACKAGE

# Body - Step 2/8
echo "------------------------------------------------------------------------------"
echo "Creating release (2/8)"
request_url="$API_URL/uploads/releases"
echo $request_url
upload_json=$(
  curl -s -X POST "$request_url" \
    -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH"
)
echo $upload_json | jq -r '.'
releases_id=$(echo $upload_json | jq -r '.id')
package_asset_id=$(echo $upload_json | jq -r '.package_asset_id')
url_encoded_token=$(echo $upload_json | jq -r '.url_encoded_token')
file_name=$(basename $APP_PACKAGE)
file_size=$(eval wc -c $APP_PACKAGE | awk '{print $1}')

# Step 3/8
echo "------------------------------------------------------------------------------"
echo "Creating metadata (3/8)"
metadata_url="$UPLOAD_DOMAIN/set_metadata/$package_asset_id"
metadata_url+="?file_name=$file_name"
metadata_url+="&file_size=$file_size"
metadata_url+="&token=$url_encoded_token"
metadata_url+="&content_type=$MIME_BINARY"
echo $metadata_url
meta_response=$(
  curl -s -d POST "$metadata_url" \
    -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH"
)
echo $meta_response | jq -r '.'
chunk_size=$(echo $meta_response | jq -r '.chunk_size')
split_dir=$APPCENTER_OUTPUT_DIRECTORY/split-dir
mkdir -p $split_dir
eval split -b $chunk_size $APP_PACKAGE $split_dir/split

# Step 4/8
echo "------------------------------------------------------------------------------"
echo "Uploading chunked binary (4/8)"
binary_upload_url="$UPLOAD_DOMAIN/upload_chunk/$package_asset_id"
binary_upload_url+="?token=$url_encoded_token"
block_number=1
for i in $split_dir/*
do
  echo "start uploading chunk $i"
  url="$binary_upload_url"
  url+="&block_number=$block_number"
  echo $url
  size=$(wc -c $i | awk '{print $1}')
  curl -X POST $url \
    -H "Content-Length: $size" -H "$CONTENT_BINARY" \
    --data-binary "@$i" \
    | jq -r '.'
  block_number=$(($block_number + 1))
done

# Step 5/8
echo "------------------------------------------------------------------------------"
echo "Finalising upload (5/8)"
finish_url="$UPLOAD_DOMAIN/finished/$package_asset_id"
finish_url+="?token=$url_encoded_token"
echo $finish_url
curl -d POST "$finish_url" \
  -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH" \
  | jq -r '.'

# Step 6/8
echo "------------------------------------------------------------------------------"
echo "Commit release (6/8)"
commit_url="$API_URL/uploads/releases/$releases_id"
echo $commit_url
curl -X PATCH $commit_url \
 -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH" \
 --data '{"upload_status": "uploadFinished", "id": "$releases_id"}' \
 | jq -r '.'

# Step 7/8
echo "------------------------------------------------------------------------------"
echo "Polling for release id (7/8)"
release_id=null
max_poll_attempts=15
for counter in $(seq 1 $max_poll_attempts)
do
  poll_result=$(
    curl -s $commit_url \
      -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH"
  )
  echo "Attempt: $counter"
  echo  $poll_result | jq -r '.'
  release_id=$(echo $poll_result | jq -r '.release_distinct_id')
  if [[ $release_id -ne null || ($counter == $max_poll_attempts) ]]
  then
   break
  fi
  sleep 3
done
if [[ $release_id == null ]]
then
  echo "Failed to find release from appcenter"
  exit 1
fi

# Step 8/8
echo "------------------------------------------------------------------------------"
echo "Update destination metadata and applying destination to release (8/8)"
distribute_url="$API_URL/releases/$release_id"
echo $distribute_url
ed_signature=$(eval $SPARKLE/bin/sign_update -s $SPARKLE_KEY $APP_PACKAGE)
ed_signature=${ed_signature#*edSignature=\"}
ed_signature=${ed_signature%\" *}
metadata=$(
  jq -n \
    --arg ed_signature "$ed_signature"\
    '{ ed_signature: $ed_signature }'
)
destinations=$(
jq -n \
    --arg name "$DISTRIBUTION_GROUP"\
    '[{ name: $name}]'
)
distribute_data=$(
  jq -n \
    --argjson destinations "$destinations" \
    --argjson metadata "$metadata" \
   '{ destinations: $destinations, metadata: $metadata }'
)
curl -X PATCH $distribute_url \
  -H "$CONTENT_JSON" -H "$ACCEPT_JSON" -H "$AUTH" \
  --data "$distribute_data" \
  | jq -r '.'
echo "Release link:"
echo https://appcenter.ms/orgs/$OWNER_NAME/apps/$APP_NAME/distribute/releases/$release_id
