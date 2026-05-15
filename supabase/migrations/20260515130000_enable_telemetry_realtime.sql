do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'telemetry'
  ) then
    alter publication supabase_realtime add table telemetry;
  end if;
end;
$$;
