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

# get postcodes from overpass; buesingen is not included in the first query and has to be requested separately
echo "Fetching Postcode Areas";
curl -v -G "http://overpass-api.de/api/interpreter" --data "data=%5Bout%3Ajson%5D%3B%20area%5Bwikidata%3D%22Q183%22%5D-%3E.searchArea%3B%20(%20relation%5B%22type%22%3D%22boundary%22%5D%5B%22boundary%22%3D%22postal_code%22%5D(area.searchArea)%3B%20)%3B%20out%20body%20geom%3B" > "$APPDIR/data/postleitzahlen.osm.json";
curl -v -G "http://overpass-api.de/api/interpreter" --data "data=%5Bout%3Ajson%5D%3B%20relation%5B%22type%22%3D%22boundary%22%5D%5B%22boundary%22%3D%22postal_code%22%5D%5B%22postal_code%22%3D%2278266%22%5D%3B%20out%20body%20geom%3B" > "$APPDIR/data/buesingen.osm.json";

# convert to geojson
echo "Converting to GeoJSON";
osmtogeojson -m "$APPDIR/data/postleitzahlen.osm.json" > "$APPDIR/data/postleitzahlen.raw.geojson";
osmtogeojson -m "$APPDIR/data/buesingen.osm.json" > "$APPDIR/data/buesingen.raw.geojson";

# import
echo "Importing";
node "$APPDIR/bin/import.js";

# convert to topojson
geo2topo "$APPDIR/data/postleitzahlen.geojson" > "$APPDIR/data/postleitzahlen.topojson";

# ensure copyright notice
DATE=`node -e "process.stdout.write((new Date()).toISOString())"`;
jq "{\"copyright\": \"© OpenStreetMap contributors, https://openstreetmap.org/copyright\", \"timestamp\": \"$DATE\"} + ." "$APPDIR/data/postleitzahlen.topojson" | sponge "$APPDIR/data/postleitzahlen.topojson";

# compress
echo "Compressing";
if [ `command -v brotli` ]; then
	brotli -k9 "$APPDIR/data/postleitzahlen.geojson";
	brotli -k9 "$APPDIR/data/postleitzahlen.topojson";
fi;

echo "Clean Up";
rm -f "$APPDIR/data/buesingen.osm.json";
rm -f "$APPDIR/data/buesingen.raw.geojson";
rm -f "$APPDIR/data/postleitzahlen.osm.json";
rm -f "$APPDIR/data/postleitzahlen.raw.geojson";

# delete uncompressed files only if compressed
if [ -e "$APPDIR/data/postleitzahlen.geojson.br" ]; then
	rm -f "$APPDIR/data/postleitzahlen.geojson";
fi;
if [ -e "$APPDIR/data/postleitzahlen.topojson.br" ]; then
	rm -f "$APPDIR/data/postleitzahlen.topojson";
fi;
