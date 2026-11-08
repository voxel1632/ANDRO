# VOXEL — Explore The Mod Galaxy

A Next.js and Supabase-powered Minecraft Bedrock mod catalog with real Supabase Auth, creator publishing, Storage uploads, search, downloads, moderation and RLS.

## Setup

1. Create a Supabase project (or use the configured one) and set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.local` using `.env.example`.
2. In the Supabase SQL Editor, run `supabase/schema.sql`. It creates/updates the profile and mod schema, RLS policies, the public `mods` storage bucket, and RPCs. Existing mod records need valid `owner_id`, `file_path`, and `file_url` values to be fully manageable; backfill those before making the legacy rows editable.
3. Enable email/password authentication in Supabase Auth. Configure the site's URL and password reset redirect URL in Supabase Auth URL configuration.
4. Install and start: `npm install && npm run dev` (production: `npm run build && npm start`).
5. Create an account on `/login`. To grant admin privileges, run the final commented SQL statement in the SQL editor with that account's email. Admin status is a database role protected by RLS; there is no hard-coded admin password.

## Features

- Persistent Supabase email/password sessions, signup and reset-email flow.
- Direct Storage uploads for `.mcpack`, `.mcaddon`, `.zip`, icon, banner and multiple screenshots; UI validation, upload progress and rollback of newly uploaded assets if database save fails.
- Public mod catalog/search and category selection; mod detail pages with screenshots and actual public Storage download URLs.
- Creator-only listing/editing/deletion, admin-wide mod management, feature/trending controls and creator disabling.
- Download count incremented atomically by a database RPC.

## Security and operations

The browser only uses the publishable key; row-level security and bucket policies enforce ownership. Admin accounts must be created with Supabase Auth and explicitly granted the `admin` role through SQL. The requested `voxeladmin` password is not embedded in source: client-side passwords are public and cannot provide secure admin authorization. Creator removal disables platform access but does not delete the Supabase Auth identity. The bucket is public because the catalog needs public image URLs and downloads; do not upload private files. Review any pre-existing `mods` table policies and reconcile legacy columns before deploying the migration. Configure Supabase Auth email delivery, database backups, rate limits, and production domain settings before launch.
