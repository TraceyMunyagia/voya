# Voya Postgres data model (v1)

```
auth.users                       (managed by Supabase Auth)
  └─ profiles                    id = auth.users.id, username (unique, nullable), display_name,
                                 photo_url, bio, city, followers_count, following_count, trips_count

trips                            owner_id, title, description, destinations[], start_date, end_date,
                                 travellers, type, status (draft|review|published|revision),
                                 cover_photo_url, currency, total_cost, cost_per_person,
                                 origin_trip_id (Make This Trip Mine), like/comment/save counts
  ├─ trip_members                (trip_id, user_id) role owner|co_creator, approved
  ├─ trip_days                   day_number, title, story, photo_urls[]
  │    └─ itinerary_items        category, title, description, cost_amount/currency/basis,
  │                              location jsonb, links jsonb, photo_urls[], notes, rating,
  │                              sort_order, details jsonb
  └─ trip_activity               actor_id, type, target_id, summary   (append-only)

Later weeks: likes, comments (W9) · follows (W10) · saves, collections (W10) · notifications (W11+)
             trip_invites (W15) · trip_revisions (W20)

Storage buckets: avatars/{user_id}/...   trip-photos/{trip_id}/...
```

## Decisions
- Co-creators and approvals are rows in `trip_members` (not arrays), so the approval flow is a simple query.
- One `itinerary_items` table for all four categories; category-specific fields live in `details`.
- `itinerary_items (day_id, trip_id)` is a composite foreign key, so an item cannot point at another trip's day.
- Clients never set `status = 'published'`; a Postgres function does after all members approve (Week 18).
- `total_cost` / `cost_per_person` are denormalised for feed cards and recomputed server-side from Week 8.
- No clock times on items; `sort_order` gives free arrangement within a day.
- A profile row is created for every new auth user by a trigger; the username is claimed in Week 2.
- Known gap: members can currently write counter columns on their own trips. Week 9 moves counters to triggers.