-- The json columns are free-form, so cap their size. The app writes far less.
alter table public.itinerary_items
  add constraint itinerary_items_details_size
    check (octet_length(details::text) <= 4000),
  add constraint itinerary_items_location_size
    check (location is null or octet_length(location::text) <= 2000),
  add constraint itinerary_items_links_size
    check (octet_length(links::text) <= 4000);