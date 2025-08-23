'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Send, CheckCircle, AlertCircle } from 'lucide-react';
import { Card, Input, Textarea, Select, Button } from '@/components/ui';

// バリデーションスキーマ
const contactFormSchema = z.object({
  name: z
    .string()
    .min(1, '名前は必須です')
    .max(50, '名前は50文字以内で入力してください'),
  email: z
    .string()
    .min(1, 'メールアドレスは必須です')
    .email('正しいメールアドレスを入力してください'),
  subject: z.string().min(1, 'お問い合わせの種類を選択してください'),
  message: z
    .string()
    .min(10, 'お問い合わせ内容は10文字以上で入力してください')
    .max(2000, 'お問い合わせ内容は2000文字以内で入力してください'),
  device_info: z
    .string()
    .max(200, 'デバイス情報は200文字以内で入力してください')
    .optional()
    .or(z.literal('')),
});

type ContactFormData = z.infer<typeof contactFormSchema>;

export function ContactForm() {
  const [submitStatus, setSubmitStatus] = useState<
    'idle' | 'submitting' | 'success' | 'error'
  >('idle');

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ContactFormData>({
    resolver: zodResolver(contactFormSchema),
  });

  const onSubmit = async (data: ContactFormData) => {
    setSubmitStatus('submitting');

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'フォームの送信に失敗しました');
      }

      const result = await response.json();
      console.log('Form submission success:', result);

      setSubmitStatus('success');
      reset();

      // 3秒後にステータスをリセット
      setTimeout(() => {
        setSubmitStatus('idle');
      }, 3000);
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitStatus('error');

      // 5秒後にステータスをリセット
      setTimeout(() => {
        setSubmitStatus('idle');
      }, 5000);
    }
  };

  const subjectOptions = [
    { value: 'usage', label: 'アプリの使用方法について' },
    { value: 'bug', label: '不具合・エラーについて' },
    { value: 'privacy', label: 'プライバシーについて' },
    { value: 'feature', label: '機能改善の提案' },
    { value: 'other', label: 'その他' },
  ];

  return (
    <section id="contact-form" className="space-y-6">
      <div className="text-center">
        <h2 className="text-2xl lg:text-3xl font-bold text-gray-900 mb-4">
          お問い合わせ
        </h2>
        <p className="text-gray-600">
          アプリについてご不明な点やご要望がございましたら、お気軽にお問い合わせください。
        </p>
      </div>

      <Card className="p-6 max-w-2xl mx-auto">
        {submitStatus === 'success' ? (
          <div className="text-center py-8">
            <CheckCircle className="mx-auto mb-4 text-green-500" size={48} />
            <h3 className="text-xl font-semibold text-green-900 mb-2">
              送信完了
            </h3>
            <p className="text-green-800 mb-4">
              お問い合わせありがとうございます。
              いただいた内容を確認し、平日10:00-18:00の間にご回答いたします。
            </p>
            <p className="text-sm text-green-700">
              ※ 返信には数日お時間をいただく場合がございます
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* 名前 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                お名前 <span className="text-red-500">*</span>
              </label>
              <Input
                {...register('name')}
                placeholder="山田 太郎"
                error={!!errors.name}
              />
              {errors.name && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.name.message}
                </p>
              )}
            </div>

            {/* メールアドレス */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                メールアドレス <span className="text-red-500">*</span>
              </label>
              <Input
                {...register('email')}
                type="email"
                placeholder="example@email.com"
                error={!!errors.email}
              />
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.email.message}
                </p>
              )}
            </div>

            {/* お問い合わせの種類 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                お問い合わせの種類 <span className="text-red-500">*</span>
              </label>
              <Select
                {...register('subject')}
                placeholder="選択してください"
                error={!!errors.subject}
              >
                {subjectOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </Select>
              {errors.subject && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.subject.message}
                </p>
              )}
            </div>

            {/* お問い合わせ内容 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                お問い合わせ内容 <span className="text-red-500">*</span>
              </label>
              <Textarea
                {...register('message')}
                placeholder="詳しい状況やご質問内容をお聞かせください&#13;&#10;&#13;&#10;例：&#13;&#10;- アプリを起動すると「エラー」と表示される&#13;&#10;- 診断結果が表示されない&#13;&#10;- 特定の機能について詳しく知りたい"
                rows={6}
                error={!!errors.message}
              />
              {errors.message && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.message.message}
                </p>
              )}
            </div>

            {/* デバイス情報（任意） */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                デバイス情報（任意）
              </label>
              <Input
                {...register('device_info')}
                placeholder="例：iPhone 14, iOS 17.0"
                error={!!errors.device_info}
              />
              <p className="mt-1 text-sm text-gray-500">
                技術的な問題の場合、デバイス情報をお教えいただくと解決が早くなります
              </p>
              {errors.device_info && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.device_info.message}
                </p>
              )}
            </div>

            {/* エラーメッセージ */}
            {submitStatus === 'error' && (
              <div className="flex items-center p-4 bg-red-50 border border-red-200 rounded-lg">
                <AlertCircle
                  className="text-red-500 mr-3 flex-shrink-0"
                  size={20}
                />
                <p className="text-red-800 text-sm">
                  送信中にエラーが発生しました。しばらく時間をおいて再度お試しください。
                  問題が続く場合は、メールで直接ご連絡ください。
                </p>
              </div>
            )}

            {/* 送信ボタン */}
            <div className="pt-4">
              <Button
                type="submit"
                size="lg"
                className="w-full"
                loading={submitStatus === 'submitting'}
                disabled={submitStatus === 'submitting'}
                icon={<Send size={20} />}
              >
                {submitStatus === 'submitting' ? '送信中...' : '送信する'}
              </Button>
            </div>

            {/* 注意事項 */}
            <div className="text-xs text-gray-500 space-y-1">
              <p>
                ※ いただいた個人情報は、お問い合わせへの回答目的のみに使用し、
                第三者に提供することはありません。
              </p>
              <p>
                ※ 営業日（平日10:00-18:00）にご回答いたします。
                お急ぎでない場合は、まずはFAQをご確認ください。
              </p>
            </div>
          </form>
        )}
      </Card>
    </section>
  );
}
