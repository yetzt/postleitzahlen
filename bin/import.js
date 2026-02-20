
const fs = require("node:fs/promises");
const path = require("node:path");

const pip = require("@turf/boolean-point-in-polygon").default;
const pof = require("@turf/point-on-feature").default;

const src = path.resolve(__dirname, "../data/postleitzahlen.osm.geojson");
const srcGermany = path.resolve(__dirname, "../data/germany.osm.geojson");
const dest = path.resolve(__dirname, "../data/postleitzahlen.geojson");

// recursive round
function recursiveRound(a){
	return (a instanceof Array) ? a.map(b=>recursiveRound(b)) : (Math.round(a*1e6)/1e6);
};

(async()=>{

	// load germany administrative boundaries polygon
	const polygonGermany = JSON.parse(await fs.readFile(srcGermany)).features.filter(f=>(f.geometry.type === "MultiPolygon")).shift();

	// geojson template
	const geojson = {
		"type": "FeatureCollection",
		"copyright": "© OpenStreetMap contributors, https://openstreetmap.org/copyright",
		"timestamp": (new Date()).toISOString(),
		"features": []
	};

	const doubleCheck = new Set();

	// add features from source, filter, edit and sort
	geojson.features = JSON.parse(await fs.readFile(src)).features.filter(f=>(!doubleCheck.has(f.properties.id) && f.properties.id.slice(0,8) === "relation" && f.properties.postal_code && (Object.hasOwn(f.properties, "postal_code:DE") || pip(pof(f), polygonGermany)))).map(f=>{

		// add id to double check
		doubleCheck.add(f.properties.id);

		// round geometry
		f.geometry.coordinates = recursiveRound(f.geometry.coordinates);

		// properties
		f.properties = {
			postcode: f.properties?.["postal_code:DE"] || f.properties?.postal_code,
			rel: f.properties.id.slice(9),
		};

		return f;

	}).sort((a,b)=>a.properties.postcode.localeCompare(b.properties.postcode));

	// write
	await fs.writeFile(dest, JSON.stringify(geojson));

	// info
	console.info(`Imported ${geojson.features.length} postcode areas`);

})();