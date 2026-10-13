-- ============ 1. Accommodation and transport to the destination belong to the trip ============
alter table public.itinerary_items alter column day_id drop not null;

-- trip-level items have no day, so they need their own link to the trip
-- (it makes them disappear with the trip)
alter table public.itinerary_items
  add constraint itinerary_items_trip_fk
  foreign key (trip_id) references public.trips (id) on delete cascade;

-- move what the app saved so far out of the days
update public.itinerary_items
set day_id = null
where category in ('accommodation', 'transport');

update public.itinerary_items i
set sort_order = r.n
from (
  select id, (row_number() over (partition by trip_id, category order by created_at) - 1)::int as n
  from public.itinerary_items
  where day_id is null
) r
where i.id = r.id;

-- accommodation and transport are trip-level; everything else sits in a day
alter table public.itinerary_items
  add constraint itinerary_items_level_check
  check ((category in ('accommodation', 'transport')) = (day_id is null));

-- ============ 2. "How did you get there?" on items in a day ============
alter table public.itinerary_items
  add column travel_mode text
    check (travel_mode in (
      'personal_car', 'rental_car', 'matatu', 'bus', 'train', 'sgr', 'flight',
      'taxi', 'uber_bolt', 'tuk_tuk', 'boda_boda', 'boat_ferry', 'tour_vehicle',
      'walking', 'other'
    )),
  add column travel_cost_amount numeric(12, 2) not null default 0
    check (travel_cost_amount >= 0),
  add column travel_cost_basis public.cost_basis not null default 'per_vehicle',
  add column travel_note text not null default ''
    check (char_length(travel_note) <= 500),
  add constraint itinerary_items_travel_level
    check (travel_mode is null or day_id is not null);

-- ============ 3. save_item: the day is optional, travel fields are saved ============
create or replace function public.save_item(
  p_trip_id  uuid,
  p_day_id   uuid,   -- null for accommodation and transport to the destination
  p_item_id  uuid,
  p_fields   jsonb,
  p_photos   jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_id       uuid := p_item_id;
  v_category public.item_category := (p_fields ->> 'category')::public.item_category;
  v_order    int;
begin
  perform public.assert_trip_editable(p_trip_id);

  if jsonb_array_length(coalesce(p_photos, '[]'::jsonb)) > 10 then
    raise exception 'An item can have at most 10 photos';
  end if;

  if p_day_id is not null
     and not exists (select 1 from public.trip_days where id = p_day_id and trip_id = p_trip_id) then
    raise exception 'That day does not belong to this trip' using errcode = '42501';
  end if;

  if v_id is null then
    -- appended to the end of its day, or of its category at trip level
    select count(*) into v_order
    from public.itinerary_items
    where trip_id = p_trip_id
      and day_id is not distinct from p_day_id
      and (p_day_id is not null or category = v_category);

    insert into public.itinerary_items (
      trip_id, day_id, category, title, description,
      cost_amount, cost_currency, cost_basis,
      location, links, notes, rating, details,
      travel_mode, travel_cost_amount, travel_cost_basis, travel_note,
      sort_order
    )
    values (
      p_trip_id, p_day_id, v_category,
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
      nullif(p_fields ->> 'travel_mode', ''),
      coalesce((p_fields ->> 'travel_cost_amount')::numeric, 0),
      coalesce((p_fields ->> 'travel_cost_basis')::public.cost_basis, 'per_vehicle'),
      coalesce(p_fields ->> 'travel_note', ''),
      v_order
    )
    returning id into v_id;
  else
    update public.itinerary_items set
      category           = v_category,
      title              = p_fields ->> 'title',
      description        = coalesce(p_fields ->> 'description', ''),
      cost_amount        = coalesce((p_fields ->> 'cost_amount')::numeric, 0),
      cost_currency      = coalesce(p_fields ->> 'cost_currency', 'KES'),
      cost_basis         = coalesce((p_fields ->> 'cost_basis')::public.cost_basis, 'one_time'),
      location           = nullif(p_fields -> 'location', 'null'::jsonb),
      links              = coalesce(nullif(p_fields -> 'links', 'null'::jsonb), '[]'::jsonb),
      notes              = coalesce(p_fields ->> 'notes', ''),
      rating             = (p_fields ->> 'rating')::smallint,
      details            = coalesce(nullif(p_fields -> 'details', 'null'::jsonb), '{}'::jsonb),
      travel_mode        = nullif(p_fields ->> 'travel_mode', ''),
      travel_cost_amount = coalesce((p_fields ->> 'travel_cost_amount')::numeric, 0),
      travel_cost_basis  = coalesce((p_fields ->> 'travel_cost_basis')::public.cost_basis, 'per_vehicle'),
      travel_note        = coalesce(p_fields ->> 'travel_note', '')
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