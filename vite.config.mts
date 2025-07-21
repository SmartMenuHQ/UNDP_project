import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import svgr from 'vite-plugin-svgr'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    tsconfigPaths(),
    RubyPlugin(),
    svgr({
      svgrOptions: {
        icon: true,
      },
    }),
  ],
  optimizeDeps: {
    include: ['react', 'react-dom']
  },
  resolve: {
    extensions: ['.mjs', '.js', '.ts', '.jsx', '.tsx', '.json'],
  },
  build: {
    rollupOptions: {
      input: {
        app: './app/javascript/entrypoint/client/index.tsx'
      }
    }
  },
  server: {
    hmr: {
      overlay: false
    }
  }
})
