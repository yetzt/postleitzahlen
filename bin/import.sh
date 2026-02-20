#!/bin/sh

# change to script dir
cd "$( dirname $0 )/..";
APPDIR=$( pwd -P )

# load nvm node if not vailable
if [ ! `command -v node` ] && [ -f "$HOME/.nvm/nvm.sh" ]; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh";
	if [ ! `command -v node` ]; then
		prnt "Missing node ( https://nodejs.org/en/download/package-manager )";
		exit 1;
	fi;
fi;

# check npm
if [ ! `command -v npm` ]; then
	prnt "Missing npm ( https://github.com/npm/cli/releases )";
	exit 1;
fi;

# check osmtogeojson
if [ ! `command -v osmtogeojson` ]; then
	npm i -g osmtogeojson;
	if [ ! `command -v osmtogeojson` ]; then
		prnt "Missing osmtogeojson (npm i -g osmtogeojson)";
		exit 1;
	fi;
fi;

# check geo2topo
if [ ! `command -v geo2topo` ]; then
	npm i -g topojson-server;
	if [ ! `command -v geo2topo` ]; then
		prnt "Missing geo2topo (npm i -g topojson-server)";
		exit 1;
	fi;
fi;

if [ ! `command -v curl` ]; then
	prnt "Missing curl ( https://curl.se/download.html )";
	exit 1;
fi;

if [ ! `command -v jq` ]; then
	prnt "Missing jq ( https://jqlang.github.io/jq/ )";
	exit 1;
fi;

if [ ! `command -v sponge` ]; then
	prnt "Missing sponge ( From moreutils )";
	exit 1;
fi;

# ensure data dir
mkdir -p "$APPDIR/data";

echo "Fetching Germany Administrative Boundaries"; # -s
curl --retry 5 --retry-delay 3 --fail --max-time 300 -v -G "http://overpass-api.de/api/interpreter" --data-urlencode 'data=[out:json]; relation["boundary"="administrative"]["admin_level"="2"]["ISO3166-1"="DE"]; out geom;' > "$APPDIR/data/germany.osm.json";
if [ $? -ne 0 ]; then
	echo "Failed" >&2;
	exit 1;
fi;

echo "Fetching Postcode Areas";
curl --retry 5 --retry-delay 3 --fail --max-time 300 -v -G "http://overpass-api.de/api/interpreter" --data-urlencode 'data=[out:json]; area[wikidata="Q183"]->.searchArea; ( relation["type"="boundary"]["boundary"="postal_code"](area.searchArea); relation["type"="boundary"]["boundary"="postal_code"]["postal_code:DE"]; relation["type"="boundary"]["boundary"="postal_code"]["postal_code"="78266"]; ); out body geom;' > "$APPDIR/data/postleitzahlen.osm.json";
if [ $? -ne 0 ]; then
	echo "Failed" >&2;
	exit 1;
fi;

echo "Converting OSM data to GeoJSON";
osmtogeojson -m "$APPDIR/data/germany.osm.json" > "$APPDIR/data/germany.osm.geojson";
osmtogeojson -m "$APPDIR/data/postleitzahlen.osm.json" > "$APPDIR/data/postleitzahlen.osm.geojson";

# import
echo "Importing";
node "$APPDIR/bin/import.js";

if [ $? -ne 0 ]; then
	echo "Import Failed" >&2;
	exit 1;
fi;

# convert to topojson
geo2topo "$APPDIR/data/postleitzahlen.geojson" > "$APPDIR/data/postleitzahlen.topojson";

# ensure copyright notice
DATE=`node -e "process.stdout.write((new Date()).toISOString())"`;
jq "{\"copyright\": \"© OpenStreetMap contributors, https://openstreetmap.org/copyright\", \"license\": \"ODbL-1.0\", \"timestamp\": \"$DATE\"} + ." "$APPDIR/data/postleitzahlen.topojson" | sponge "$APPDIR/data/postleitzahlen.topojson";
jq "{\"copyright\": \"© OpenStreetMap contributors, https://openstreetmap.org/copyright\", \"license\": \"ODbL-1.0\", \"timestamp\": \"$DATE\"} + ." "$APPDIR/data/postleitzahlen.geojson" | sponge "$APPDIR/data/postleitzahlen.geojson";

# compress
echo "Compressing";
if [ `command -v brotli` ]; then
	brotli -kf -q 11 "$APPDIR/data/postleitzahlen.geojson";
	brotli -kf -q 11 "$APPDIR/data/postleitzahlen.topojson";
fi;

echo "Clean Up";
rm -f "$APPDIR/data/germany.osm.json";
rm -f "$APPDIR/data/germany.osm.geojson";
rm -f "$APPDIR/data/postleitzahlen.osm.json";
rm -f "$APPDIR/data/postleitzahlen.osm.geojson";

# delete uncompressed files only if compressed
if [ -e "$APPDIR/data/postleitzahlen.geojson.br" ]; then
	rm -f "$APPDIR/data/postleitzahlen.geojson";
fi;
if [ -e "$APPDIR/data/postleitzahlen.topojson.br" ]; then
	rm -f "$APPDIR/data/postleitzahlen.topojson";
fi;
