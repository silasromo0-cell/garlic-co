# Garlic & Co: setup

1. **Supabase**: New project → SQL Editor → paste `supabase/schema.sql` (change the admin email first) → Run. Then paste `supabase/seed.sql` → Run.
2. **Admin login**: Authentication → Users → Add user (same email as in schema.sql, tick "Auto confirm").
3. **Keys**: Project Settings → API → copy Project URL + anon key into `config.js`.
4. **Vercel**: push this folder to GitHub → Vercel → Add New Project → Deploy (no build settings needed).
5. Admin is at `yoursite.vercel.app/admin/`

## Moving the pictures to Supabase
Storage → `menu-images` bucket → drag in everything from `images/` (files directly in the bucket, no sub-folder). Then in SQL Editor:
```sql
update menu_items set image_url =
  'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/menu-images/' || replace(image_url,'images/','')
where image_url like 'images/%';
```
New photos uploaded from the admin go to this bucket automatically.
