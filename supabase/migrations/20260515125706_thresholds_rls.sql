alter table thresholds enable row level security;

alter table thresholds
  add constraint thresholds_sensor_id_key unique (sensor_id);

create policy "authenticated can select thresholds"
  on thresholds for select to authenticated using (true);

create policy "authenticated can insert thresholds"
  on thresholds for insert to authenticated with check (true);

create policy "authenticated can update thresholds"
  on thresholds for update to authenticated using (true);
