-- Mise cloud snapshots. Run once in Supabase SQL Editor.
create table if not exists public.mise_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  version bigint not null default 1,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.mise_snapshot_history (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  version bigint not null,
  data jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists mise_snapshot_history_user_created
  on public.mise_snapshot_history (user_id, created_at desc);

alter table public.mise_snapshots enable row level security;
alter table public.mise_snapshot_history enable row level security;

drop policy if exists "owners read current mise snapshot" on public.mise_snapshots;
create policy "owners read current mise snapshot" on public.mise_snapshots
  for select using (auth.uid() = user_id);
drop policy if exists "owners create current mise snapshot" on public.mise_snapshots;
create policy "owners create current mise snapshot" on public.mise_snapshots
  for insert with check (auth.uid() = user_id);
drop policy if exists "owners update current mise snapshot" on public.mise_snapshots;
create policy "owners update current mise snapshot" on public.mise_snapshots
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "owners read mise history" on public.mise_snapshot_history;
create policy "owners read mise history" on public.mise_snapshot_history
  for select using (auth.uid() = user_id);

create or replace function public.archive_mise_snapshot()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.mise_snapshot_history (user_id, version, data, created_at)
  values (new.user_id, new.version, new.data, new.updated_at);
  return new;
end;
$$;

drop trigger if exists archive_mise_snapshot_after_write on public.mise_snapshots;
create trigger archive_mise_snapshot_after_write
after insert or update on public.mise_snapshots
for each row execute function public.archive_mise_snapshot();

revoke all on public.mise_snapshots from anon;
revoke all on public.mise_snapshot_history from anon;
grant select, insert, update on public.mise_snapshots to authenticated;
grant select on public.mise_snapshot_history to authenticated;

