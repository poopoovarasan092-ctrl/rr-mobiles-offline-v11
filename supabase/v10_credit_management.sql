-- RR Mobiles V10: customer credit and partial-payment tracking.
-- Run once in Supabase > SQL Editor > New query.

create table if not exists public.credit_payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  bill_id uuid not null references public.bills(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  payment_date date not null default current_date,
  amount numeric(12,2) not null check (amount > 0),
  payment_mode text not null default 'Cash',
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists credit_payments_owner_bill_idx
  on public.credit_payments(owner_id,bill_id);
create index if not exists credit_payments_owner_date_idx
  on public.credit_payments(owner_id,payment_date desc);

alter table public.credit_payments enable row level security;
drop policy if exists "owner full access" on public.credit_payments;
create policy "owner full access" on public.credit_payments
  for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

grant select, insert, update, delete on public.credit_payments to authenticated;

create or replace function public.record_rr_credit_payment_v10(
  p_bill_id uuid,
  p_amount numeric,
  p_payment_date date,
  p_payment_mode text,
  p_notes text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  bill_row public.bills%rowtype;
  already_paid numeric(12,2);
  payment_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Payment must be greater than zero'; end if;

  select * into bill_row
    from public.bills
    where id = p_bill_id and owner_id = auth.uid()
    for update;

  if not found then raise exception 'Bill not found'; end if;
  if lower(coalesce(bill_row.payment_mode,'')) <> 'credit' then
    raise exception 'Only bills marked Credit can receive credit payments';
  end if;

  select coalesce(sum(amount),0) into already_paid
    from public.credit_payments
    where bill_id = p_bill_id and owner_id = auth.uid();

  if already_paid + p_amount > bill_row.total then
    raise exception 'Payment exceeds outstanding balance of %', bill_row.total - already_paid;
  end if;

  insert into public.credit_payments(
    owner_id,bill_id,customer_id,payment_date,amount,payment_mode,notes
  ) values (
    auth.uid(),p_bill_id,bill_row.customer_id,coalesce(p_payment_date,current_date),
    p_amount,coalesce(nullif(p_payment_mode,''),'Cash'),p_notes
  ) returning id into payment_id;

  return payment_id;
end;
$$;

grant execute on function public.record_rr_credit_payment_v10(uuid,numeric,date,text,text) to authenticated;
