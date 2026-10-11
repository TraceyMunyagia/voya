 -- ============ Length guards (the app enforces shorter limits) ============
alter table public.trips
  add constraint trips_description_length check (char_length(description) <= 5000),
  add constraint trips_destinations_count check (cardinality(destinations) <= 10);

alter table public.trip_days
  add constraint trip_days_title_length check (char_length(title) <= 80),
  add constraint trip_days_story_length check (char_length(story) <= 5000);

alter table public.itinerary_items
  add constraint itinerary_items_title_length check (char_length(title) between 1 and 120);

-- ============ Permission check shared by the functions below ============
create or replace function public.assert_trip_editable(p_trip_id uuid)
returns void
language plpgsql stable
as $$
begin
  if p_trip_id is null
     or not public.is_trip_member(p_trip_id)
     or not public.is_trip_editable(p_trip_id) then
    raise exception 'You cannot edit this trip' using errcode = '42501';
  end if;
end;
$$;

-- ============ Days ============
-- Appends the next day number.
create or replace function public.add_day(p_trip_id uuid)
returns public.trip_days
language plpgsql
as $$
declare
  n int;
  d public.trip_days;
begin
  perform public.assert_trip_editable(p_trip_id);

  select coalesce(max(day_number), 0) + 1 into n
  from public.trip_days where trip_id = p_trip_id;

  if n > 60 then
    raise exception 'A trip can have at most 60 days';
  end if;

  insert into public.trip_days (trip_id, day_number)
  values (p_trip_id, n)
  returning * into d;
  return d;
end;
$$;

-- Makes sure days 1..p_days exist. Never removes anything.
create or replace function public.sync_trip_days(p_trip_id uuid, p_days int)
returns void
language plpgsql
as $$
begin
  perform public.assert_trip_editable(p_trip_id);
  if p_days < 1 or p_days > 60 then
    raise exception 'A trip can have between 1 and 60 days';
  end if;

  insert into public.trip_days (trip_id, day_number)
  select p_trip_id, g from generate_series(1, p_days) as g
  on conflict (trip_id, day_number) do nothing;
end;
$$;

-- Renumbers the trip's days to follow p_ids (a permutation of ALL its day ids).
create or replace function public.reorder_days(p_trip_id uuid, p_ids uuid[])
returns void
language plpgsql
as $$
begin
  perform public.assert_trip_editable(p_trip_id);

  if coalesce(array_length(p_ids, 1), 0) <>
     (select count(*) from public.trip_days where trip_id = p_trip_id)
     or exists (
       select 1 from unnest(p_ids) as i
       where not exists (
         select 1 from public.trip_days d where d.id = i and d.trip_id = p_trip_id
       )
     ) then
    raise exception 'The list does not match this trip''s days';
  end if;

  -- two steps so the unique (trip_id, day_number) is never violated mid-way
  update public.trip_days set day_number = day_number + 100000 where trip_id = p_trip_id;
  update public.trip_days d
  set day_number = o.n
  from unnest(p_ids) with ordinality as o(id, n)
  where d.id = o.id and d.trip_id = p_trip_id;
end;
$$;

-- Deletes a day (its items go with it) and closes the gap in the numbering.
create or replace function public.delete_day(p_day_id uuid)
returns void
language plpgsql
as $$
declare
  v_trip uuid;
begin
  select trip_id into v_trip from public.trip_days where id = p_day_id;
  perform public.assert_trip_editable(v_trip);

  delete from public.trip_days where id = p_day_id;

  update public.trip_days set day_number = day_number + 100000 where trip_id = v_trip;
  update public.trip_days d
  set day_number = r.n
  from (
    select id, row_number() over (order by day_number) as n
    from public.trip_days where trip_id = v_trip
  ) r
  where d.id = r.id;
end;
$$;

-- ============ Items ============
-- Sets sort_order for the items of one day to follow p_ids.
create or replace function public.reorder_items(p_day_id uuid, p_ids uuid[])
returns void
language plpgsql
as $$
declare
  v_trip uuid;
begin
  select trip_id into v_trip from public.trip_days where id = p_day_id;
  perform public.assert_trip_editable(v_trip);

  update public.itinerary_items i
  set sort_order = o.n
  from unnest(p_ids) with ordinality as o(id, n)
  where i.id = o.id and i.day_id = p_day_id;
end;
$$;

-- ============ Who may call them ============
revoke execute on function
  public.assert_trip_editable(uuid),
  public.add_day(uuid),
  public.sync_trip_days(uuid, int),
  public.reorder_days(uuid, uuid[]),
  public.delete_day(uuid),
  public.reorder_items(uuid, uuid[])
from public, anon;

grant execute on function
  public.assert_trip_editable(uuid),
  public.add_day(uuid),
  public.sync_trip_days(uuid, int),
  public.reorder_days(uuid, uuid[]),
  public.delete_day(uuid),
  public.reorder_items(uuid, uuid[])
to authenticated;