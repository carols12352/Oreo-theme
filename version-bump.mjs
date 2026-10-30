/**
 * Sync theme version across package.json, manifest.json, and versions.json.
 *
 * Usage:
 *   node version-bump.mjs                 # use process.env.npm_package_version
 *   node version-bump.mjs 1.3.7           # set an explicit version
 *   npm version patch                     # npm sets package version, then runs this via "version" script
 */

import { readFileSync, writeFileSync } from "fs";

const packageJsonForFallback = JSON.parse(readFileSync("package.json", "utf8"));
const targetVersion =
	process.argv[2] || process.env.npm_package_version || packageJsonForFallback.version;

if (!targetVersion) {
	console.error("No version provided. Pass a version or run via npm version / npm run version.");
	process.exit(1);
}

if (!/^\d+\.\d+\.\d+(-[\w.-]+)?$/.test(targetVersion)) {
	console.error(`Invalid version: ${targetVersion}`);
	process.exit(1);
}

let packageJson = packageJsonForFallback;
packageJson.version = targetVersion;
writeFileSync("package.json", JSON.stringify(packageJson, null, "\t") + "\n");

let manifest = JSON.parse(readFileSync("manifest.json", "utf8"));
const { minAppVersion } = manifest;
manifest.version = targetVersion;
writeFileSync("manifest.json", JSON.stringify(manifest, null, "\t") + "\n");

let versions = JSON.parse(readFileSync("versions.json", "utf8"));
versions[targetVersion] = minAppVersion;
writeFileSync("versions.json", JSON.stringify(versions, null, "\t") + "\n");

console.log(`Bumped to ${targetVersion} (minAppVersion ${minAppVersion})`);
