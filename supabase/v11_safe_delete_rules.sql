-- RR Mobiles V11: safe customer and stock product deletion.
-- Run once in Supabase SQL Editor after the V6 and V10 migrations.
-- Customer deletion is blocked while any credit bill has an outstanding balance.
-- Product deletion is blocked while stock is not exactly zero.
-- Purchase, bill and loyalty history is retained when a zero-balance customer
-- or zero-stock product is deleted.

-- Preserve loyalty history when a customer is removed.
alter table public.loyalty_transactions
  alter column customer_id drop not null;

alter table public.loyalty_transactions
  drop constraint if exists loyalty_transactions_customer_id_fkey;

alter table public.loyalty_transactions
  add constraint loyalty_transactions_customer_id_fkey
  foreign key (customer_id) references public.customers(id) on delete set null;

create or replace function public.rr_v11_guard_customer_delete()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  outstanding numeric(12,2);
begin
  select coalesce(sum(greatest(b.total - coalesce(p.paid,0),0)),0)
    into outstanding
  from public.bills b
  left join (
    select bill_id, sum(amount) as paid
    from public.credit_payments
    group by bill_id
  ) p on p.bill_id = b.id
  where b.customer_id = old.id
    and lower(coalesce(b.payment_mode,'')) = 'credit';

  if outstanding > 0 then
    raise exception 'Cannot delete customer: outstanding balance is %', outstanding;
  end if;
  return old;
end;
$$;

drop trigger if exists rr_v11_customer_delete_guard on public.customers;
create trigger rr_v11_customer_delete_guard
before delete on public.customers
for each row execute function public.rr_v11_guard_customer_delete();

create or replace function public.rr_v11_guard_product_delete()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if coalesce(old.stock,0) <> 0 then
    raise exception 'Cannot delete stock product: quantity must be exactly zero (current quantity: %)', old.stock;
  end if;
  return old;
end;
$$;

drop trigger if exists rr_v11_product_delete_guard on public.products;
create trigger rr_v11_product_delete_guard
before delete on public.products
for each row execute function public.rr_v11_guard_product_delete();

-- purchases.product_id already uses ON DELETE SET NULL in the V6 migration.
-- This preserves purchase rows and their product_name after product deletion.
