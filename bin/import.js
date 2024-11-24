
const fs = require("node:fs/promises");
const path = require("node:path");

const src = path.resolve(__dirname, "../data/postleitzahlen.raw.geojson");
const srcBuesingen = path.resolve(__dirname, "../data/buesingen.raw.geojson");
const dest = path.resolve(__dirname, "../data/postleitzahlen.geojson");

// recursive round
function recursiveRound(a){
	return (a instanceof Array) ? a.map(b=>recursiveRound(b)) : (Math.round(a*1e6)/1e6);
};

(async()=>{

	// geojson template
	const geojson = {
		"type": "FeatureCollection",
		"copyright": "© OpenStreetMap contributors, https://openstreetmap.org/copyright",
		"timestamp": (new Date()).toISOString(),
		"features": []
	};

	// add features from source
	geojson.features = JSON.parse(await fs.readFile(src)).features;
	geojson.features.push(JSON.parse(await fs.readFile(srcBuesingen)).features.pop());

	// edit features
	geojson.features = geojson.features.map(f=>{

		// round geometry
		f.geometry.coordinates = recursiveRound(f.geometry.coordinates);

		// properties
		f.properties = {
			postcode: f.properties.postal_code,
			rel: f.properties.id.split("/").pop(),
		};

		return f;

	}).sort((a,b)=>a.properties.postcode.localeCompare(b.properties.postcode)); // sort

	// write
	await fs.writeFile(dest, JSON.stringify(geojson));

})();