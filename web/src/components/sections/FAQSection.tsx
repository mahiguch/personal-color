'use client';

import { useState } from 'react';
import { ChevronDown, ChevronUp, Search } from 'lucide-react';
import { Card, Input, Badge } from '@/components/ui';
import { faqData, faqCategories } from '@/lib/faq-data';

export function FAQSection() {
  const [expandedItems, setExpandedItems] = useState<Set<string>>(new Set());
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');

  // FAQ項目の絞り込み
  const filteredFAQs = faqData.filter((faq) => {
    const matchesCategory =
      selectedCategory === 'all' || faq.category === selectedCategory;
    const matchesSearch =
      searchTerm === '' ||
      faq.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
      faq.answer.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesCategory && matchesSearch;
  });

  const toggleExpanded = (id: string) => {
    const newExpanded = new Set(expandedItems);
    if (newExpanded.has(id)) {
      newExpanded.delete(id);
    } else {
      newExpanded.add(id);
    }
    setExpandedItems(newExpanded);
  };

  const categories = [
    { id: 'all', label: 'すべて' },
    ...Object.entries(faqCategories).map(([id, label]) => ({ id, label })),
  ];

  return (
    <section className="space-y-8">
      <div className="text-center">
        <h2 className="text-2xl lg:text-3xl font-bold text-gray-900 mb-4">
          よくある質問
        </h2>
        <p className="text-gray-600">
          アプリの使用方法やトラブルシューティングについて、よくお寄せいただく質問をまとめました。
        </p>
      </div>

      {/* 検索とフィルター */}
      <div className="space-y-4">
        {/* 検索バー */}
        <div className="relative">
          <Search
            className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
            size={20}
          />
          <Input
            type="text"
            placeholder="質問を検索..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>

        {/* カテゴリフィルター */}
        <div className="flex flex-wrap gap-2">
          {categories.map((category) => (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                selectedCategory === category.id
                  ? 'bg-orange-100 text-orange-800 border border-orange-200'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {category.label}
            </button>
          ))}
        </div>
      </div>

      {/* FAQ項目 */}
      <div className="space-y-4">
        {filteredFAQs.length === 0 ? (
          <Card className="p-6 text-center">
            <p className="text-gray-500">
              該当する質問が見つかりませんでした。
            </p>
          </Card>
        ) : (
          filteredFAQs.map((faq) => (
            <Card key={faq.id} className="overflow-hidden">
              <button
                onClick={() => toggleExpanded(faq.id)}
                className="w-full p-6 text-left flex items-center justify-between hover:bg-gray-50 transition-colors"
              >
                <div className="flex-1 pr-4">
                  <div className="flex items-center gap-3 mb-2">
                    <Badge variant="info" size="sm">
                      {faqCategories[faq.category]}
                    </Badge>
                  </div>
                  <h3 className="font-semibold text-gray-900 text-lg">
                    {faq.question}
                  </h3>
                </div>
                <div className="flex-shrink-0">
                  {expandedItems.has(faq.id) ? (
                    <ChevronUp className="text-gray-400" size={24} />
                  ) : (
                    <ChevronDown className="text-gray-400" size={24} />
                  )}
                </div>
              </button>

              {expandedItems.has(faq.id) && (
                <div className="px-6 pb-6 border-t border-gray-100">
                  <div className="pt-4">
                    <p className="text-gray-700 leading-relaxed whitespace-pre-line">
                      {faq.answer}
                    </p>
                  </div>
                </div>
              )}
            </Card>
          ))
        )}
      </div>

      {/* 他に質問がある場合 */}
      <Card className="p-6 bg-orange-50 border-orange-200 text-center">
        <h3 className="font-semibold text-orange-900 mb-2">
          他にご質問はございますか？
        </h3>
        <p className="text-orange-800 text-sm mb-4">
          上記で解決しない場合は、下記のお問い合わせフォームからご連絡ください。
          平日10:00-18:00にサポートスタッフが対応いたします。
        </p>
        <button
          onClick={() => {
            document.getElementById('contact-form')?.scrollIntoView({
              behavior: 'smooth',
            });
          }}
          className="bg-orange-600 text-white px-6 py-2 rounded-lg hover:bg-orange-700 transition-colors"
        >
          お問い合わせフォームへ
        </button>
      </Card>
    </section>
  );
}
