import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  functions: {
    edunexusai: {
      name: "EDUNEXUS AI Runtime",
      source: "neon/functions/edunexusai/index.mjs",
    },
  },
});
