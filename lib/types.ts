export type Mod = {
  id: string; owner_id: string; name: string; description: string; category: string; version: string;
  author: string; tags: string[]; icon_url: string | null; banner_url: string | null;
  screenshot_urls: string[]; file_url: string; file_path: string; icon_path: string | null;
  banner_path: string | null; screenshot_paths: string[]; download_count: number;
  featured: boolean; trending: boolean; created_at: string; updated_at: string;
};
export const CATEGORIES = ['Furniture','Utility','Visual','Mobs','Weapons','World Generation','Technology'];
export const formatCount = (n: number) => Intl.NumberFormat(undefined, { notation: n > 9999 ? 'compact' : 'standard' }).format(n || 0);
