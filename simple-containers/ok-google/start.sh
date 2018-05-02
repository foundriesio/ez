#!/bin/bash

echo "setup authorized credentials file"
mkdir -p /root/.config/google-oauthlib-tool
echo '
{
    "client_secret": "'${CLIENT_SECRET}'",
    "client_id": "'${CLIENT_ID}'",
    "refresh_token": "'${REFRESH_TOKEN}'",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "scopes": ["https://www.googleapis.com/auth/assistant-sdk-prototype"]
}
' > /root/.config/google-oauthlib-tool/credentials.json

echo "setup alsa configuration"
echo '
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}
pcm.mic {
  type plug
  slave {
    pcm "'${MIC_ADDR}'"
  }
}
pcm.speaker {
  type plug
  slave {
    pcm "'${SPEAKER_ADDR}'"
  }
}
' > /root/.asoundrc

set -x

# Execute all the rest
exec "$@"
