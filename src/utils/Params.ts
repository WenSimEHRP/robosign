export type RenderParam = {
    type: "string" | "enum";
    default?: string | number | boolean;
    variations?: Record<string, Record<string, RenderParam> | null>;
};

export function resolveParamIds(params: Record<string, RenderParam>, parentKey = ""): string[] {
    const ids: string[] = [];
    for (const [paramKey, param] of Object.entries(params)) {
        ids.push(parentKey + paramKey);
        if (param.type === "enum" && param.variations) {
            for (const [variationKey, variationParams] of Object.entries(param.variations)) {
                ids.push(...resolveParamIds(variationParams || {}, parentKey + paramKey + "::" + variationKey + "::"));
            }
        }
    }
    return ids;
}
