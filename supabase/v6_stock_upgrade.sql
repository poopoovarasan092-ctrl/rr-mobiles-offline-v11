-- RR Mobiles V6 upgrade: exact product-linked stock movement.
-- Run once in Supabase SQL Editor while signed in as project owner.

alter table public.purchases
  add column if not exists product_id uuid references public.products(id) on delete set null;

create or replace function public.create_rr_bill_v4(
  p_bill_no text, p_bill_date date, p_customer_id uuid,
  p_customer_name text, p_customer_phone text, p_items jsonb,
  p_total numeric, p_cost_total numeric, p_payment_mode text
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  new_id uuid;
  item jsonb;
  earned integer;
  wanted_qty integer;
  changed_rows integer;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one bill item';
  end if;

  earned := floor(greatest(coalesce(p_total,0),0)/100)::integer;

  -- Validate and deduct tracked products first. Any failure rolls back the entire bill.
  for item in select value from jsonb_array_elements(p_items)
  loop
    if item ? 'product_id' and nullif(item->>'product_id','') is not null then
      wanted_qty := (item->>'qty')::integer;
      if wanted_qty <= 0 then raise exception 'Quantity must be greater than zero'; end if;

      update public.products
        set stock = stock - wanted_qty
        where id = (item->>'product_id')::uuid
          and owner_id = auth.uid()
          and stock >= wanted_qty;

      get diagnostics changed_rows = row_count;
      if changed_rows = 0 then
        raise exception 'Insufficient stock or product not found: %', coalesce(item->>'name','product');
      end if;
    end if;
  end loop;

  insert into public.bills(
    owner_id,bill_no,bill_date,customer_id,customer_name,customer_phone,
    items,total,cost_total,payment_mode,points_earned
  )
  values(
    auth.uid(),p_bill_no,p_bill_date,p_customer_id,p_customer_name,p_customer_phone,
    p_items,p_total,p_cost_total,p_payment_mode,earned
  ) returning id into new_id;

  if p_customer_id is not null and earned > 0 then
    update public.customers set points_balance = points_balance + earned
      where id = p_customer_id and owner_id = auth.uid();
    insert into public.loyalty_transactions(owner_id,customer_id,bill_id,points,description)
      values(auth.uid(),p_customer_id,new_id,earned,'Earned from bill '||p_bill_no);
  end if;

  return new_id;
end;
$$;

create or replace function public.create_rr_stock_purchase_v6(
  p_product_id uuid,
  p_supplier text,
  p_quantity integer,
  p_unit_cost numeric,
  p_purchase_date date
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  product_row public.products%rowtype;
  purchase_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Quantity must be greater than zero'; end if;
  if p_unit_cost is null or p_unit_cost < 0 then raise exception 'Unit cost cannot be negative'; end if;

  update public.products
    set stock = stock + p_quantity,
        purchase_price = p_unit_cost
    where id = p_product_id and owner_id = auth.uid()
    returning * into product_row;

  if not found then raise exception 'Product not found'; end if;

  insert into public.purchases(
    owner_id,product_id,product_name,supplier,quantity,unit_cost,total,purchase_date
  )
  values(
    auth.uid(),product_row.id,product_row.name,p_supplier,p_quantity,
    p_unit_cost,p_quantity*p_unit_cost,coalesce(p_purchase_date,current_date)
  ) returning id into purchase_id;

  return purchase_id;
end;
$$;

grant execute on function public.create_rr_bill_v4(text,date,uuid,text,text,jsonb,numeric,numeric,text) to authenticated;
grant execute on function public.create_rr_stock_purchase_v6(uuid,text,integer,numeric,date) to authenticated;
