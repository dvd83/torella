-- Torella · schéma Supabase (projet « torella », région Zurich eu-central-2)
-- Données du cabinet : un enregistrement JSON par objet (patient, facture, rendez-vous, remède, dépense, réglages)
create table public.records (
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null check (kind in ('patients','appts','invoices','depenses','remedies','customSym','cabinet')),
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (owner, kind, id)
);
alter table public.records enable row level security;
create policy "records_select_own" on public.records for select to authenticated using (owner = (select auth.uid()));
create policy "records_insert_own" on public.records for insert to authenticated with check (owner = (select auth.uid()));
create policy "records_update_own" on public.records for update to authenticated using (owner = (select auth.uid())) with check (owner = (select auth.uid()));
create policy "records_delete_own" on public.records for delete to authenticated using (owner = (select auth.uid()));

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;
create trigger records_touch before update on public.records for each row execute function public.touch_updated_at();

-- Administratrice : le premier compte créé gère le catalogue Tarif 590
create table public.app_admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
alter table public.app_admins enable row level security;
create policy "admins_select_self" on public.app_admins for select to authenticated using (user_id = (select auth.uid()));

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create or replace function public.first_user_is_admin() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.app_admins) then
    insert into public.app_admins(user_id) values (new.id);
  end if;
  return new;
end $$;
revoke execute on function public.first_user_is_admin() from public, anon, authenticated;
create trigger on_auth_user_created_admin after insert on auth.users for each row execute function public.first_user_is_admin();

-- Catalogue Tarif 590 : 'current' (en vigueur) et 'pending' (proposé par la vérification annuelle)
create table public.tarif590 (
  id text primary key check (id in ('current','pending')),
  data jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.tarif590 enable row level security;
create policy "tarif_read" on public.tarif590 for select to authenticated using (true);
create policy "tarif_admin_insert" on public.tarif590 for insert to authenticated with check ((select public.is_admin()));
create policy "tarif_admin_update" on public.tarif590 for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "tarif_admin_delete" on public.tarif590 for delete to authenticated using ((select public.is_admin()));
create trigger tarif_touch before update on public.tarif590 for each row execute function public.touch_updated_at();
