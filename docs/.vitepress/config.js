import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'kiri-check',
  description: 'Property-based testing library for Dart/Flutter',
  base: '/kiri-check-doc/',
  
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Quickstart', link: '/quickstart' },
      { text: 'pub.dev', link: 'https://pub.dev/packages/kiri_check' }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Quickstart', link: '/quickstart' },
          { text: 'Write Properties', link: '/properties/write-properties' },
          { text: 'Configure Tests', link: '/properties/configure-tests' }
        ]
      },
      {
        text: 'Arbitraries',
        items: [
          { text: 'Overview', link: '/arbitraries' },
          { text: 'Generation', link: '/generation' },
          { text: 'Shrinking', link: '/shrinking' }
        ]
      },
      {
        text: 'Stateful Testing',
        items: [
          { text: 'Overview', link: '/stateful/' },
          { text: 'Quickstart', link: '/stateful/quickstart' },
          { text: 'Write Properties', link: '/stateful/properties' },
          { text: 'Commands', link: '/stateful/commands' }
        ]
      },
      {
        text: 'Advanced',
        items: [
          { text: 'Statistics', link: '/statistics' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/szktty/kiri-check' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 SUZUKI Tetsuya'
    }
  },

  // Custom CSS variables to match the forest theme
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `
            :root {
              --vp-c-brand-1: #10b981;
              --vp-c-brand-2: #059669;
              --vp-c-brand-3: #047857;
              --vp-c-brand-soft: rgba(16, 185, 129, 0.14);
            }
          `
        }
      }
    }
  }
})