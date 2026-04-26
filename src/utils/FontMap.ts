const notoVariations = [
  "Black",
  "Bold",
  "DemiLight",
  "Light",
  "Medium",
  "Regular",
  "Thin",
];

const map: Record<string, string[]> = {
  "noto sans cjk sc": notoVariations.map(
    (weight) => `NotoSansSC-${weight}.otf`,
  ),
  "noto sans cjk tc": notoVariations.map(
    (weight) => `NotoSansTC-${weight}.otf`,
  ),
  "noto sans cjk jp": notoVariations.map(
    (weight) => `NotoSansJP-${weight}.otf`,
  ),
  "noto sans cjk kr": notoVariations.map(
    (weight) => `NotoSansKR-${weight}.otf`,
  ),
  "fira sans": [
    "FiraSans-Black.ttf",
    "FiraSans-Bold.ttf",
    "FiraSans-ExtraBold.ttf",
    "FiraSans-ExtraLight.ttf",
    "FiraSans-Light.ttf",
    "FiraSans-Medium.ttf",
    "FiraSans-Regular.ttf",
    "FiraSans-SemiBold.ttf",
    "FiraSans-Thin.ttf",
  ],
};

const fallbackFontFamily = "noto sans cjk sc";

export function resolveFontFiles(fontFamilies: string[] | undefined): string[] {
  const requestedFamilies = (fontFamilies ?? []).map((family) =>
    family.trim().toLowerCase(),
  );
  const matchedFiles = new Set<string>();

  for (const family of requestedFamilies) {
    const files = map[family];
    if (!files) {
      continue;
    }

    for (const file of files) {
      matchedFiles.add(file);
    }
  }

  if (matchedFiles.size > 0) {
    return Array.from(matchedFiles);
  }

  return [...map[fallbackFontFamily]];
}
