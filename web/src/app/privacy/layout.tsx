import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'プライバシーポリシー | AIスタイリスト',
  description: 'AIスタイリストのプライバシーポリシー。お子様の安全とプライバシー保護を最優先に、透明性を持って情報の取り扱いについてご説明いたします。',
  keywords: 'プライバシーポリシー, 個人情報保護, 子供向け, パーソナルカラー診断, データ保護',
  openGraph: {
    title: 'プライバシーポリシー | AIスタイリスト',
    description: 'お子様の安全とプライバシー保護を最優先に、透明性を持って情報の取り扱いについてご説明いたします。',
    type: 'article',
  },
};

export default function PrivacyLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
