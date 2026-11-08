import type { Metadata } from 'next';
import './globals.css';
import Link from 'next/link';
import { AccountMenu } from '@/components/AccountMenu';
export const metadata: Metadata = { title: 'VOXEL — Explore The Mod Galaxy', description: 'Discover and share Minecraft Bedrock mods.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body><header className="topbar"><Link href="/" className="brand"><span className="brand-mark">V</span> VOXEL</Link><nav><Link href="/">Explore</Link><Link href="/dashboard">Creator Studio</Link></nav><AccountMenu /></header><main>{children}</main><footer>VOXEL · Explore The Mod Galaxy <span>Built for creators across the galaxy.</span></footer></body></html>; }
