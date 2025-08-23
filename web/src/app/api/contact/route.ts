import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

// バリデーションスキーマ（フォームコンポーネントと同じ）
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

const subjectLabels: Record<string, string> = {
  usage: 'アプリの使用方法について',
  bug: '不具合・エラーについて',
  privacy: 'プライバシーについて',
  feature: '機能改善の提案',
  other: 'その他',
};

// スパム対策のためのシンプルなレート制限
const rateLimitMap = new Map<string, { count: number; lastReset: number }>();
const RATE_LIMIT_MAX = 5; // 5回まで
const RATE_LIMIT_WINDOW = 60 * 60 * 1000; // 1時間

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const userLimit = rateLimitMap.get(ip);

  if (!userLimit) {
    rateLimitMap.set(ip, { count: 1, lastReset: now });
    return true;
  }

  // ウィンドウをリセット
  if (now - userLimit.lastReset > RATE_LIMIT_WINDOW) {
    userLimit.count = 1;
    userLimit.lastReset = now;
    return true;
  }

  // 制限チェック
  if (userLimit.count >= RATE_LIMIT_MAX) {
    return false;
  }

  userLimit.count++;
  return true;
}

async function sendEmail(data: {
  name: string;
  email: string;
  subject: string;
  message: string;
  device_info?: string;
}) {
  // 実際のメール送信実装
  // ここでは console.log でログ出力（本番では実際のメール送信サービスを使用）

  const emailContent = `
【パーソナルカラー診断アプリ お問い合わせ】

お名前: ${data.name}
メールアドレス: ${data.email}
お問い合わせの種類: ${subjectLabels[data.subject] || data.subject}
デバイス情報: ${data.device_info || '未記入'}

お問い合わせ内容:
${data.message}

---
送信日時: ${new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })}
  `.trim();

  console.log('=== お問い合わせメール ===');
  console.log(emailContent);
  console.log('========================');

  // TODO: 実際のメール送信実装
  // 例: SendGrid, Resend, Nodemailer等を使用
  /*
  const response = await fetch('https://api.sendgrid.v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{
        to: [{ email: process.env.CONTACT_EMAIL }],
        subject: `[パーソナルカラー診断アプリ] ${subjectLabels[data.subject] || data.subject}`,
      }],
      from: { email: 'noreply@your-domain.com', name: 'パーソナルカラー診断アプリ' },
      content: [{
        type: 'text/plain',
        value: emailContent,
      }],
      reply_to: { email: data.email, name: data.name },
    }),
  });
  */

  return true;
}

export async function POST(request: NextRequest) {
  try {
    // IPアドレスを取得（レート制限用）
    const forwarded = request.headers.get('x-forwarded-for');
    const ip = forwarded?.split(',')[0] || 'unknown';

    // レート制限チェック
    if (!checkRateLimit(ip)) {
      return NextResponse.json(
        {
          error: 'Too many requests',
          message:
            '送信回数が制限を超えています。しばらく時間をおいてから再度お試しください。',
        },
        { status: 429 }
      );
    }

    // リクエストボディを取得
    const body = await request.json();

    // バリデーション
    const validationResult = contactFormSchema.safeParse(body);
    if (!validationResult.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          message: '入力内容に誤りがあります。',
          details: validationResult.error.issues,
        },
        { status: 400 }
      );
    }

    const { name, email, subject, message, device_info } =
      validationResult.data;

    // シンプルなスパム検出
    const spamKeywords = ['spam', 'advertisement', '広告', '宣伝'];
    const textToCheck = `${name} ${message}`.toLowerCase();
    const isSpam = spamKeywords.some((keyword) =>
      textToCheck.includes(keyword)
    );

    if (isSpam) {
      // スパムの場合は成功レスポンスを返すが実際には送信しない
      console.log('Spam detected:', {
        name,
        email,
        message: message.substring(0, 100),
      });
      return NextResponse.json({ success: true });
    }

    // メール送信
    await sendEmail({
      name,
      email,
      subject,
      message,
      device_info,
    });

    // 成功レスポンス
    return NextResponse.json({
      success: true,
      message: 'お問い合わせを受け付けました。ご連絡ありがとうございます。',
    });
  } catch (error) {
    console.error('Contact form submission error:', error);

    return NextResponse.json(
      {
        error: 'Internal server error',
        message:
          'サーバーエラーが発生しました。しばらく時間をおいてから再度お試しください。',
      },
      { status: 500 }
    );
  }
}

// OPTIONS メソッド（CORS対応）
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      Allow: 'POST, OPTIONS',
    },
  });
}
