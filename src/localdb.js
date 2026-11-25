// RR Mobiles Offline Edition: IndexedDB-backed Supabase-compatible adapter.
// All records stay on this device. No network requests or cloud sync are performed.
const DB_NAME='rr-mobiles-offline-v10';
const TABLES=['customers','products','bills','repairs','purchases','expenses','credit_payments','loyalty_transactions'];
let dbPromise;
function db(){if(!dbPromise)dbPromise=new Promise((resolve,reject)=>{const r=indexedDB.open(DB_NAME,1);r.onupgradeneeded=()=>{const d=r.result;for(const t of TABLES)if(!d.objectStoreNames.contains(t))d.createObjectStore(t,{keyPath:'id'});};r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});return dbPromise}
const uid=()=>crypto.randomUUID?crypto.randomUUID():`${Date.now()}-${Math.random().toString(16).slice(2)}`;
async function all(table){const d=await db();return new Promise((res,rej)=>{const r=d.transaction(table).objectStore(table).getAll();r.onsuccess=()=>res(r.result||[]);r.onerror=()=>rej(r.error)})}
async function put(table,row){const d=await db();return new Promise((res,rej)=>{const r=d.transaction(table,'readwrite').objectStore(table).put({...row,id:row.id||uid(),created_at:row.created_at||new Date().toISOString()});r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)})}
async function del(table,id){const d=await db();return new Promise((res,rej)=>{const r=d.transaction(table,'readwrite').objectStore(table).delete(id);r.onsuccess=()=>res(true);r.onerror=()=>rej(r.error)})}
class Query{
 constructor(table){this.table=table;this.action='select';this.payload=null;this.filters=[];this.sort=null;this.max=Infinity}
 select(){this.action=this.action==='insert'?'insert':'select';return this}
 insert(v){this.action='insert';this.payload=Array.isArray(v)?v:[v];return this}
 update(v){this.action='update';this.payload=v;return this}
 delete(){this.action='delete';return this}
 eq(k,v){this.filters.push(x=>x[k]===v);return this}
 order(k,o={}){this.sort={k,asc:o.ascending!==false};return this}
 limit(n){this.max=n;return this}
 async then(resolve,reject){try{let rows=await all(this.table);rows=rows.filter(x=>this.filters.every(f=>f(x)));let data=null;
 if(this.action==='insert'){data=[];for(const x of this.payload)data.push(await put(this.table,x));}
 else if(this.action==='update'){data=[];for(const x of rows){const next={...x,...this.payload};await put(this.table,next);data.push(next)}}
 else if(this.action==='delete'){for(const x of rows)await del(this.table,x.id);data=rows}
 else {if(this.sort)rows.sort((a,b)=>{const c=String(a[this.sort.k]||'').localeCompare(String(b[this.sort.k]||''));return this.sort.asc?c:-c});data=rows.slice(0,this.max)}
 resolve({data,error:null});}catch(error){resolve({data:null,error:{message:error.message||String(error)}})}}
}
async function rpc(name,p){try{
 if(name==='create_rr_bill_v4'){
  const items=p.p_items||[];for(const it of items){if(it.product_id){const prod=(await all('products')).find(x=>x.id===it.product_id);if(!prod||Number(prod.stock)<Number(it.qty))throw Error(`Insufficient stock for ${it.name}`)}}
  const bill=await put('bills',{bill_no:p.p_bill_no,bill_date:p.p_bill_date,customer_id:p.p_customer_id,customer_name:p.p_customer_name,customer_phone:p.p_customer_phone,items,total:Number(p.p_total),cost_total:Number(p.p_cost_total),payment_mode:p.p_payment_mode,points_earned:Math.floor(Number(p.p_total)/100)});
  for(const it of items)if(it.product_id){const prod=(await all('products')).find(x=>x.id===it.product_id);await put('products',{...prod,stock:Number(prod.stock)-Number(it.qty)})}
  if(p.p_customer_id){const c=(await all('customers')).find(x=>x.id===p.p_customer_id);if(c)await put('customers',{...c,points_balance:Number(c.points_balance||0)+Math.floor(Number(p.p_total)/100)})}
  return {data:bill,error:null};
 }
 if(name==='create_rr_stock_purchase_v6'){
  const prod=(await all('products')).find(x=>x.id===p.p_product_id);if(!prod)throw Error('Product not found');const qty=Number(p.p_quantity),cost=Number(p.p_unit_cost);if(qty<=0||cost<0)throw Error('Invalid purchase quantity or cost');
  const purchase=await put('purchases',{product_id:prod.id,product_name:prod.name,supplier:p.p_supplier,quantity:qty,unit_cost:cost,total:qty*cost,purchase_date:p.p_purchase_date});await put('products',{...prod,stock:Number(prod.stock||0)+qty});return {data:purchase,error:null};
 }
 if(name==='record_rr_credit_payment_v10'){
  const bill=(await all('bills')).find(x=>x.id===p.p_bill_id);if(!bill||String(bill.payment_mode).toLowerCase()!=='credit')throw Error('Credit bill not found');const payments=(await all('credit_payments')).filter(x=>x.bill_id===bill.id);const paid=payments.reduce((s,x)=>s+Number(x.amount||0),0),amount=Number(p.p_amount);if(amount<=0||amount>Number(bill.total)-paid)throw Error('Payment exceeds outstanding balance');return {data:await put('credit_payments',{bill_id:bill.id,customer_id:bill.customer_id,payment_date:p.p_payment_date,amount,payment_mode:p.p_payment_mode,notes:p.p_notes}),error:null};
 }
 throw Error(`Unsupported offline operation: ${name}`);
 }catch(error){return {data:null,error:{message:error.message||String(error)}}}}
const listeners=new Set();
export const localClient={from:(t)=>{if(!TABLES.includes(t))throw Error(`Unknown local table: ${t}`);return new Query(t)},rpc,auth:{getSession:async()=>({data:{session:{user:{id:'local-owner',email:'owner@rrmobiles.local'}}}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signInWithPassword:async()=>({data:{session:{user:{id:'local-owner'}}},error:null}),signOut:async()=>({error:null})}};
export async function localDbInfo(){const counts={};for(const t of TABLES)counts[t]=(await all(t)).length;return counts}
export async function clearLocalDatabase(){const d=await db();await new Promise((res,rej)=>{const tx=d.transaction(TABLES,'readwrite');TABLES.forEach(t=>tx.objectStore(t).clear());tx.oncomplete=res;tx.onerror=()=>rej(tx.error)})}
