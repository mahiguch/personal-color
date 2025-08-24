import { Container, Card } from '@/components/ui';
import { featuresData } from '@/lib/features-data';

export function FeaturesSection() {
  return (
    <section id="features" className="py-20 lg:py-32 bg-gray-50">
      <Container>
        <div className="text-center mb-20">
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900 mb-6 tracking-tighter">
            <span className="text-primary-400">3ステップ</span>で簡単診断
          </h2>
          <p className="text-lg text-gray-500 max-w-2xl mx-auto tracking-tight">
            最新のAI技術を使って、あなたに似合うパーソナルカラーを数秒で診断。
            専門知識がなくても、誰でも簡単に利用できます。
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 lg:gap-12">
          {featuresData.map((feature, index) => (
            <div
              key={feature.id}
              className="bg-white rounded-2xl p-8 text-center group hover:shadow-soft transition-all duration-300"
            >
              {/* Step number */}
              <div className="inline-flex items-center justify-center w-10 h-10 bg-primary-100 text-primary-600 rounded-full font-semibold text-sm mb-6">
                {index + 1}
              </div>

              {/* Icon */}
              <div className="text-5xl mb-6 opacity-90 group-hover:opacity-100 transition-opacity duration-300">
                {feature.icon}
              </div>

              {/* Title */}
              <h3 className="text-xl font-semibold text-gray-900 mb-4 tracking-tight">
                {feature.title}
              </h3>

              {/* Description */}
              <p className="text-gray-500 mb-6 leading-relaxed tracking-tight">
                {feature.description}
              </p>

              {/* Details */}
              <div className="space-y-3">
                {feature.details.map((detail, detailIndex) => (
                  <div
                    key={detailIndex}
                    className="flex items-center text-sm text-gray-400 justify-center"
                  >
                    <span className="w-1 h-1 bg-primary-400 rounded-full mr-3 flex-shrink-0"></span>
                    <span className="tracking-tight">{detail}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Bottom highlight */}
        <div className="mt-20 text-center">
          <div className="bg-white rounded-3xl p-12 shadow-soft">
            <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <span className="text-2xl">🔒</span>
            </div>
            <h3 className="text-2xl font-bold text-gray-900 mb-4 tracking-tight">
              プライバシーと安全性を最優先
            </h3>
            <p className="text-gray-500 max-w-2xl mx-auto tracking-tight">
              撮影した写真は診断後に即座に削除され、個人情報は一切保存されません。
              小学生でも安心して使える、教育的で安全なアプリです。
            </p>
          </div>
        </div>
      </Container>
    </section>
  );
}
