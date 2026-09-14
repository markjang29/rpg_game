import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// 8024 관례: 멀티엔트리, base './' (스프링 static 하위 동작).
// 4엔트리 — 기존 8024 5엔트리 패턴과 동일. WASM(godot-tactics)은 정적 경로 직결+lazy.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 700,
    rollupOptions: {
      input: {
        apps: 'apps.html',        // /apps/rpg 허브
        prototype: 'prototype.html', // /apps/rpg/prototype
        tactics: 'tactics.html',  // /apps/rpg/tactics
        assets: 'assets.html'     // /studio/assets (8017 import)
      }
    }
  }
})
