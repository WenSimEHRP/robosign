#!/usr/bin/env bun

import { mkdir, exists } from "node:fs/promises";
import { join } from "node:path";
import { $ } from "bun";

const paths = [
    "https://github.com/notofonts/noto-cjk/releases/download/Sans2.004/05_NotoSansCJK-SubsetOTF.zip"
];

const TEMP_DIR = "./temp_fonts";
const DEST_DIR = "./public/fonts";

try {
    await $`7z --help`.quiet();
} catch (e) {
    console.error("Error: '7z' (p7zip) is not installed or not in your PATH.");
    process.exit(1);
}

if (!(await exists(DEST_DIR))) {
    await mkdir(DEST_DIR, { recursive: true });
}

for (const url of paths) {
    const filename = url.split("/").pop();
    const downloadPath = join(TEMP_DIR, filename);
    const extractPath = join(TEMP_DIR, "extracted");

    console.log(`--- Processing: ${filename} ---`);

    await $`rm -rf ${TEMP_DIR}`;
    await mkdir(TEMP_DIR, { recursive: true });

    console.log(`Downloading...`);
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to download ${url}`);
    await Bun.write(downloadPath, await response.arrayBuffer());

    console.log(`Extracting with 7z...`);
    await $`7z x ${downloadPath} -o${extractPath} -y`.quiet();

    console.log(`Moving fonts to ${DEST_DIR}...`);
    await $`find ${extractPath} -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec mv {} ${DEST_DIR} \;`;

    await $`rm -rf ${TEMP_DIR}`;
    console.log(`Done with ${filename}\n`);
}

console.log("All fonts processed successfully!");
