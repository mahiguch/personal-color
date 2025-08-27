import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
          50: '#fef7ff',
          100: '#fceeff', 
          500: '#8B5CF6',  // Figmaプライマリー紫
          600: '#7C3AED',  // Figmaプライマリー濃紫
          900: '#581c87',
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
          success: '#10B981',   // Figmaの成功色（緑）
          warning: '#F59E0B',   // Figmaの警告色（オレンジ）
          error: '#EF4444',     // Figmaのエラー色（赤）
          info: '#3B82F6',      // Figmaの情報色（青）
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        warm: {
          // イエベ（イエローベース）- Figmaの暖色系
          50: '#fefce8',
          400: '#FDE047',  // Figmaの黄色ベース
          500: '#F59E0B',  // Figmaの暖色アクセント
          600: '#D97706',  // 暖色の濃い色
          700: '#B45309',  // 最暖色
        },
        cool: {
          // ブルベ（ブルーベース）- Figmaの寒色系
          50: '#eff6ff',
          400: '#60A5FA',  // Figmaの青ベース
          500: '#3B82F6',  // Figmaの寒色アクセント
          600: '#2563EB',  // 寒色の濃い色
          700: '#1D4ED8',  // 最寒色
        },
      },
      fontFamily: {
        sans: ['Inter', 'Hiragino Sans', 'Yu Gothic UI', 'sans-serif'],
      },
      fontSize: {
        '5xl': ['3rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }], // Hero
        '3xl': ['2rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }], // Section  
        'xl': ['1.25rem', { lineHeight: '1.5' }], // Cards
        'base': ['1rem', { lineHeight: '1.5' }],  // Body
        'sm': ['0.875rem', { lineHeight: '1.5' }],
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [tailwindcssAnimate],
} satisfies Config;

export default config;
