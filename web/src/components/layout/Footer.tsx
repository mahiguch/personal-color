'use client';

import Link from 'next/link';
import Image from 'next/image';
import { Badge } from '@/components/ui/badge';
import { MESSAGES } from '@/lib/constants';

export function Footer() {
  return (
    <footer className="bg-gray-50 border-t border-gray-200">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* 左側：ロゴ・説明 */}
          <div className="md:col-span-2">
            <div className="flex items-center space-x-3 mb-4">
              <Image
                src="/app_icon.svg"
                alt="パーソナルカラー診断アプリ"
                width={40}
                height={40}
                className="object-contain"
              />
              <div>
                <h3 className="font-semibold text-lg text-gray-900">
                  パーソナルカラー診断アプリ
                </h3>
                <p className="text-sm text-gray-600">
                  {MESSAGES.footer.description}
                </p>
              </div>
            </div>
          </div>

          {/* 中央：サイトマップ */}
          <div>
            <h4 className="font-medium text-gray-900 mb-4">サイトマップ</h4>
            <ul className="space-y-2">
              <li>
                <Link 
                  href="/#features" 
                  className="text-gray-600 hover:text-primary-600 transition-colors"
                >
                  {MESSAGES.footer.links.about}
                </Link>
              </li>
              <li>
                <Link 
                  href="/support" 
                  className="text-gray-600 hover:text-primary-600 transition-colors"
                >
                  {MESSAGES.footer.links.support}
                </Link>
              </li>
              <li>
                <Link 
                  href="/privacy" 
                  className="text-gray-600 hover:text-primary-600 transition-colors"
                >
                  {MESSAGES.footer.links.privacy}
                </Link>
              </li>
            </ul>
          </div>

          {/* 右側：ステータスバッジ */}
          <div className="flex flex-col items-start md:items-end space-y-3">
            <Badge 
              variant="outline" 
              className="bg-gradient-to-r from-warm-400 to-cool-400 text-white border-none px-4 py-2 text-sm font-medium"
            >
              {MESSAGES.hero.cta}
            </Badge>
            <div className="text-xs text-gray-500 text-center md:text-right">
              <p>iOS 15+ 対応予定</p>
              <p>安全・プライバシー重視</p>
            </div>
          </div>
        </div>

        {/* 下部：著作権 */}
        <div className="mt-8 pt-8 border-t border-gray-200">
          <div className="flex flex-col md:flex-row justify-between items-center space-y-2 md:space-y-0">
            <p className="text-sm text-gray-500">
              {MESSAGES.footer.copyright}
            </p>
            <div className="flex items-center space-x-1 text-xs text-gray-400">
              <span>Powered by</span>
              <span className="font-medium text-primary-600">Next.js 15</span>
              <span>+</span>
              <span className="font-medium text-primary-600">AI</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
