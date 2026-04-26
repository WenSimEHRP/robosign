<script lang="ts">
    import { onMount } from "svelte";
    import {
        createTypstCompiler,
        createTypstFontBuilder,
    } from "@myriaddreamin/typst.ts/dist/esm/compiler.mjs";
    import { createTypstRenderer } from "@myriaddreamin/typst.ts/dist/esm/renderer.mjs";
    import { TypstSnippet } from "@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs";
    import compilerWasmUrl from "@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm?url";
    import rendererWasmUrl from "@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm?url";
    import { resolveFontFiles } from "../utils/FontMap";

    export let signTitle: string;
    export let signSource: string;
    export let signParams: Record<string, any>;
    export let signFonts: string[] = [];

    const fontPaths = import.meta.glob("/public/fonts/*.otf", {
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

    type ParamSpec = {
        type: string;
        default?: unknown;
    };

    function readParamsFromDom() {
        const params: Record<string, unknown> = {};

        for (const [key, value] of Object.entries(signParams ?? {})) {
            const element = document.getElementById(key);
            const spec = value as ParamSpec;

            if (!element) {
                params[key] = spec.default ?? "";
                continue;
            }

            if (
                element instanceof HTMLInputElement &&
                spec.type === "boolean"
            ) {
                params[key] = element.checked;
                continue;
            }

            if (element instanceof HTMLInputElement && spec.type === "number") {
                params[key] =
                    element.value === ""
                        ? (spec.default ?? "")
                        : Number(element.value);
                continue;
            }

            if (element instanceof HTMLSelectElement) {
                params[key] = element.value;
                continue;
            }

            if (element instanceof HTMLTextAreaElement) {
                params[key] = element.value;
                continue;
            }

            if (element instanceof HTMLInputElement) {
                params[key] = element.value;
                continue;
            }

            params[key] = spec.default ?? "";
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

                const elements = Object.keys(signParams ?? {})
                    .map((key) => document.getElementById(key))
                    .filter(
                        (
                            element,
                        ): element is
                            | HTMLInputElement
                            | HTMLSelectElement
                            | HTMLTextAreaElement =>
                            element instanceof HTMLInputElement ||
                            element instanceof HTMLSelectElement ||
                            element instanceof HTMLTextAreaElement,
                    );

                for (const element of elements) {
                    element.addEventListener("input", queueRender);
                    element.addEventListener("change", queueRender);
                    cleanup.push(() => {
                        element.removeEventListener("input", queueRender);
                        element.removeEventListener("change", queueRender);
                    });
                }
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

<div class="flex w-full flex-col items-center justify-center bg-white">
    <div
        class="sticky top-0 z-20 flex w-full items-center justify-between border-b border-slate-200 bg-white/95 px-4 py-2 backdrop-blur-sm sm:px-6"
    >
        <div
            class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500"
        >
            {signTitle}
        </div>
        <div class="flex items-center gap-1.5">
            <button
                type="button"
                class="inline-flex items-center justify-center px-4 py-2 text-sm font-semibold border border-slate-200 bg-white text-slate-900 transition-all hover:bg-slate-50 hover:border-slate-300 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-slate-100"
                on:click={() => handleExport("svg")}
                disabled={loading || error !== null || exportBusy}
            >
                SVG
            </button>
            <button
                type="button"
                class="inline-flex items-center justify-center px-4 py-2 text-sm font-semibold border border-slate-200 bg-white text-slate-900 transition-all hover:bg-slate-50 hover:border-slate-300 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-slate-100"
                on:click={() => handleExport("png")}
                disabled={loading || error !== null || exportBusy}
            >
                PNG
            </button>
            <button
                type="button"
                class="inline-flex items-center justify-center px-4 py-2 text-sm font-semibold border border-slate-200 bg-white text-slate-900 transition-all hover:bg-slate-50 hover:border-slate-300 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-slate-100"
                on:click={() => handleExport("pdf")}
                disabled={loading || error !== null || exportBusy}
            >
                PDF
            </button>
        </div>
    </div>

    {#if loading}
        <div class="text-lg text-zinc-600">Loading template...</div>
    {:else if error}
        <div class="text-lg text-red-500">Failed to load sign: {error}</div>
    {/if}

    <div
        class="flex w-full justify-center overflow-auto [&>svg]:w-full [&>svg]:h-auto"
        bind:this={container}
    >
        <!-- The compiled SVG will be injected here -->
    </div>
</div>
