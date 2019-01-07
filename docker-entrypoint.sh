#!/bin/bash -e

rm -f /usr/local/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
# Generate WebRtcEndpoint configuration
echo "stunServerAddress=\"$STUN_IP\"" >> /usr/local/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
echo "stunServerPort=$STUN_PORT" >> /usr/local/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini

if [ "$TURN_URL" != "" ]; then
  echo "turnURL=\"$TURN_URL\"" >> /usr/local/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

rm -f /usr/local/etc/kurento/modules/kurento/BaseRtpEndpoint.conf.ini
# Generate BaseRtpEndpoint configuration
echo "minPort=$RTP_MIN_PORT" >> /usr/local/etc/kurento/modules/kurento/BaseRtpEndpoint.conf.ini
echo "maxPort=$RTP_MAX_PORT" >> /usr/local/etc/kurento/modules/kurento/BaseRtpEndpoint.conf.ini

CONFIG=$(cat /usr/local/etc/kurento/kurento.conf.json | sed '/^[ ]*\/\//d' | jq ".mediaServer.net.websocket.port = $PORT")
echo $CONFIG > /usr/local/etc/kurento/kurento.conf.json

exec "$@"

