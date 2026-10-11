-- items must be referenceable by (id, trip_id) from item_photos
alter table public.itinerary_items
  add constraint itinerary_items_id_trip_key unique (id, trip_id);

-- photos move to their own table (with captions)
alter table public.itinerary_items drop column photo_urls;

alter table public.itinerary_items
  add constraint itinerary_items_notes_length check (char_length(notes) <= 2000),
  add constraint itinerary_items_description_length check (char_length(description) <= 2000),
  add constraint itinerary_items_links_count check (jsonb_array_length(links) <= 5);

-- ============ Item photos ============
create table public.item_photos (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null,
  item_id     uuid not null,
  url         text not null,
  caption     text not null default '' check (char_length(caption) <= 200),
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  foreign key (item_id, trip_id) references public.itinerary_items (id, trip_id) on delete cascade
);
create index item_photos_item_idx on public.item_photos (item_id, sort_order);

alter table public.item_photos enable row level security;

create policy "read photos of published or own trips" on public.item_photos
  for select to authenticated
  using (public.is_trip_published(trip_id) or public.is_trip_member(trip_id));

create policy "members add photos while editable" on public.item_photos
  for insert to authenticated
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members edit photos while editable" on public.item_photos
  for update to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id))
  with check (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

create policy "members delete photos while editable" on public.item_photos
  for delete to authenticated
  using (public.is_trip_member(trip_id) and public.is_trip_editable(trip_id));

alter publication supabase_realtime add table public.item_photos;

-- ============ Save an item with its photos in one transaction ============
-- p_item_id null  = create (appended to the end of the day)
-- p_item_id given = update; p_fields replaces every editable field and
--                   p_photos replaces the item's photos.
create or replace function public.save_item(
  p_trip_id  uuid,
  p_day_id   uuid,
  p_item_id  uuid,
  p_fields   jsonb,
  p_photos   jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_id uuid := p_item_id;
begin
  perform public.assert_trip_editable(p_trip_id);

  if jsonb_array_length(coalesce(p_photos, '[]'::jsonb)) > 10 then
    raise exception 'An item can have at most 10 photos';
  end if;

  if v_id is null then
    insert into public.itinerary_items (
      trip_id, day_id, category, title, description,
      cost_amount, cost_currency, cost_basis,
      location, links, notes, rating, details, sort_order
    )
    values (
      p_trip_id, p_day_id,
      (p_fields ->> 'category')::public.item_category,
      p_fields ->> 'title',
      coalesce(p_fields ->> 'description', ''),
      coalesce((p_fields ->> 'cost_amount')::numeric, 0),
      coalesce(p_fields ->> 'cost_currency', 'KES'),
      coalesce((p_fields ->> 'cost_basis')::public.cost_basis, 'one_time'),
      nullif(p_fields -> 'location', 'null'::jsonb),
      coalesce(nullif(p_fields -> 'links', 'null'::jsonb), '[]'::jsonb),
      coalesce(p_fields ->> 'notes', ''),
      (p_fields ->> 'rating')::smallint,
      coalesce(nullif(p_fields -> 'details', 'null'::jsonb), '{}'::jsonb),
      (select count(*) from public.itinerary_items where day_id = p_day_id)
    )
    returning id into v_id;
  else
    update public.itinerary_items set
      category      = (p_fields ->> 'category')::public.item_category,
      title         = p_fields ->> 'title',
      description   = coalesce(p_fields ->> 'description', ''),
      cost_amount   = coalesce((p_fields ->> 'cost_amount')::numeric, 0),
      cost_currency = coalesce(p_fields ->> 'cost_currency', 'KES'),
      cost_basis    = coalesce((p_fields ->> 'cost_basis')::public.cost_basis, 'one_time'),
      location      = nullif(p_fields -> 'location', 'null'::jsonb),
      links         = coalesce(nullif(p_fields -> 'links', 'null'::jsonb), '[]'::jsonb),
      notes         = coalesce(p_fields ->> 'notes', ''),
      rating        = (p_fields ->> 'rating')::smallint,
      details       = coalesce(nullif(p_fields -> 'details', 'null'::jsonb), '{}'::jsonb)
    where id = v_id and trip_id = p_trip_id;

    if not found then
      raise exception 'That item could not be found' using errcode = '42501';
    end if;
  end if;

  delete from public.item_photos where item_id = v_id;
  insert into public.item_photos (trip_id, item_id, url, caption, sort_order)
  select p_trip_id, v_id, e ->> 'url', coalesce(e ->> 'caption', ''), (o.n - 1)::int
  from jsonb_array_elements(coalesce(p_photos, '[]'::jsonb)) with ordinality as o(e, n);

  return v_id;
end;
$$;

revoke execute on function public.save_item(uuid, uuid, uuid, jsonb, jsonb) from public, anon;
grant execute on function public.save_item(uuid, uuid, uuid, jsonb, jsonb) to authenticated;