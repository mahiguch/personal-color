import Link from 'next/link';
import { ChevronRight, Home } from 'lucide-react';
import { Container } from '@/components/ui/Container';

export interface BreadcrumbItem {
  label: string;
  href?: string;
}

export interface BreadcrumbProps {
  items: BreadcrumbItem[];
  showHome?: boolean;
}

export function Breadcrumb({ items, showHome = true }: BreadcrumbProps) {
  return (
    <nav
      className="bg-gray-50 border-b border-gray-200 py-3"
      aria-label="パンくず"
    >
      <Container>
        <ol className="flex items-center space-x-2 text-sm">
          {showHome && (
            <>
              <li>
                <Link
                  href="/"
                  className="flex items-center text-gray-500 hover:text-gray-700 transition-colors"
                >
                  <Home size={16} />
                  <span className="ml-1 hidden sm:inline">ホーム</span>
                </Link>
              </li>
              {items.length > 0 && (
                <li>
                  <ChevronRight size={16} className="text-gray-400" />
                </li>
              )}
            </>
          )}

          {items.map((item, index) => (
            <li key={index} className="flex items-center">
              {index > 0 && (
                <ChevronRight size={16} className="text-gray-400 mr-2" />
              )}

              {item.href && index < items.length - 1 ? (
                <Link
                  href={item.href}
                  className="text-gray-500 hover:text-gray-700 transition-colors"
                >
                  {item.label}
                </Link>
              ) : (
                <span
                  className="text-gray-900 font-medium"
                  aria-current={index === items.length - 1 ? 'page' : undefined}
                >
                  {item.label}
                </span>
              )}
            </li>
          ))}
        </ol>
      </Container>
    </nav>
  );
}
