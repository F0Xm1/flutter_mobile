create policy "authenticated can insert locations"
  on locations for insert to authenticated with check (true);

create policy "authenticated can delete locations"
  on locations for delete to authenticated using (true);

create policy "authenticated can insert sensors"
  on sensors for insert to authenticated with check (true);

create policy "authenticated can delete sensors"
  on sensors for delete to authenticated using (true);
