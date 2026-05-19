-- Add user_id to locations (nullable for backwards-compat with existing rows)
alter table locations
  add column user_id uuid references auth.users(id) on delete cascade;

-- ── locations ────────────────────────────────────────────────────────────────
drop policy if exists "authenticated can read locations"   on locations;
drop policy if exists "authenticated can insert locations" on locations;
drop policy if exists "authenticated can delete locations" on locations;

create policy "users can select own locations"
  on locations for select to authenticated
  using (user_id = auth.uid());

create policy "users can insert own locations"
  on locations for insert to authenticated
  with check (user_id = auth.uid());

create policy "users can update own locations"
  on locations for update to authenticated
  using (user_id = auth.uid());

create policy "users can delete own locations"
  on locations for delete to authenticated
  using (user_id = auth.uid());

-- ── sensors ──────────────────────────────────────────────────────────────────
drop policy if exists "authenticated can read sensors"   on sensors;
drop policy if exists "authenticated can insert sensors" on sensors;
drop policy if exists "authenticated can delete sensors" on sensors;

create policy "users can select own sensors"
  on sensors for select to authenticated
  using (
    location_id in (
      select id from locations where user_id = auth.uid()
    )
  );

create policy "users can insert own sensors"
  on sensors for insert to authenticated
  with check (
    location_id in (
      select id from locations where user_id = auth.uid()
    )
  );

create policy "users can delete own sensors"
  on sensors for delete to authenticated
  using (
    location_id in (
      select id from locations where user_id = auth.uid()
    )
  );

-- ── telemetry ────────────────────────────────────────────────────────────────
-- INSERT is performed by the .NET backend (service_role, bypasses RLS)
drop policy if exists "authenticated can read telemetry" on telemetry;

create policy "users can select own telemetry"
  on telemetry for select to authenticated
  using (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );

-- ── thresholds ───────────────────────────────────────────────────────────────
drop policy if exists "authenticated can select thresholds" on thresholds;
drop policy if exists "authenticated can insert thresholds" on thresholds;
drop policy if exists "authenticated can update thresholds" on thresholds;

create policy "users can select own thresholds"
  on thresholds for select to authenticated
  using (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );

create policy "users can insert own thresholds"
  on thresholds for insert to authenticated
  with check (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );

create policy "users can update own thresholds"
  on thresholds for update to authenticated
  using (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );

-- ── events ───────────────────────────────────────────────────────────────────
drop policy if exists "authenticated can select events" on events;
drop policy if exists "authenticated can insert events" on events;

create policy "users can select own events"
  on events for select to authenticated
  using (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );

create policy "users can insert own events"
  on events for insert to authenticated
  with check (
    sensor_id in (
      select s.id from sensors s
      join locations l on l.id = s.location_id
      where l.user_id = auth.uid()
    )
  );
