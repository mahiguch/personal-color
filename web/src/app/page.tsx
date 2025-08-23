import { HeroSection } from '@/components/sections/HeroSection';
import { FeaturesSection } from '@/components/sections/FeaturesSection';
import { Layout } from '@/components/layout';

export default function Home() {
  return (
    <Layout>
      <HeroSection />
      <FeaturesSection />
    </Layout>
  );
}
