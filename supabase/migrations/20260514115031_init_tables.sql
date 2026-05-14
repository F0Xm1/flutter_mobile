-- Приміщення
create table locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  created_at timestamptz default now()
);

-- Сенсори
create table sensors (
  id uuid primary key default gen_random_uuid(),
  location_id uuid references locations(id) on delete cascade,
  name text not null,
  type text not null, -- 'temperature' | 'humidity' | 'pressure'
  unit text not null, -- '°C' | '%' | 'hPa'
  created_at timestamptz default now()
);

-- Телеметрія
create table telemetry (
  id bigint generated always as identity primary key,
  sensor_id uuid references sensors(id) on delete cascade,
  value numeric not null,
  recorded_at timestamptz default now()
);

-- Пороги алертів
create table thresholds (
  id uuid primary key default gen_random_uuid(),
  sensor_id uuid references sensors(id) on delete cascade,
  min_value numeric,
  max_value numeric
);

-- Індекс для швидкого читання телеметрії
create index telemetry_sensor_time_idx
  on telemetry(sensor_id, recorded_at desc);