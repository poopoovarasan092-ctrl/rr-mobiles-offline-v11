-- RR Mobiles V8: shop operating expense tracking.
-- Run this once in Supabase > SQL Editor > New query.
-- Does not modify existing customers, bills, products, repairs or purchases.

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  expense_date date not null default current_date,
  category text not null default 'Other',
  description text,
  amount numeric(12,2) not null check (amount > 0),
  payment_mode text not null default 'Cash',
  created_at timestamptz not null default now()
);

alter table public.expenses enable row level security;

drop policy if exists "owner full access" on public.expenses;
create policy "owner full access" on public.expenses
  for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

grant select, insert, update, delete on public.expenses to authenticated;
