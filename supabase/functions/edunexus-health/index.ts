import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (_req: Request) => {
  return new Response(
    JSON.stringify({
      service: "edunexus",
      status: "ok",
      version: "1.0.0",
      architecture: "modular-monolith",
      timestamp: new Date().toISOString(),
    }),
    { headers: { "content-type": "application/json" } },
  );
});
