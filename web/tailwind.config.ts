import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // カラーパレット定義 - ミニマルデザイン
      colors: {
        // プライマリカラー（ソフトなグリーン系）
        primary: {
          50: '#f6f7f5',
          100: '#e9ebe6',
          200: '#d4d8ce',
          300: '#b5bcab',
          400: '#8e9c78', // メインカラー
          500: '#748567',
          600: '#5d6b52',
          700: '#4b5542',
          800: '#3e4537',
          900: '#363a30',
          950: '#1c1f19',
        },
        // セカンダリカラー（ニュートラルグレー）
        secondary: {
          50: '#fafafa',
          100: '#f4f4f5',
          200: '#e4e4e7',
          300: '#d4d4d8',
          400: '#a1a1aa',
          500: '#71717a',
          600: '#52525b',
          700: '#3f3f46',
          800: '#27272a',
          900: '#18181b',
          950: '#09090b',
        },
        // グレースケール（カスタマイズ）
        gray: {
          50: '#fafafa',
          100: '#f4f4f5',
          200: '#e4e4e7',
          300: '#d4d4d8',
          400: '#a1a1aa',
          500: '#71717a',
          600: '#52525b',
          700: '#3f3f46',
          800: '#27272a',
          900: '#18181b',
          950: '#09090b',
        },
        // 成功・エラー・警告カラー
        success: {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
          950: '#052e16',
        },
        error: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
          950: '#450a0a',
        },
        warning: {
          50: '#fefdf5',
          100: '#fdf9eb',
          200: '#f9f1c7',
          300: '#f3e8a3',
          400: '#ebd65f',
          500: '#d4b942',
          600: '#b8962f',
          700: '#967626',
          800: '#7d5f23',
          900: '#694f22',
          950: '#3c2b10',
        },
        // パーソナルカラー関連
        'personal-color': {
          'yellow-base': '#f59e0b',
          'blue-base': '#3b82f6',
          warm: '#f97316',
          cool: '#06b6d4',
        },
      },
      // フォント設定 - モダンなタイポグラフィ
      fontFamily: {
        sans: [
          '"DM Sans"',
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          'sans-serif',
        ],
        serif: ['"Crimson Text"', 'Georgia', 'serif'],
        mono: ['"Roboto Mono"', '"SF Mono"', 'Monaco', 'Consolas', 'monospace'],
        ja: [
          '"Noto Sans JP"',
          '"DM Sans"',
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          'sans-serif',
        ],
      },
      // レスポンシブタイポグラフィ
      letterSpacing: {
        tighter: '-0.05em',
        tight: '-0.025em',
        normal: '0em',
        wide: '0.025em',
        wider: '0.05em',
        widest: '0.1em',
      },
      // スペーシングシステム
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      // ブレイクポイント（デフォルト値を明示）
      screens: {
        xs: '475px',
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
        '2xl': '1536px',
      },
      // 影（シャドウ）
      boxShadow: {
        soft: '0 2px 8px 0 rgba(0, 0, 0, 0.06)',
        medium: '0 4px 12px 0 rgba(0, 0, 0, 0.08)',
        hard: '0 8px 25px 0 rgba(0, 0, 0, 0.12)',
        'colored-primary': '0 8px 25px 0 rgba(249, 115, 22, 0.15)',
        'colored-secondary': '0 8px 25px 0 rgba(59, 130, 246, 0.15)',
      },
      // 角丸
      borderRadius: {
        '4xl': '2rem',
        '5xl': '2.5rem',
      },
      // アニメーション
      animation: {
        'fade-in': 'fade-in 0.5s ease-out',
        'fade-up': 'fade-up 0.5s ease-out',
        'scale-in': 'scale-in 0.2s ease-out',
        'slide-down': 'slide-down 0.3s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'scale-in': {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        'slide-down': {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      // タイポグラフィ
      fontSize: {
        '2xs': ['0.625rem', { lineHeight: '0.75rem' }],
        xs: ['0.75rem', { lineHeight: '1rem' }],
        sm: ['0.875rem', { lineHeight: '1.25rem' }],
        base: ['1rem', { lineHeight: '1.5rem' }],
        lg: ['1.125rem', { lineHeight: '1.75rem' }],
        xl: ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '3.25rem' }],
        '6xl': ['3.75rem', { lineHeight: '4rem' }],
        '7xl': ['4.5rem', { lineHeight: '4.75rem' }],
        '8xl': ['6rem', { lineHeight: '6.25rem' }],
        '9xl': ['8rem', { lineHeight: '8.25rem' }],
      },
      // レスポンシブ設計用の最大幅
      maxWidth: {
        '8xl': '88rem',
        '9xl': '96rem',
      },
      // Z-index レイヤー管理
      zIndex: {
        '60': '60',
        '70': '70',
        '80': '80',
        '90': '90',
        '100': '100',
      },
    },
  },
  plugins: [],
};

export default config;
