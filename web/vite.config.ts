import { resolve } from 'node:path';
import vue from '@vitejs/plugin-vue';
import { defineConfig } from 'vite';

const assetDir = resolve(__dirname, '../dist/assets');

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      vue: resolve(assetDir, 'injectionKeys-DWh5N0Cf.js'),
    },
  },
  build: {
    outDir: assetDir,
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, 'src/entries/libraryBrowser.ts'),
      formats: ['es'],
      fileName: () => 'LibraryBrowser-BlmrAKrd.js',
    },
    rollupOptions: {
      external: (id) =>
        id.startsWith('./') ||
        id.startsWith('../dist/assets/') ||
        id.includes('libraryExerciseTracking-CAhSe-yn.js'),
      output: {
        paths: (id) => {
          if (id.includes('exerciseLibrary-PHUUbGWG.js')) return './exerciseLibrary-PHUUbGWG.js';
          if (id.includes('dateKey-CYtjlmzc.js')) return './dateKey-CYtjlmzc.js';
          if (id.includes('units-D1Q8qPMV.js')) return './units-D1Q8qPMV.js';
          if (id.includes('libraryExerciseTracking-CAhSe-yn.js')) {
            return './libraryExerciseTracking-CAhSe-yn.js';
          }
          if (id === 'vue' || id.includes('injectionKeys-DWh5N0Cf.js')) {
            return './injectionKeys-DWh5N0Cf.js';
          }
          return id;
        },
        entryFileNames: 'LibraryBrowser-BlmrAKrd.js',
      },
    },
  },
});
