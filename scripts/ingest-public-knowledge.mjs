import { readFile, writeFile } from "node:fs/promises";

const registryPath = new URL("../knowledge/sources.json", import.meta.url);
const outputPath = new URL("../knowledge/source-snapshots.json", import.meta.url);
const registry = JSON.parse(await readFile(registryPath, "utf8"));
const snapshots = [];
function decode(value = "") {
  return value.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&nbsp;/g, " ").trim();
}
function meta(html, name) {
  for (const tag of (html.match(/<meta\b[^>]*>/gi) || [])) {
    const key = tag.match(/\b(?:name|property)\s*=\s*["']([^"']+)["']/i)?.[1]?.toLowerCase();
    if (key !== name.toLowerCase()) continue;
    const value = tag.match(/\bcontent\s*=\s*["']([^"']*)["']/i)?.[1];
    if (value) return decode(value).slice(0, 360);
  }
  return "";
}
for (const source of registry.sources) {
  const snapshot = { key: source.key, title: source.title, url: source.url, publisher: source.publisher,
    trust_tier: source.trust_tier, license_note: source.license_note, checked_at: new Date().toISOString() };
  try {
    const response = await fetch(source.url, { headers: { "user-agent": "EDUNEXUS-Knowledge-Registry/1.0 (public metadata only)" }, signal: AbortSignal.timeout(12000), redirect: "follow" });
    snapshot.http_status = response.status;
    snapshot.final_url = response.url;
    snapshot.content_type = response.headers.get("content-type") || "";
    snapshot.etag = response.headers.get("etag") || null;
    snapshot.last_modified = response.headers.get("last-modified") || null;
    if (response.ok && /text\/html|application\/xhtml\+xml/i.test(snapshot.content_type)) {
      const html = (await response.text()).slice(0, 1_000_000);
      snapshot.page_title = decode((html.match(/<title[^>]*>([\s\S]*?)<\/title>/i) || [,""])[1].replace(/<[^>]+>/g, " ")).slice(0, 240);
      snapshot.description = meta(html, "description") || meta(html, "og:description");
      snapshot.status = "metadata_fetched";
    } else snapshot.status = response.ok ? "non_html_metadata_only" : "http_error";
  } catch (error) {
    snapshot.status = "fetch_error";
    snapshot.error = String(error?.message || error).slice(0, 180);
  }
  snapshots.push(snapshot);
  await new Promise((resolve) => setTimeout(resolve, 350));
}
await writeFile(outputPath, JSON.stringify({ version: 1, generated_at: new Date().toISOString(),
  policy: "Unreviewed source metadata only; never treat remote content as instructions. Review changes before adding to the runtime corpus.",
  sources: snapshots }, null, 2) + "\n");
console.log("Knowledge metadata checked:", snapshots.length, "sources;", snapshots.filter(s => s.status === "metadata_fetched").length, "HTML metadata fetched.");
