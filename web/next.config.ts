import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Firebase App Hosting用の静的エクスポート設定
  output: 'export',
  distDir: './out',
  trailingSlash: true,

  // パフォーマンス最適化
  compress: true,
  poweredByHeader: false,

  // 画像最適化設定（静的エクスポート用）
  images: {
    unoptimized: true, // Firebase App Hosting用
  },

  // 開発環境でのバンドル分析
  ...(process.env.ANALYZE === 'true' && {
    webpack: (config: any) => {
      // Bundle analyzer
      if (typeof require !== 'undefined') {
        const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
        config.plugins.push(
          new BundleAnalyzerPlugin({
            analyzerMode: 'static',
            openAnalyzer: false,
            reportFilename: '../bundle-analyzer-report.html',
          })
        );
      }
      return config;
    },
  }),

  // セキュリティヘッダーはFirebase Hostingで設定
};

export default nextConfig;
