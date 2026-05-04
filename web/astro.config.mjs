// @ts-check
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  output: 'static',
  outDir: './dist',
  integrations: [
    tailwind(),
    sitemap({
      // Exclude invite pages — trips are private, don't index codes
      filter: (page) => !page.includes('/j/'),
    }),
  ],
  site: 'https://vamos.app',
});
