-- ============ Enums ============
create type public.trip_status   as enum ('draft', 'review', 'published', 'revision');
create type public.trip_type     as enum ('solo', 'couple', 'friends', 'family', 'group', 'business', 'other');
create type public.item_category as enum ('accommodation', 'transport', 'meal', 'activity', 'other');
create type public.cost_basis    as enum ('per_person', 'per_night', 'per_group', 'per_vehicle', 'one_time', 'free');
create type public.member_role   as enum ('owner', 'co_creator');

-- ============ Helpers ============
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ============ Profiles ============
create table public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  username         text unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name     text,
  photo_url        text,
  bio              text not null default '',
  city             text not null default '',
  followers_count  int not null default 0,
  following_count  int not null default 0,
  trips_count      int not null default 0,
  created_at       timestamptz not null default now()
);

-- Every new auth user gets a profile row (username is claimed in Week 2)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ Trips ============
create table public.trips (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references public.profiles (id) on delete cascade,
  title            text not null check (char_length(title) between 1 and 120),
  description      text not null default '',
  destinations     text[] not null default '{}',
  start_date       date,
  end_date         date,
  travellers       int not null default 1 check (travellers >= 1),
  type             public.trip_type not null default 'solo',
  status           public.trip_status not null default 'draft',
  cover_photo_url  text,
  currency         text not null default 'KES',
  total_cost       numeric(12, 2) not null default 0,
  cost_per_person  numeric(12, 2) not null default 0,
  origin_trip_id   uuid references public.trips (id) on delete set null,  -- "Make This Trip Mine"
  like_count       int not null default 0,
  comment_count    int not null default 0,
  save_count       int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (end_date is null or start_date is null or end_date >= start_date)
);
create index trips_owner_idx  on public.trips (owner_id);
create index trips_status_idx on public.trips (status, created_at desc);

create trigger trips_updated
  before update on public.trips
  for each row execute function public.set_updated_at();

create or replace function public.prevent_owner_change()
returns trigger
language plpgsql
as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'owner_id cannot be changed';
  end if;
  return new;
end;
$$;

create trigger trips_owner_locked
  before update of owner_id on public.trips
  for each row execute function public.prevent_owner_change();

-- ============ Trip members (owner + co-creators + approvals) ============
create table public.trip_members (
  trip_id    uuid not null references public.trips (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       public.member_role not null default 'co_creator',
  approved   boolean not null default false,
  joined_at  timestamptz not null default now(),
  primary key (trip_id, user_id)
);
create index trip_members_user_idx on public.trip_members (user_id);

-- The creator is automatically the first member (owner)
create or replace function public.add_owner_as_member()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.trip_members (trip_id, user_id, role)
  values (new.id, new.owner_id, 'owner');
  return new;
end;
$$;

create trigger trips_add_owner
  after insert on public.trips
  for each row execute function public.add_owner_as_member();

-- ============ Days (no clock times) ============
create table public.trip_days (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips (id) on delete cascade,
  day_number  int not null check (day_number >= 1),
  title       text not null default '',
  story       text not null default '',
  photo_urls  text[] not null default '{}',
  unique (trip_id, day_number),
  unique (id, trip_id)
);

-- ============ Itinerary items ============
create table public.itinerary_items (
  id             uuid primary key default gen_random_uuid(),
  trip_id        uuid not null,
  day_id         uuid not null,
  category       public.item_category not null,
  title          text not null,
  description    text not null default '',
  cost_amount    numeric(12, 2) not null default 0 check (cost_amount >= 0),
  cost_currency  text not null default 'KES',
  cost_basis     public.cost_basis not null default 'one_time',
  location       jsonb,                                -- {name, latitude, longitude, place_id, address, maps_url}
  links          jsonb not null default '[]'::jsonb,   -- [{label, url}]
  photo_urls     text[] not null default '{}',
  notes          text not null default '',
  rating         smallint check (rating between 1 and 5),
  sort_order     int not null default 0,
  details        jsonb not null default '{}'::jsonb,   -- category-specific fields
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- the day must belong to the same trip
  foreign key (day_id, trip_id) references public.trip_days (id, trip_id) on delete cascade
);
create index itinerary_items_day_idx  on public.itinerary_items (day_id, sort_order);
create index itinerary_items_trip_idx on public.itinerary_items (trip_id);

create trigger itinerary_items_updated
  before update on public.itinerary_items
  for each row execute function public.set_updated_at();

-- ============ Activity feed (append-only) ============
create table public.trip_activity (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips (id) on delete cascade,
  actor_id    uuid not null references public.profiles (id) on delete cascade,
  type        text not null,
  target_id   uuid,
  summary     text not null,
  created_at  timestamptz not null default now()
);
create index trip_activity_trip_idx on public.trip_activity (trip_id, created_at desc);

-- ============ Realtime (used from Week 16) ============
alter publication supabase_realtime add table
  public.trips, public.trip_days, public.itinerary_items, public.trip_activity;