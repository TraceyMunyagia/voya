-- Has the user finished onboarding? Drives the router guard.
alter table public.profiles
  add column onboarding_completed boolean not null default false;

-- Keep these in sync with UsernameRules.reserved in the app.
alter table public.profiles
  add constraint profiles_username_not_reserved
  check (
    username is null
    or username <> all (array[
      'admin', 'administrator', 'voya', 'support', 'help', 'staff', 'moderator',
      'team', 'official', 'api', 'null', 'undefined', 'root', 'system'
    ])
  );

alter table public.profiles
  add constraint profiles_display_name_length
  check (display_name is null or char_length(display_name) <= 50);

alter table public.profiles
  add constraint profiles_bio_length
  check (char_length(bio) <= 280);

-- Clients may only change these columns on their own profile. Counters
-- (followers_count etc.) can no longer be edited from the app.
revoke update on public.profiles from authenticated;
grant update (username, display_name, photo_url, bio, city, onboarding_completed)
  on public.profiles to authenticated;