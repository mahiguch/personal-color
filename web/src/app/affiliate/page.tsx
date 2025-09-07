'use client';

import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Shield, Eye, Users, Lock, Mail, FileText, AlertTriangle, Check } from 'lucide-react';

export default function PrivacyPage() {
  const lastUpdated = "2025年9月5日";

  return (
    <div className="min-h-screen bg-white">
      <Header />
      <main className="pt-20">
        {/* ヘッダーセクション */}
        <section className="py-12 bg-gradient-to-b from-primary-25 to-white">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto text-center">
              <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-6">
                アフィリエイトプログラム
              </h1>
              <p className="text-lg text-gray-600 mb-4">
                パーソナルカラー診断アプリ
              </p>
              <p className="text-sm text-gray-500">
                最終更新日：{lastUpdated}
              </p>
            </div>
          </div>
        </section>
        <section className='py-16'>
            <div className="container mx-auto px-4 sm:px-6 lg:px-8">
               <div className="max-w-4xl mx-auto"></div>
               <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                   <a href="https://amzn.to/4p9rBP7" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/719zy3mFsuL._AC_SL1301_.jpg" alt="氷結 本搾り チューハイ 350ml 20本" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">【Amazon.co.jp限定】氷結 本搾り チューハイ 350ml 20本</p>
                       </CardContent>
                    </Card>
                  </a>
                   <a href="https://amzn.to/42jWsP1" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/71yxFCLcw0L._AC_SX679_.jpg" alt="LISTERINE(リステリン) クールミント 1000ml 2個" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">LISTERINE(リステリン) クールミント 1000ml 2個</p>
                       </CardContent>
                    </Card>
                  </a>
                   <a href="https://amzn.to/3V5Jkct" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/61LbQqaPxvL._AC_SX679_.jpg" alt="ソフラン プレミアム消臭 【業務用 大容量】" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">ソフラン プレミアム消臭 【業務用 大容量】</p>
                       </CardContent>
                    </Card>
                  </a>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                   <a href="https://amzn.to/4m32afk" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/41yfvH2nrgL._AC_PIbundle-2,TopRight,0,0_SH20_.jpg" alt="パイクプレイスロースト 793g ミディアム レギュラー 粉 2袋セット" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">パイクプレイスロースト 793g ミディアム レギュラー 粉 2袋セット</p>
                       </CardContent>
                    </Card>
                  </a>
                   <a href="https://amzn.to/3K7dqKc" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/61BkIv1HPkL._AC_SX679_.jpg" alt="トップ 【業務用 大容量】 クリアリキッド 4㎏ 洗濯洗剤" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">トップ 【業務用 大容量】 クリアリキッド 4㎏ 洗濯洗剤</p>
                       </CardContent>
                    </Card>
                  </a>
                   <a href="https://amzn.to/4njyRWV" target="_blank" rel="noopener noreferrer" className="inline-block">
                     <Card>
                       <CardContent className="p-6 text-center">
                         <img src="https://m.media-amazon.com/images/I/81VK6guA+cL._AC_SX679_.jpg" alt="ジョイ W除菌 食器用洗剤" className="w-full h-48 object-cover mb-4 rounded-md" />
                         <p className="text-sm text-gray-600">ジョイ W除菌 食器用洗剤</p>
                       </CardContent>
                    </Card>
                  </a>
                </div>
            </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
