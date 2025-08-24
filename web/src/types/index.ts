export interface Review {
  name: string;
  age: string;
  type: '保護者' | '小学生';
  avatar: string;
  rating: number;
  comment: string;
}

export interface Feature {
  icon: string;
  title: string;
  description: string;
}

export interface FAQItem {
  question: string;
  answer: string;
}

export interface SiteConfig {
  name: string;
  title: string;
  description: string;
  url: string;
  ogImage: string;
}

export interface NavigationItem {
  title: string;
  href: string;
}
