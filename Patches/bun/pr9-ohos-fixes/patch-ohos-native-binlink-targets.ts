#!/usr/bin/env bun
/**
 * Patch script for OHOS builds: adds "openharmony" to the os[] field of native
 * binlink target test packages and regenerates their .tgz files using
 * Bun.gzipSync (system gzip on OHOS is toybox store-only, not real gzip).
 *
 * Run with bootstrap bun from the bun source root:
 *   bun run Patches/bun/pr9-ohos-fixes/patch-ohos-native-binlink-targets.ts
 *
 * This covers the three target packages that create-native-binlink-packages.ts
 * does NOT regenerate (altpath-target and fallback-target) plus the original
 * target.  Running after applying native-binlink-ohos.patch ensures the tarballs
 * on OHOS contain proper gzip data and the registry metadata hashes match.
 */

import { join } from "path";
import { readFile, writeFile, mkdir, rm } from "fs/promises";
import { existsSync } from "fs";
import { $ } from "bun";

const packagesDir = join(import.meta.dir, "../../../test/cli/install/registry/packages");

const targets = [
  "test-native-binlink-target",
  "test-native-binlink-altpath-target",
  "test-native-binlink-fallback-target",
];

for (const pkgName of targets) {
  const tarballName = `${pkgName}-1.0.0.tgz`;
  const tarballPath = join(packagesDir, pkgName, tarballName);
  const registryPkgJsonPath = join(packagesDir, pkgName, "package.json");

  if (!existsSync(tarballPath)) {
    console.log(`[skip] ${pkgName}: tarball not found`);
    continue;
  }

  // Extract, update, repack
  const tmpDir = `/tmp/ohos-binlink-${pkgName}`;
  await rm(tmpDir, { recursive: true, force: true });
  await mkdir(tmpDir, { recursive: true });
  await $`tar -xzf ${tarballPath} -C ${tmpDir}`;

  const innerPkgJsonPath = join(tmpDir, "package", "package.json");
  const innerPkgJson = JSON.parse(await readFile(innerPkgJsonPath, "utf8"));
  const osArr: string[] = innerPkgJson.os ?? [];
  if (!osArr.includes("openharmony")) {
    osArr.push("openharmony");
    innerPkgJson.os = osArr;
    await writeFile(innerPkgJsonPath, JSON.stringify(innerPkgJson, null, 2) + "\n");
  }

  const tmpTar = `/tmp/ohos-binlink-${pkgName}.tar`;
  await $`tar -cf ${tmpTar} -C ${tmpDir} package`;
  const tarBytes = await readFile(tmpTar);
  const gzBytes = Bun.gzipSync(tarBytes);
  await writeFile(tarballPath, gzBytes);

  // Recalculate hashes
  const sha512h = new Bun.CryptoHasher("sha512");
  sha512h.update(gzBytes);
  const integrity = `sha512-${Buffer.from(sha512h.digest()).toString("base64")}`;

  const sha1h = new Bun.CryptoHasher("sha1");
  sha1h.update(gzBytes);
  const shasum = Buffer.from(sha1h.digest()).toString("hex");

  // Update registry metadata
  const registryPkgJson = JSON.parse(await readFile(registryPkgJsonPath, "utf8"));
  const vd = registryPkgJson.versions["1.0.0"];
  const osArrR: string[] = vd.os ?? [];
  if (!osArrR.includes("openharmony")) {
    osArrR.push("openharmony");
    vd.os = osArrR;
  }
  vd.dist.integrity = integrity;
  vd.dist.shasum = shasum;
  await writeFile(registryPkgJsonPath, JSON.stringify(registryPkgJson, null, 2) + "\n");

  await rm(tmpDir, { recursive: true, force: true });
  await rm(tmpTar, { force: true });

  console.log(`[ok] ${pkgName}: os=${JSON.stringify(vd.os)}, integrity=${integrity.slice(0, 40)}...`);
}
