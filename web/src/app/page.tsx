import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { HeroSection } from '@/components/sections/HeroSection';
import { FeaturesSection } from '@/components/sections/FeaturesSection';
import { ReviewsSection } from '@/components/sections/ReviewsSection';
import { LaunchSection } from '@/components/sections/LaunchSection';

export default function Home() {
  return (
    <div className="min-h-screen bg-white">
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
