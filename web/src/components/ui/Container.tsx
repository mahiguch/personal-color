import { HTMLAttributes, ReactNode } from 'react';
import { cn } from '@/lib/utils';

export interface ContainerProps extends HTMLAttributes<HTMLDivElement> {
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  children: ReactNode;
}

export function Container({
  className,
  size = 'lg',
  children,
  ...props
}: ContainerProps) {
  const baseStyles = 'mx-auto px-4 sm:px-6 lg:px-8';

  const sizes = {
    sm: 'max-w-2xl', // 672px
    md: 'max-w-4xl', // 896px
    lg: 'max-w-6xl', // 1152px
    xl: 'max-w-7xl', // 1280px
    full: 'max-w-none', // No max width
  };

  return (
    <div className={cn(baseStyles, sizes[size], className)} {...props}>
      {children}
    </div>
  );
}
