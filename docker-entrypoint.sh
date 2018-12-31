#!/bin/bash -e

rm -f config/kurento/WebRtcEndpoint.conf.ini
# Generate WebRtcEndpoint configuration
echo "stunServerAddress=$STUN_IP" >> config/kurento/WebRtcEndpoint.conf.ini
echo "stunServerPort=$STUN_PORT" >> config/kurento/WebRtcEndpoint.conf.ini

if [ "$TURN_URL" != "" ]; then
  echo "turnURL=$TURN_URL" >> config/kurento/WebRtcEndpoint.conf.ini
fi

rm -f config/kurento/BaseRtpEndpoint.conf.ini
# Generate BaseRtpEndpoint configuration
echo "minPort=$RTP_MIN_PORT" >> config/kurento/BaseRtpEndpoint.conf.ini
echo "maxPort=$RTP_MAX_PORT" >> config/kurento/BaseRtpEndpoint.conf.ini

CONFIG=$(cat config/kurento.conf.json | sed '/^[ ]*\/\//d' | jq ".mediaServer.net.websocket.port = $PORT")
echo $CONFIG > config/kurento.conf.json

exec "$@"

