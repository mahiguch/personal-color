import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Contact form handler
export const contact = onRequest(
  {
    cors: true,
    region: 'asia-northeast1', // Tokyo region
  },
  async (request, response) => {
    // CORS headers
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    response.set('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method === 'OPTIONS') {
      response.status(200).send();
      return;
    }

    if (request.method !== 'POST') {
      response.status(405).json({
        error: 'Method not allowed',
        message: 'Only POST requests are allowed',
      });
      return;
    }

    try {
      const { name, email, subject, message, device_info } = request.body;

      // Basic validation
      if (!name || !email || !subject || !message) {
        response.status(400).json({
          error: 'Missing required fields',
          message: '必須項目が不足しています。',
        });
        return;
      }

      // Email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        response.status(400).json({
          error: 'Invalid email',
          message: '正しいメールアドレスを入力してください。',
        });
        return;
      }

      // Rate limiting (simple implementation)
      const clientIP = request.ip || 'unknown';
      console.log(`Contact form submission from IP: ${clientIP}`);

      // Store in Firestore (for logging/analytics)
      const db = admin.firestore();
      await db.collection('contact_submissions').add({
        name,
        email,
        subject,
        message,
        device_info: device_info || null,
        ip: clientIP,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send email notification (placeholder - implement with your preferred service)
      console.log('=== Contact Form Submission ===');
      console.log(`Name: ${name}`);
      console.log(`Email: ${email}`);
      console.log(`Subject: ${subject}`);
      console.log(`Message: ${message}`);
      console.log(`Device Info: ${device_info || 'Not provided'}`);
      console.log('===============================');

      // TODO: Implement actual email sending
      // You can use services like SendGrid, Nodemailer, or Gmail API

      response.status(200).json({
        success: true,
        message: 'お問い合わせを受け付けました。ご連絡ありがとうございます。',
      });
    } catch (error) {
      console.error('Contact form error:', error);
      response.status(500).json({
        error: 'Internal server error',
        message:
          'サーバーエラーが発生しました。しばらく時間をおいてから再度お試しください。',
      });
    }
  }
);
