<script lang="ts">
    import { onMount } from "svelte";
    import {
        createTypstCompiler,
        createTypstFontBuilder,
    } from "@myriaddreamin/typst.ts/dist/esm/compiler.mjs";
    import { createTypstRenderer } from "@myriaddreamin/typst.ts/dist/esm/renderer.mjs";
    import { TypstSnippet } from "@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs";
    // Those files won't fit in cloudflare's 25mib limit
    // import compilerWasmUrl from "@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm?url";
    // import rendererWasmUrl from "@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm?url";
    const compilerWasmUrl =
        "https://unpkg.com/@myriaddreamin/typst-ts-web-compiler@0.7.0-rc2/pkg/typst_ts_web_compiler_bg.wasm";
    const rendererWasmUrl =
        "https://unpkg.com/@myriaddreamin/typst-ts-renderer@0.7.0-rc2/pkg/typst_ts_renderer_bg.wasm";
    import { resolveFontFiles } from "../utils/FontMap";
    import { resolveParamIds, type RenderParam } from "../utils/Params";

    export let signTitle: string;
    export let signSource: string;
    export let signAssets: Record<string, string> = {};
    export let signParams: Record<string, RenderParam>;
    let signParamIds: string[] = resolveParamIds(signParams);
    export let signFonts: string[] = [];

    const fontPaths = import.meta.glob("/public/fonts/*.{otf,ttf}", {
        query: "?url",
        import: "default",
    });

    let container: HTMLDivElement;
    let loading = true;
    let error: string | null = null;
    let initialized = false;
    let renderRevision = 0;
    let renderQueued = false;
    let exportBusy = false;
    let compiler: ReturnType<typeof createTypstCompiler> | null = null;
    let renderer: ReturnType<typeof createTypstRenderer> | null = null;
    let lastExportVectorData: Uint8Array<ArrayBufferLike> | null = null;
    let lastExportPdfData: Uint8Array<ArrayBufferLike> | null = null;
    let exportTypst: TypstSnippet | null = null;

    function isVisibleElement(element: Element) {
        for (let current: Element | null = element; current; current = current.parentElement) {
            if (current.hasAttribute("hidden")) {
                return false;
            }

            const styles = getComputedStyle(current);
            if (styles.display === "none" || styles.visibility === "hidden" || styles.visibility === "collapse") {
                return false;
            }
        }

        return true;
    }

    function readParamsFromDom() {
        const params: Record<string, string | null> = {};

        for (const key of signParamIds) {
            const element = document.getElementById(key);

            if (
                element instanceof HTMLInputElement ||
                element instanceof HTMLSelectElement ||
                element instanceof HTMLTextAreaElement
            ) {
                if (element instanceof HTMLInputElement && element.type === "radio") {
                    continue;
                }

                if (isVisibleElement(element)) {
                    params[key] = element.value;
                }
                continue;
            }

            const selectedRadio = document.querySelector<HTMLInputElement>(
                `input[name="${CSS.escape(key)}"]:checked`,
            );

            if (selectedRadio && isVisibleElement(selectedRadio)) {
                params[`${key}::${selectedRadio.value}`] = null;
            }
        }

        return params;
    }

    async function renderDocument() {
        const activeCompiler = compiler;
        const activeRenderer = renderer;

        if (!activeCompiler || !activeRenderer) {
            return;
        }

        const revision = ++renderRevision;
        const paramsInput = JSON.stringify(readParamsFromDom());

        try {
            error = null;
            activeCompiler.addSource("/main.typ", signSource);
            for (const [assetPath, assetData] of Object.entries(signAssets)) {
                activeCompiler.addSource(`/${assetPath}`, assetData);
            }

            const svgStr = await activeCompiler.runWithWorld(
                {
                    mainFilePath: "/main.typ",
                    inputs: { params: paramsInput },
                },
                async (world) => {
                    const vectorResult = await world.vector({
                        diagnostics: "full",
                    });
                    const pdfResult = await world.pdf({ diagnostics: "full" });

                    if (!vectorResult.result || !pdfResult.result) {
                        throw new Error("Failed to compile typst template.");
                    }

                    lastExportVectorData = vectorResult.result;
                    lastExportPdfData = pdfResult.result;

                    return await activeRenderer.renderSvg({
                        format: "vector",
                        artifactContent: vectorResult.result,
                    });
                },
            );
            if (revision !== renderRevision || !container) {
                return;
            }

            container.innerHTML = svgStr;
        } catch (err) {
            if (revision !== renderRevision) {
                return;
            }

            console.error(err);
            error = (err as Error).message;
            if (container) {
                container.innerHTML = "";
            }
        } finally {
            if (revision === renderRevision) {
                loading = false;
                renderQueued = false;
            }
        }
    }

    function queueRender() {
        if (!initialized || renderQueued) {
            return;
        }

        renderQueued = true;
        loading = true;
        void renderDocument();
    }

    function downloadBlob(blob: Blob, fileName: string) {
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = fileName;
        link.rel = "noopener noreferrer";
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(url);
    }

    async function getExportTypst() {
        const snippet = exportTypst;

        if (!snippet) {
            throw new Error("Typst renderer is not ready yet.");
        }

        return snippet;
    }

    function sanitizeSvgForDownload(svg: string) {
        return svg
            .replace(/&nbsp;/g, "&#160;")
            .replace(
                /&(?!#\d+;|#x[0-9A-Fa-f]+;|amp;|lt;|gt;|quot;|apos;)/g,
                "&amp;",
            );
    }

    async function exportSvg() {
        exportBusy = true;
        try {
            const vectorData = lastExportVectorData;
            if (!vectorData) {
                throw new Error("No compiled vector data is available yet.");
            }

            const snippet = await getExportTypst();
            const svg = sanitizeSvgForDownload(
                await snippet.svg({ vectorData }),
            );
            downloadBlob(
                new Blob([svg], {
                    type: "image/svg+xml;charset=utf-8",
                }),
                `${document.title.replace(/\s+/g, "-").toLowerCase()}.svg`,
            );
        } finally {
            exportBusy = false;
        }
    }

    async function exportPng() {
        exportBusy = true;
        try {
            const vectorData = lastExportVectorData;
            if (!vectorData) {
                throw new Error("No compiled vector data is available yet.");
            }

            const snippet = await getExportTypst();
            const tempContainer = document.createElement("div");
            tempContainer.style.position = "fixed";
            tempContainer.style.left = "-10000px";
            tempContainer.style.top = "0";
            tempContainer.style.width = "1px";
            tempContainer.style.height = "1px";
            tempContainer.style.overflow = "hidden";
            tempContainer.style.pointerEvents = "none";
            document.body.appendChild(tempContainer);

            try {
                await snippet.canvas(tempContainer, { vectorData });

                const renderedCanvas = tempContainer.querySelector("canvas");
                if (!(renderedCanvas instanceof HTMLCanvasElement)) {
                    throw new Error(
                        "Failed to locate rendered canvas for PNG export.",
                    );
                }

                const pngBlob = await new Promise<Blob | null>((resolve) =>
                    renderedCanvas.toBlob((blob) => resolve(blob), "image/png"),
                );

                if (!pngBlob) {
                    throw new Error("Failed to create PNG image.");
                }

                downloadBlob(
                    pngBlob,
                    `${document.title.replace(/\s+/g, "-").toLowerCase()}.png`,
                );
            } finally {
                tempContainer.remove();
            }
        } finally {
            exportBusy = false;
        }
    }

    async function exportPdf() {
        exportBusy = true;
        try {
            const pdf = lastExportPdfData;
            if (!pdf) {
                throw new Error("No compiled PDF data is available yet.");
            }

            const pdfBuffer = pdf.buffer.slice(
                pdf.byteOffset,
                pdf.byteOffset + pdf.byteLength,
            ) as ArrayBuffer;
            downloadBlob(
                new Blob([pdfBuffer], { type: "application/pdf" }),
                `${document.title.replace(/\s+/g, "-").toLowerCase()}.pdf`,
            );
        } finally {
            exportBusy = false;
        }
    }

    async function handleExport(format: "svg" | "png" | "pdf") {
        if (exportBusy) {
            return;
        }

        if (format === "svg") {
            await exportSvg();
        } else if (format === "png") {
            await exportPng();
        } else {
            await exportPdf();
        }
    }

    onMount(() => {
        const cleanup: Array<() => void> = [];

        void (async () => {
            try {
                const win = window as any;
                if (!win.$typst$compiler) {
                    win.$typst$compiler = createTypstCompiler();
                    await win.$typst$compiler.init({
                        getModule: () => compilerWasmUrl,
                    });
                }
                if (!win.$typst$renderer) {
                    win.$typst$renderer = createTypstRenderer();
                    await win.$typst$renderer.init({
                        getModule: () => rendererWasmUrl,
                    });
                }

                const compilerInstance = win.$typst$compiler;
                const rendererInstance = win.$typst$renderer;

                compiler = compilerInstance;
                renderer = rendererInstance;
                exportTypst = new TypstSnippet({
                    compiler: compilerInstance,
                    renderer: rendererInstance,
                });

                // Initialize and load fonts if not done
                if (!win.$typst$fonts_loaded) {
                    const builder = createTypstFontBuilder();
                    await builder.init();
                    const selectedFontFiles = resolveFontFiles(signFonts);
                    const selectedFontFileSet = new Set(selectedFontFiles);

                    for (const [path, resolver] of Object.entries(fontPaths)) {
                        const fileName = path.split("/").pop() ?? "";
                        if (!selectedFontFileSet.has(fileName)) {
                            continue;
                        }

                        let urlStr: string;
                        if (typeof resolver === "function") {
                            // resolve the dynamic import to get the URL
                            urlStr = (await resolver()) as string;
                        } else {
                            urlStr = path.replace("/public", "");
                        }
                        try {
                            const fontRes = await fetch(urlStr);
                            const buffer = await fontRes.arrayBuffer();
                            await builder.addFontData(new Uint8Array(buffer));
                        } catch (fontErr) {
                            console.warn(
                                `Failed to load font ${urlStr}:`,
                                fontErr,
                            );
                        }
                    }
                    await builder.build(async (fontResolver) => {
                        compilerInstance.setFonts(fontResolver);
                        win.$typst$fonts_loaded = true;
                    });
                }

                initialized = true;
                queueRender();

                document.addEventListener("input", queueRender, true);
                document.addEventListener("change", queueRender, true);
                cleanup.push(() => {
                    document.removeEventListener("input", queueRender, true);
                    document.removeEventListener("change", queueRender, true);
                });
            } catch (err) {
                console.error(err);
                error = (err as Error).message;
                loading = false;
            }
        })();

        return () => {
            for (const dispose of cleanup) {
                dispose();
            }
        };
    });

    $: if (initialized) {
        void renderDocument();
    }
</script>

<div class="flex w-full flex-col items-center justify-center bg-(--app-surface-strong) text-(--app-fg)">
    <div
        class="flex w-full flex-col gap-2 border-b border-(--app-border) bg-(--app-surface) px-3 py-3 backdrop-blur-sm sm:flex-row sm:items-center sm:justify-between sm:px-6 sm:py-2"
    >
        <div
            class="text-center text-xs font-semibold uppercase tracking-[0.22em] text-(--app-muted-fg) sm:text-left"
        >
            {signTitle}
        </div>
        <div class="flex w-full flex-wrap gap-1.5 sm:w-auto sm:justify-end">
            <button
                type="button"
                class="inline-flex flex-1 items-center justify-center border border-(--app-border) bg-(--app-surface-strong) px-4 py-2 text-sm font-semibold text-(--app-fg) transition-all hover:border-(--app-muted) hover:bg-(--app-surface) active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-(--app-surface) sm:flex-none"
                on:click={() => handleExport("svg")}
                disabled={loading || error !== null || exportBusy}
            >
                SVG
            </button>
            <button
                type="button"
                class="inline-flex flex-1 items-center justify-center border border-(--app-border) bg-(--app-surface-strong) px-4 py-2 text-sm font-semibold text-(--app-fg) transition-all hover:border-(--app-muted) hover:bg-(--app-surface) active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-(--app-surface) sm:flex-none"
                on:click={() => handleExport("png")}
                disabled={loading || error !== null || exportBusy}
            >
                PNG
            </button>
            <button
                type="button"
                class="inline-flex flex-1 items-center justify-center border border-(--app-border) bg-(--app-surface-strong) px-4 py-2 text-sm font-semibold text-(--app-fg) transition-all hover:border-(--app-muted) hover:bg-(--app-surface) active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-(--app-surface) sm:flex-none"
                on:click={() => handleExport("pdf")}
                disabled={loading || error !== null || exportBusy}
            >
                PDF
            </button>
        </div>
    </div>

    {#if loading}
        <div class="text-lg text-(--app-muted-fg)">Loading template...</div>
    {:else if error}
        <div class="text-lg text-red-500 dark:text-red-400">Failed to load sign: {error}</div>
    {/if}

    <div
        class="flex w-full justify-center overflow-auto [&>svg]:w-full [&>svg]:h-auto"
        bind:this={container}
    >
        <!-- The compiled SVG will be injected here -->
    </div>
</div>
