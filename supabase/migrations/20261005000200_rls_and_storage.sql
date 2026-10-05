alter table public.users enable row level security;
alter table public.trips enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_days enable row level security;
alter table public.itinerary_items enable row level security;
alter table public.activity enable row level security;

create policy "published trips are public" on public.trips
  for select using (status = 'published' or auth.uid() = any(member_ids));
create policy "members create trips" on public.trips
  for insert with check (auth.uid() = owner_id);
create policy "members update trips" on public.trips
  for update using (auth.uid() = any(member_ids))
  with check (auth.uid() = any(member_ids));
create policy "users view profiles" on public.users
  for select using (true);
create policy "users manage own profile" on public.users
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "trip members see their memberships" on public.trip_members
  for select using (auth.uid() = user_id or auth.uid() in (
    select owner_id from public.trips where id = trip_id
  ));
create policy "trip content follows trip access" on public.trip_days
  for all using (exists (
    select 1 from public.trips t where t.id = trip_id
      and (t.status = 'published' or auth.uid() = any(t.member_ids))
  ));
create policy "items follow day access" on public.itinerary_items
  for all using (exists (
    select 1 from public.trip_days d join public.trips t on t.id = d.trip_id
      where d.id = day_id and (t.status = 'published' or auth.uid() = any(t.member_ids))
  ));

insert into storage.buckets (id, name, public)
values ('trip-media', 'trip-media', true)
on conflict (id) do nothing;

create policy "public trip media is readable" on storage.objects
  for select using (bucket_id = 'trip-media');
create policy "authenticated users upload trip media" on storage.objects
  for insert to authenticated with check (bucket_id = 'trip-media');
