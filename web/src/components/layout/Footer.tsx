import Link from 'next/link';
import { Container } from '@/components/ui/Container';

export function Footer() {
  const currentYear = new Date().getFullYear();

  const footerLinks = [
    {
      title: 'サイト',
      links: [
        { name: 'プライバシーポリシー', href: '/privacy-policy' },
        { name: 'サポート', href: '/support' },
      ],
    },
  ];

  return (
    <footer className="bg-gray-50 border-t border-gray-200">
      <Container>
        <div className="py-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            {/* Logo and Description */}
            <div className="md:col-span-2">
              <div className="flex items-center mb-4">
                <div className="w-8 h-8 bg-gradient-to-br from-orange-400 to-pink-500 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">P</span>
                </div>
                <span className="ml-2 text-lg font-bold text-gray-900">
                  パーソナルカラー診断アプリ
                </span>
              </div>
              <p className="text-gray-600 text-sm leading-relaxed max-w-md">
                AIが教える、あなたに似合う色を発見しよう！小学5年生から楽しく使える、安全で教育的なパーソナルカラー診断アプリです。
              </p>
            </div>

            {/* Links */}
            {footerLinks.map((section) => (
              <div key={section.title}>
                <h3 className="text-gray-900 font-medium mb-3">
                  {section.title}
                </h3>
                <ul className="space-y-2">
                  {section.links.map((link) => (
                    <li key={link.name}>
                      <Link
                        href={link.href}
                        className="text-gray-600 hover:text-gray-900 text-sm transition-colors"
                      >
                        {link.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}

            {/* Contact Info */}
            <div>
              <h3 className="text-gray-900 font-medium mb-3">お問い合わせ</h3>
              <div className="space-y-2 text-sm text-gray-600">
                <p>サポートが必要な場合は</p>
                <Link
                  href="/support"
                  className="text-orange-600 hover:text-orange-700 transition-colors"
                >
                  サポートページ
                </Link>
                <span> をご利用ください</span>
              </div>
            </div>
          </div>

          {/* Copyright */}
          <div className="mt-8 pt-8 border-t border-gray-200">
            <div className="flex flex-col md:flex-row items-center justify-between">
              <p className="text-gray-500 text-sm">
                © {currentYear} パーソナルカラー診断アプリ. All rights
                reserved.
              </p>
              <div className="mt-4 md:mt-0">
                <p className="text-gray-400 text-xs">
                  Made with ❤️ for safe and educational entertainment
                </p>
              </div>
            </div>
          </div>
        </div>
      </Container>
    </footer>
  );
}
