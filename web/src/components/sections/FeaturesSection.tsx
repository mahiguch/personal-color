import { Container, Card } from '@/components/ui';
import { featuresData } from '@/lib/features-data';

export function FeaturesSection() {
  return (
    <section id="features" className="py-16 lg:py-24 bg-white">
      <Container>
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-6">
            3ステップで
            <span className="bg-gradient-to-r from-orange-500 to-pink-500 bg-clip-text text-transparent">
              簡単診断
            </span>
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            最新のAI技術を使って、あなたに似合うパーソナルカラーを数秒で診断。
            専門知識がなくても、誰でも簡単に利用できます。
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {featuresData.map((feature, index) => (
            <Card
              key={feature.id}
              variant="elevated"
              className="text-center group hover:shadow-xl transition-shadow duration-300"
            >
              {/* Step number */}
              <div className="inline-flex items-center justify-center w-12 h-12 bg-gradient-to-r from-orange-500 to-pink-500 text-white rounded-full font-bold text-lg mb-6">
                {index + 1}
              </div>

              {/* Icon */}
              <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-300">
                {feature.icon}
              </div>

              {/* Title */}
              <h3 className="text-xl font-bold text-gray-900 mb-4">
                {feature.title}
              </h3>

              {/* Description */}
              <p className="text-gray-600 mb-6 leading-relaxed">
                {feature.description}
              </p>

              {/* Details */}
              <div className="space-y-2">
                {feature.details.map((detail, detailIndex) => (
                  <div
                    key={detailIndex}
                    className="flex items-start text-sm text-gray-700"
                  >
                    <span className="inline-block w-2 h-2 bg-orange-400 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                    <span>{detail}</span>
                  </div>
                ))}
              </div>
            </Card>
          ))}
        </div>

        {/* Bottom highlight */}
        <div className="mt-16 text-center">
          <div className="bg-gradient-to-r from-orange-50 to-pink-50 rounded-2xl p-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              🔒 プライバシーと安全性を最優先
            </h3>
            <p className="text-gray-700 max-w-2xl mx-auto">
              撮影した写真は診断後に即座に削除され、個人情報は一切保存されません。
              小学生でも安心して使える、教育的で安全なアプリです。
            </p>
          </div>
        </div>
      </Container>
    </section>
  );
}
