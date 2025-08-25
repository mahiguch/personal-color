import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { HeroSection } from '@/components/sections/HeroSection';
import { FeaturesSection } from '@/components/sections/FeaturesSection';
import { ReviewsSection } from '@/components/sections/ReviewsSection';
import { LaunchSection } from '@/components/sections/LaunchSection';
import { mobileAppSchema } from '@/lib/structured-data';
import Script from 'next/script';

export default function Home() {
  return (
    <div className="min-h-screen bg-white">
      <Script
        id="mobile-app-schema"
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(mobileAppSchema),
        }}
      />
      <Header />
      <main>
        <HeroSection />
        <FeaturesSection />
        <ReviewsSection />
        <LaunchSection />
      </main>
      <Footer />
    </div>
  );
}
