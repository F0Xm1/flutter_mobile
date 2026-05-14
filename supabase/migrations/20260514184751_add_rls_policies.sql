-- Enable RLS on all tables
alter table locations  enable row level security;
alter table sensors    enable row level security;
alter table telemetry  enable row level security;
alter table thresholds enable row level security;

-- Authenticated users can read everything (read-only from mobile)
create policy "authenticated can read locations"
  on locations for select to authenticated using (true);

create policy "authenticated can read sensors"
  on sensors for select to authenticated using (true);

create policy "authenticated can read telemetry"
  on telemetry for select to authenticated using (true);

create policy "authenticated can read thresholds"
  on thresholds for select to authenticated using (true);
