create table events (
  id bigint generated always as identity primary key,
  sensor_id uuid references sensors(id) on delete cascade,
  sensor_type text not null,
  value numeric not null,
  threshold_type text not null,
  threshold_value numeric not null,
  triggered_at timestamptz default now()
);

create index events_triggered_at_idx on events(triggered_at desc);

alter table events enable row level security;

create policy "authenticated can select events"
  on events for select to authenticated using (true);

create policy "authenticated can insert events"
  on events for insert to authenticated with check (true);

alter publication supabase_realtime add table events;
