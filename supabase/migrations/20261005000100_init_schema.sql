create type public.trip_status as enum ('draft', 'review', 'published', 'revision');
create type public.trip_type as enum ('solo', 'couple', 'friends', 'family', 'group', 'business', 'other');
create type public.item_category as enum ('accommodation', 'transport', 'meal', 'activity', 'other');
create type public.cost_basis as enum ('perPerson', 'perNight', 'perGroup', 'perVehicle', 'oneTime', 'free');
create type public.member_role as enum ('owner', 'coCreator');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default '',
  photo_url text,
  bio text not null default '',
  city text not null default '',
  followers_count integer not null default 0,
  following_count integer not null default 0,
  trips_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.trips (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users(id),
  member_ids uuid[] not null default '{}',
  title text not null,
  description text not null default '',
  destinations text[] not null default '{}',
  start_date date,
  end_date date,
  travellers integer not null default 1 check (travellers > 0),
  type public.trip_type not null default 'solo',
  status public.trip_status not null default 'draft',
  cover_photo_url text,
  currency text not null default 'KES',
  total_cost numeric not null default 0,
  cost_per_person numeric not null default 0,
  approvals jsonb not null default '{}',
  origin_trip_id uuid references public.trips(id),
  like_count integer not null default 0,
  comment_count integer not null default 0,
  save_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.trip_members (
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role public.member_role not null default 'coCreator',
  approved boolean not null default false,
  primary key (trip_id, user_id)
);

create table public.trip_days (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  day_number integer not null check (day_number > 0),
  title text not null default '',
  story text not null default '',
  photo_urls text[] not null default '{}',
  unique (trip_id, day_number)
);

create table public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  day_id uuid not null references public.trip_days(id) on delete cascade,
  category public.item_category not null,
  title text not null,
  description text not null default '',
  cost jsonb not null default '{}',
  location jsonb,
  links jsonb not null default '[]',
  photo_urls text[] not null default '{}',
  notes text not null default '',
  rating integer check (rating between 1 and 5),
  item_order integer not null default 0,
  details jsonb not null default '{}'
);

create table public.activity (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.users(id),
  type text not null,
  target_id uuid,
  summary text not null default '',
  created_at timestamptz not null default now()
);
