# Voya Supabase data model (v1)

```
users (id = auth.users.id)
  username, displayName, photoUrl, bio, city,
  followersCount, followingCount, tripsCount
  saves/{tripId}          savedAt, collectionIds[]
  collections/{id}        name, tripIds[]

trips (id)
  ownerId, memberIds[]            <- owner + co-creators (queries + rules)
  title, description, destinations[], startDate, endDate
  travellers, type, status        <- draft | review | published | revision
  coverPhotoUrl, currency, totalCost, costPerPerson
  approvals { uid: bool }, originTripId (Make This Trip Mine)
  likeCount, commentCount, saveCount, createdAt, updatedAt

  days (trip_id, id)      dayNumber, title, story, photoUrls[]
    items (day_id, id)    category, title, description, cost{amount,currency,basis},
                          location{name,lat,lng,placeId,address,mapsUrl},
                          links[{label,url}], photoUrls[], notes, rating, order,
                          details{ category-specific fields }

  activity/{id}           actorId, type, targetId, summary, createdAt   (append-only)
  likes/{uid}  comments/{id}                                             (Week 9)
  follows: users/{uid}/following/{uid2}                                   (Week 10)
```

The canonical SQL lives in `supabase/migrations/`. Dart models use snake_case
keys for rows returned by Postgres; nested values such as cost, location, and
links are stored as JSONB.

## Decisions
- One `items` subcollection for all four categories; category-specific fields live in `details`.
- `member_ids` is denormalised on the trip so RLS checks and array queries stay cheap.
- Clients never set `status = published`; a database function does after all approvals.
- `totalCost` / `costPerPerson` are denormalised for feed cards and recomputed server-side.
- No clock times on items; `order` gives free arrangement within a day.
