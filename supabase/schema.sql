-- RR Mobiles V4 database. Run the complete file once in Supabase > SQL Editor > New query.
-- GST-free billing: this schema intentionally has no GST/tax columns.
create extension if not exists pgcrypto;

create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 name text not null, phone text, whatsapp text, address text, notes text,
 points_balance integer not null default 0 check(points_balance >= 0), created_at timestamptz not null default now()
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 name text not null, sku text, stock integer not null default 0 check(stock >= 0), purchase_price numeric(12,2) not null default 0,
 selling_price numeric(12,2) not null default 0, low_stock_at integer not null default 2, created_at timestamptz not null default now()
);
create table if not exists public.bills (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 bill_no text not null, bill_date date not null default current_date, customer_id uuid references public.customers(id) on delete set null,
 customer_name text, customer_phone text, items jsonb not null default '[]'::jsonb, total numeric(12,2) not null default 0,
 cost_total numeric(12,2) not null default 0, payment_mode text not null default 'Cash', points_earned integer not null default 0,
 created_at timestamptz not null default now(), unique(owner_id,bill_no)
);
create table if not exists public.repairs (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 repair_no text not null, customer_name text not null, customer_phone text, device text not null, issue text not null,
 estimated_cost numeric(12,2) not null default 0, status text not null default 'Received', received_date date not null default current_date,
 created_at timestamptz not null default now()
);
create table if not exists public.purchases (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 supplier text, product_name text not null, quantity integer not null check(quantity > 0), unit_cost numeric(12,2) not null default 0,
 total numeric(12,2) not null default 0, purchase_date date not null default current_date, created_at timestamptz not null default now()
);
create table if not exists public.loyalty_transactions (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade, bill_id uuid references public.bills(id) on delete set null,
 points integer not null, description text, created_at timestamptz not null default now()
);

alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.bills enable row level security;
alter table public.repairs enable row level security;
alter table public.purchases enable row level security;
alter table public.loyalty_transactions enable row level security;

do $$ declare t text; begin
 foreach t in array array['customers','products','bills','repairs','purchases','loyalty_transactions'] loop
  execute format('drop policy if exists "owner full access" on public.%I',t);
  execute format('create policy "owner full access" on public.%I for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid())',t);
 end loop;
end $$;

-- Atomic bill creation: inserts bill, adjusts stock, awards 1 point per ₹100 (₹1 redemption value).
create or replace function public.create_rr_bill_v4(p_bill_no text,p_bill_date date,p_customer_id uuid,p_customer_name text,p_customer_phone text,p_items jsonb,p_total numeric,p_cost_total numeric,p_payment_mode text)
returns uuid language plpgsql security invoker set search_path=public as $$
declare new_id uuid; item jsonb; earned integer;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 earned := floor(coalesce(p_total,0)/100)::integer;
 insert into public.bills(owner_id,bill_no,bill_date,customer_id,customer_name,customer_phone,items,total,cost_total,payment_mode,points_earned)
 values(auth.uid(),p_bill_no,p_bill_date,p_customer_id,p_customer_name,p_customer_phone,p_items,p_total,p_cost_total,p_payment_mode,earned) returning id into new_id;
 for item in select * from jsonb_array_elements(p_items) loop
  update public.products set stock=greatest(0,stock-(item->>'qty')::integer)
   where owner_id=auth.uid() and lower(name)=lower(item->>'name');
 end loop;
 if p_customer_id is not null and earned>0 then
  update public.customers set points_balance=points_balance+earned where id=p_customer_id and owner_id=auth.uid();
  insert into public.loyalty_transactions(owner_id,customer_id,bill_id,points,description)
  values(auth.uid(),p_customer_id,new_id,earned,'Earned from bill '||p_bill_no);
 end if;
 return new_id;
end $$;
