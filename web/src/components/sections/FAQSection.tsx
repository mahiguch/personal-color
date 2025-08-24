'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { ChevronDownIcon, ChevronUpIcon } from 'lucide-react';
import { FAQ_ITEMS } from '@/lib/constants';

interface FAQItemProps {
  question: string;
  answer: string;
  index: number;
  isOpen: boolean;
  onToggle: () => void;
}

function FAQItem({ question, answer, index, isOpen, onToggle }: FAQItemProps) {
  const colorClasses = [
    'border-primary-200 bg-primary-25',
    'border-warm-200 bg-warm-25',
    'border-cool-200 bg-cool-25',
    'border-accent-success bg-green-25',
    'border-accent-info bg-blue-25',
    'border-accent-warning bg-yellow-25',
  ];

  return (
    <Card className={`${colorClasses[index % 6]} border-2 rounded-xl overflow-hidden transition-all duration-300`}>
      <CardContent className="p-0">
        <Button
          variant="ghost"
          className="w-full p-6 text-left hover:bg-transparent transition-colors duration-200"
          onClick={onToggle}
        >
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-gray-900 pr-4 leading-relaxed">
              Q{index + 1}. {question}
            </h3>
            <div className="flex-shrink-0">
              {isOpen ? (
                <ChevronUpIcon className="h-5 w-5 text-gray-600" />
              ) : (
                <ChevronDownIcon className="h-5 w-5 text-gray-600" />
              )}
            </div>
          </div>
        </Button>
        
        {isOpen && (
          <div className="px-6 pb-6 animate-fadeIn">
            <div className="pt-4 border-t border-gray-200/50">
              <p className="text-gray-700 leading-relaxed whitespace-pre-line">
                {answer}
              </p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export function FAQSection({ isStandalone = false }: { isStandalone?: boolean }) {
  const [openItems, setOpenItems] = useState<number[]>([]);

  const toggleItem = (index: number) => {
    setOpenItems(prev => 
      prev.includes(index) 
        ? prev.filter(i => i !== index)
        : [...prev, index]
    );
  };

  return (
    <section id="faq" className={isStandalone ? "py-16 bg-white" : "py-20 bg-gradient-to-b from-white to-gray-25"}>
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* メインページでのみヘッダーを表示 */}
        {!isStandalone && (
          <>
            {/* セクションヘッダー */}
            <div className="text-center space-y-4 mb-16">
              <Badge variant="outline" className="bg-accent-info text-white border-accent-info px-4 py-2 text-sm font-medium">
                FAQ
              </Badge>
              <h2 className="text-3xl sm:text-4xl font-bold text-gray-900">
                よくあるご質問
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                保護者の皆様から寄せられるよくあるご質問にお答えします。
                その他のご質問は、サポートページからお気軽にお問い合わせください。
              </p>
            </div>
          </>
        )}

        {/* サポートページでのシンプルなヘッダー */}
        {isStandalone && (
          <div className="text-center mb-12">
            <h2 className="text-3xl font-semibold text-gray-900 mb-4">
              よくあるご質問
            </h2>
            <p className="text-gray-600 max-w-2xl mx-auto">
              アプリについてよくお寄せいただくご質問と回答をまとめました。
            </p>
          </div>
        )}

        {/* FAQ項目 */}
        <div className={`max-w-4xl mx-auto space-y-4 ${!isStandalone ? 'mb-16' : ''}`}>
          {FAQ_ITEMS.map((item, index) => (
            <FAQItem
              key={index}
              question={item.question}
              answer={item.answer}
              index={index}
              isOpen={openItems.includes(index)}
              onToggle={() => toggleItem(index)}
            />
          ))}
        </div>

        {/* メインページでのみ追加情報を表示 */}
        {!isStandalone && (
          <div className="max-w-4xl mx-auto">
            <Card className="bg-gradient-to-r from-primary-50 to-cool-50 border-2 border-primary-100 rounded-2xl">
              <CardContent className="p-8 text-center">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  その他のサポート
                </h3>
                <p className="text-gray-700 mb-6 leading-relaxed">
                  上記以外のご質問やサポートが必要な場合は、
                  App Storeのレビュー機能を通してお気軽にお問い合わせください。
                  皆様からのフィードバックをお待ちしております。
                </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <Button 
                    size="lg"
                    className="bg-primary-600 hover:bg-primary-700 text-white font-semibold px-8 py-3 rounded-full shadow-lg hover:shadow-xl transition-all duration-200"
                    disabled
                  >
                    � App Store（リリース後利用可能）
                  </Button>
                  <Button 
                    size="lg"
                    variant="outline"
                    className="border-primary-600 text-primary-600 hover:bg-primary-600 hover:text-white font-semibold px-8 py-3 rounded-full transition-all duration-200"
                    onClick={() => window.open('/privacy', '_blank')}
                  >
                    📄 プライバシーポリシーを見る
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </section>
  );
}
