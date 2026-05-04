/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        // Brand colors — aligned with the app palette (placeholder until high-fi design)
        brand: {
          50: '#fef9ec',
          100: '#fef0c7',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
        },
      },
      fontFamily: {
        sans: [
          'Inter',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
};
