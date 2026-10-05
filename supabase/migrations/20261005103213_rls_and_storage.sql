-- ============ Helper functions ============
-- security definer so the policies can look at trips / trip_members
-- without triggering the policies on those same tables.
create or replace function public.is_trip_member(p_trip_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.trip_members m
    where m.trip_id = p_trip_id and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_trip_owner(p_trip_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.trips t
    where t.id = p_trip_id and t.owner_id = auth.uid()
  );
$$;

create or replace function public.is_trip_published(p_trip_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.trips t
    where t.id = p_trip_id and t.status = 'published'
  );
$$;

create or replace function public.is_trip_editable(p_trip_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.trips t
    where t.id = p_trip_id and t.status in ('draft', 'revision')
  );
$$;

-- ============ Turn RLS on ============
alter table public.profiles         enable row level security;
alter table public.trips            enable row level security;
alter table public.trip_members     enable row level security;
alter table public.trip_days        enable row level security;
alter table public.itinerary_items  enable row level security;
alter table public.trip_activity    enable row level security;

-- ============ profiles ============
-- (rows are created by the on_auth_user_created trigger, so no insert policy)
create policy "profiles are readable by signed-in users" on public.profiles
  for select to authenticated using (true);

create policy "users update their own profile" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ============ trips ============
-- owner_id is included in the select policy so INSERT ... RETURNING works
-- (the owner's trip_members row is only added by an AFTER trigger).
create policy "read published or own trips" on public.trips
  for select to authenticated
  using (status = 'published' or owner_id = auth.uid() or public.is_trip_member(id));

create policy "create own draft trips" on public.trips
  for insert to authenticated
  with check (owner_id = auth.uid() and status = 'draft');

-- Members edit while draft / review / revision. Clients can never move a trip to
-- 'published'; a security-definer function does that in Week 18.
create policy "members edit unpublished trips" on public.trips
  for update to authenticated
  using (public.is_trip_member(id) and status in ('draft', 'review', 'revision'))
  with check (status in ('draft', 'review', 'revision'));

create policy "owner deletes own drafts" on public.trips
  for delete to authenticated
  using (owner_id = auth.uid() and status = 'draft');

-- ============ trip_members ============
create policy "see members of your trips and published trips" on public.trip_members
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_trip_member(trip_id)
    or public.is_trip_published(trip_id)
  );

create policy "owner adds members" on public.trip_members
  for insert to authenticated
  with check (public.is_trip_owner(trip_id));

create policy "members update their own row" on public.trip_members
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "owner removes members, members can leave" on public.trip_members
  for delete to authenticated
  using (public.is_trip_owner(trip_id) or user_id = auth.uid());

-- ============ trip_days ============
create policy "read days of published or own trips" on public.trip_days
  for select to authenticated
  using (public.is_trip_published(trip_id) or public.is_trip_member(trip_id));

create policy "members add days while editable" on public.trip_days
  for insert to authenticated
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members edit days while editable" on public.trip_days
  for update to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id))
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members delete days while editable" on public.trip_days
  for delete to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

-- ============ itinerary_items ============
create policy "read items of published or own trips" on public.itinerary_items
  for select to authenticated
  using (public.is_trip_published(trip_id) or public.is_trip_member(trip_id));

create policy "members add items while editable" on public.itinerary_items
  for insert to authenticated
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members edit items while editable" on public.itinerary_items
  for update to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id))
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members delete items while editable" on public.itinerary_items
  for delete to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

-- ============ trip_activity (append-only: no update / delete policies) ============
create policy "members read activity" on public.trip_activity
  for select to authenticated
  using (public.is_trip_member(trip_id));

create policy "members log their own activity" on public.trip_activity
  for insert to authenticated
  with check (public.is_trip_member(trip_id) and actor_id = auth.uid());

-- ============ Storage ============
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',     'avatars',     true, 5242880,  array['image/jpeg', 'image/png', 'image/webp']),
  ('trip-photos', 'trip-photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- avatars/{user_id}/...  : each user manages their own folder
create policy "users manage their own avatar folder" on storage.objects
  for all to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- trip-photos/{trip_id}/... : trip members manage photos (public read via the bucket)
create policy "trip members upload photos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'trip-photos'
    and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  );

create policy "trip members update photos" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'trip-photos'
    and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  );

create policy "trip members delete photos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'trip-photos'
    and public.is_trip_member(((storage.foldername(name))[1])::uuid)
  );