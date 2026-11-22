-- =====================================================================
-- LABAKU - MIGRASI V4 (Perbaikan Login Case-Sensitive, Sync Tarif Karyawan, Diskon Produk)
-- Jalankan di Supabase > SQL Editor. Aman dijalankan ulang.
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

-- ---------- 1. Kolom diskon produk (persen / nominal) & stok aktual ----------
alter table public.products
  add column if not exists diskon_mode  text,      -- 'persen' | 'nominal' | null
  add column if not exists diskon_nilai numeric default 0,
  add column if not exists stok         numeric;

-- Backfill stok aktual untuk produk yang sudah ada (jumlah_produksi - total terjual)
update public.products p
set stok = greatest(
  0,
  coalesce(p.jumlah_produksi, 0) - coalesce((
    select sum(si.kuantitas) from public.sale_items si where si.product_id = p.id
  ), 0)
)
where p.stok is null;

-- Backfill tarif & satuan_tarif karyawan yang masih 0 dari data product_labors terbaru
update public.profiles pr
set
  tarif = latest.tarif_snapshot,
  satuan_tarif = coalesce(nullif(latest.metode, ''), 'jam')
from (
  select distinct on (pl.employee_id)
    pl.employee_id,
    pl.tarif_snapshot,
    pl.metode
  from public.product_labors pl
  join public.products p on p.id = pl.product_id
  where coalesce(pl.tarif_snapshot, 0) > 0
  order by pl.employee_id, p.created_at desc
) latest
where pr.id = latest.employee_id
  and pr.role = 'karyawan'
  and coalesce(pr.tarif, 0) = 0;

-- ---------- 1b. Storage RLS policy lengkap (SELECT + INSERT + UPDATE) untuk upload foto profil/logo ----------
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('logos', 'logos', true)
on conflict (id) do update set public = true;

drop policy if exists "labaku_public_select" on storage.objects;
create policy "labaku_public_select" on storage.objects for select to anon, authenticated
  using (bucket_id in ('avatars', 'logos'));

drop policy if exists "labaku_public_upload" on storage.objects;
create policy "labaku_public_upload" on storage.objects for insert to anon, authenticated
  with check (bucket_id in ('avatars', 'logos'));

drop policy if exists "labaku_public_update" on storage.objects;
create policy "labaku_public_update" on storage.objects for update to anon, authenticated
  using (bucket_id in ('avatars', 'logos'))
  with check (bucket_id in ('avatars', 'logos'));

-- ---------- 2. Login & Cek Identitas CASE-SENSITIVE (huruf besar/kecil harus persis) ----------
create or replace function public.login_check(p_slug text, p_username text) returns text
language plpgsql stable security definer set search_path = public as $$
declare v_biz uuid;
begin
  select id into v_biz from public.businesses where nama = trim(p_slug) limit 1;
  if v_biz is null then
    if exists (select 1 from public.profiles where username = trim(p_username))
      then return 'business_invalid';
      else return 'both_invalid';
    end if;
  end if;
  if exists (
    select 1 from public.profiles
    where business_id = v_biz and username = trim(p_username)
  ) then
    return 'ok';
  else
    return 'user_invalid';
  end if;
end $$;

create or replace function public.login_user(
  p_slug     text,
  p_username text,
  p_password text
) returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  v_biz  uuid;
  v_prof record;
begin
  select id into v_biz from public.businesses where nama = trim(p_slug) limit 1;
  if v_biz is null then
    if exists (select 1 from public.profiles where username = trim(p_username)) then
      return jsonb_build_object('status', 'business_invalid');
    else
      return jsonb_build_object('status', 'both_invalid');
    end if;
  end if;

  select id, password_hash into v_prof
  from public.profiles
  where business_id = v_biz and username = trim(p_username)
  limit 1;

  if not found then
    return jsonb_build_object('status', 'user_invalid');
  end if;

  if v_prof.password_hash is null or v_prof.password_hash <> crypt(p_password, v_prof.password_hash) then
    return jsonb_build_object('status', 'password_invalid');
  end if;

  return jsonb_build_object('status', 'ok', 'user_id', v_prof.id);
end $$;

create or replace function public.reset_pin(
  p_slug     text,
  p_username text,
  p_password text,
  p_new_pin  text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_login jsonb;
  v_uid   uuid;
begin
  if p_new_pin !~ '^\d{6}$' then
    return jsonb_build_object('status', 'invalid_pin');
  end if;

  v_login := public.login_user(p_slug, p_username, p_password);
  if v_login->>'status' <> 'ok' then
    return v_login;
  end if;

  v_uid := (v_login->>'user_id')::uuid;
  update public.profiles set pin_hash = crypt(p_new_pin, gen_salt('bf')) where id = v_uid;
  delete from public.pin_attempts where user_id = v_uid;
  delete from public.app_sessions where user_id = v_uid;
  return jsonb_build_object('status', 'ok');
end $$;

create or replace function public.reset_password(
  p_slug         text,
  p_username     text,
  p_pin          text,
  p_new_password text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_biz uuid;
  v_uid uuid;
  v_res jsonb;
begin
  if length(coalesce(p_new_password, '')) < 6 then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'password_short');
  end if;

  select id into v_biz from public.businesses where nama = trim(p_slug) limit 1;
  if v_biz is null then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'business_invalid');
  end if;

  select id into v_uid from public.profiles
  where business_id = v_biz and username = trim(p_username)
  limit 1;

  if v_uid is null then
    return jsonb_build_object('ok', false, 'left', 0, 'error', 'user_invalid');
  end if;

  v_res := public._check_pin(v_uid, p_pin);
  if (v_res->>'ok')::boolean then
    update public.profiles
      set password_hash = crypt(p_new_password, gen_salt('bf'))
      where id = v_uid;
    delete from public.app_sessions where user_id = v_uid;
  end if;

  return v_res;
end $$;

-- ---------- 3. Ubah password juga menghapus sesi lama agar password lama tidak bisa dipakai ----------
create or replace function public.change_password(p_token text, p_new_password text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  a record;
  v_cur_hash text := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if length(coalesce(p_new_password, '')) < 6 then raise exception 'password_short'; end if;
  update public.profiles
    set password_hash = crypt(p_new_password, gen_salt('bf'))
    where id = a.uid;
  delete from public.app_sessions where user_id = a.uid and token_hash <> v_cur_hash;
end $$;

-- Ubah PIN juga memastikan hanya PIN terbaru yang berlaku + hapus sesi lama
create or replace function public.change_pin(p_token text, p_new_pin text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  a record;
  v_cur_hash text := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if p_new_pin !~ '^\d{6}$' then raise exception 'invalid_pin'; end if;
  update public.profiles
    set pin_hash = crypt(p_new_pin, gen_salt('bf'))
    where id = a.uid;
  delete from public.pin_attempts where user_id = a.uid;
  delete from public.app_sessions where user_id = a.uid and token_hash <> v_cur_hash;
end $$;

-- Update karyawan: saat password/PIN diubah, hapus sesi & percobaan PIN lama karyawan
create or replace function public.update_employee(
  p_token text,
  p_emp_id uuid,
  p_username text,
  p_foto_url text,
  p_tarif numeric,
  p_satuan_tarif text,
  p_password text,
  p_pin text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if not exists (select 1 from public.profiles
                 where id = p_emp_id and business_id = a.biz and role = 'karyawan') then
    raise exception 'not_found';
  end if;
  if trim(coalesce(p_username, '')) = '' then raise exception 'empty_name'; end if;
  if p_password is not null and p_password <> '' and length(p_password) < 6 then
    raise exception 'password_short';
  end if;
  if p_pin is not null and p_pin <> '' and p_pin !~ '^\d{6}$' then
    raise exception 'invalid_pin';
  end if;

  update public.profiles set
    username = trim(p_username),
    foto_url = coalesce(p_foto_url, foto_url),
    tarif = coalesce(p_tarif, tarif),
    satuan_tarif = coalesce(nullif(p_satuan_tarif, ''), satuan_tarif),
    password_hash = case when p_password is not null and p_password <> ''
                         then crypt(p_password, gen_salt('bf')) else password_hash end,
    pin_hash = case when p_pin is not null and p_pin <> ''
                    then crypt(p_pin, gen_salt('bf')) else pin_hash end
  where id = p_emp_id and business_id = a.biz;

  if (p_pin is not null and p_pin <> '') or (p_password is not null and p_password <> '') then
    delete from public.pin_attempts where user_id = p_emp_id;
    delete from public.app_sessions where user_id = p_emp_id;
  end if;

  -- Sinkronkan perubahan tarif/satuan karyawan ke semua Tenaga Kerja di produk terkait
  if p_tarif is not null or nullif(p_satuan_tarif, '') is not null then
    update public.product_labors pl
    set
      tarif_snapshot = coalesce(p_tarif, pl.tarif_snapshot),
      metode = coalesce(nullif(p_satuan_tarif, ''), pl.metode)
    where pl.employee_id = p_emp_id
      and exists (
        select 1 from public.products p
        where p.id = pl.product_id and p.business_id = a.biz
      );

    -- Hitung ulang hpp_tenaga, total_hpp, dan laba_bersih untuk produk yang terdampak
    update public.products p
    set
      hpp_tenaga = sub.new_tenaga,
      total_hpp = coalesce(p.hpp_bahan, 0) + sub.new_tenaga + coalesce(p.hpp_overhead, 0),
      laba_bersih = coalesce(p.harga_net, 0) - (coalesce(p.hpp_bahan, 0) + sub.new_tenaga + coalesce(p.hpp_overhead, 0))
    from (
      select
        pl.product_id,
        coalesce(sum(
          case when pl.metode = 'manual' then pl.tarif_snapshot
               else pl.jam_kerja * pl.tarif_snapshot end
        ), 0) as new_tenaga
      from public.product_labors pl
      where pl.product_id in (
        select distinct product_id from public.product_labors where employee_id = p_emp_id
      )
      group by pl.product_id
    ) sub
    where p.id = sub.product_id and p.business_id = a.biz;
  end if;

  return (select jsonb_build_object(
    'id', id, 'username', username, 'foto_url', foto_url,
    'tarif', coalesce(tarif, 0), 'satuan_tarif', coalesce(satuan_tarif, 'jam')
  ) from public.profiles where id = p_emp_id);
end $$;

-- ---------- 4. _products_json menyertakan info diskon ----------
create or replace function public._products_json(p_biz uuid, p_limit int) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by (x->>'created_at') desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', p.id, 'nama', p.nama, 'created_at', p.created_at,
      'jumlah_produksi', p.jumlah_produksi, 'unit_id', p.unit_id, 'unit', u.nama,
      'category_id', p.category_id, 'kategori', c.nama,
      'overhead_mode', p.overhead_mode, 'overhead_persen', p.overhead_persen,
      'margin_metode', p.margin_metode, 'margin_nilai', p.margin_nilai,
      'total_hpp', p.total_hpp, 'harga_jual', p.harga_jual, 'laba_bersih', p.laba_bersih,
      'harga_net', p.harga_net, 'margin_target', p.margin_target,
      'hpp_bahan', coalesce(p.hpp_bahan, 0),
      'hpp_tenaga', coalesce(p.hpp_tenaga, 0),
      'hpp_overhead', coalesce(p.hpp_overhead, 0),
      'service_charge_persen', coalesce(p.service_charge_persen, 0),
      'pajak_jenis', p.pajak_jenis, 'pajak_persen', coalesce(p.pajak_persen, 0),
      'pajak_termasuk', coalesce(p.pajak_termasuk, false),
      'pembulatan', coalesce(p.pembulatan, false),
      'pembulatan_step', p.pembulatan_step,
      'diskon_persen', coalesce(p.diskon_persen, 0),
      'diskon_mode', p.diskon_mode,
      'diskon_nilai', coalesce(p.diskon_nilai, 0),
      'sisa_stok', greatest(
        0,
        coalesce(p.stok, coalesce(p.jumlah_produksi, 0))
      ),
      'foto_url', p.foto_url) as x
    from public.products p
    left join public.units u on u.id = p.unit_id
    left join public.product_categories c on c.id = p.category_id
    where p.business_id = p_biz and coalesce(p.is_deleted, false) = false
    order by p.created_at desc
    limit p_limit) t $$;

-- ---------- 5. Terapkan / hapus diskon produk oleh Bos ----------
create or replace function public.set_product_discount(
  p_token text,
  p_id uuid,
  p_mode text,           -- 'persen' | 'nominal' | null (hapus diskon)
  p_nilai numeric,
  p_persen numeric
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; r jsonb;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  update public.products set
    diskon_mode   = nullif(trim(coalesce(p_mode, '')), ''),
    diskon_nilai  = case when nullif(trim(coalesce(p_mode, '')), '') is null then 0 else coalesce(p_nilai, 0) end,
    diskon_persen = case when nullif(trim(coalesce(p_mode, '')), '') is null then 0 else coalesce(p_persen, 0) end
  where id = p_id and business_id = a.biz;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = p_id limit 1;
  return r;
end $$;

-- ---------- 6. Sync tarif karyawan otomatis saat save_product & update_product ----------
create or replace function public.save_product(p_token text, p jsonb) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_id uuid; r jsonb;
begin
  select * into a from public._auth(p_token);
  if trim(coalesce(p->>'nama', '')) = '' or coalesce((p->>'jumlah_produksi')::numeric, 0) <= 0 then
    raise exception 'invalid_product';
  end if;
  if jsonb_array_length(coalesce(p->'materials', '[]'::jsonb)) < 1 then
    raise exception 'no_materials';
  end if;

  insert into public.products(
    business_id, category_id, nama, jumlah_produksi, stok, unit_id, overhead_mode, overhead_persen,
    margin_metode, margin_nilai, service_charge_persen, pajak_jenis, pajak_persen, pajak_termasuk,
    pembulatan, pembulatan_step, diskon_persen, total_hpp, harga_jual, laba_bersih, harga_net,
    margin_target, hpp_bahan, hpp_tenaga, hpp_overhead, foto_url)
  values (
    a.biz, nullif(p->>'category_id', '')::uuid, trim(p->>'nama'), (p->>'jumlah_produksi')::numeric,
    (p->>'jumlah_produksi')::numeric,
    nullif(p->>'unit_id', '')::uuid, p->>'overhead_mode', (p->>'overhead_persen')::numeric,
    p->>'margin_metode', (p->>'margin_nilai')::numeric,
    coalesce((p->>'service_charge_persen')::numeric, 0), nullif(p->>'pajak_jenis', ''),
    coalesce((p->>'pajak_persen')::numeric, 0), coalesce((p->>'pajak_termasuk')::boolean, false),
    coalesce((p->>'pembulatan')::boolean, false), (p->>'pembulatan_step')::numeric, 0,
    (p->>'total_hpp')::numeric, (p->>'harga_jual')::numeric, (p->>'laba_bersih')::numeric,
    (p->>'harga_net')::numeric, (p->>'margin_target')::numeric,
    (p->>'hpp_bahan')::numeric, (p->>'hpp_tenaga')::numeric, (p->>'hpp_overhead')::numeric,
    p->>'foto_url')
  returning id into v_id;

  insert into public.product_materials(product_id, material_id, qty)
    select v_id, (m->>'material_id')::uuid, (m->>'qty')::numeric
    from jsonb_array_elements(p->'materials') m
    where exists (select 1 from public.materials x
                  where x.id = (m->>'material_id')::uuid and x.business_id = a.biz);

  insert into public.product_labors(product_id, employee_id, jam_kerja, tarif_snapshot, metode)
    select v_id, (l->>'employee_id')::uuid, (l->>'qty')::numeric, (l->>'tarif')::numeric,
           coalesce(l->>'metode', 'jam')
    from jsonb_array_elements(coalesce(p->'labors', '[]'::jsonb)) l
    where exists (select 1 from public.profiles x
                  where x.id = (l->>'employee_id')::uuid and x.business_id = a.biz);

  -- Sinkronkan tarif & satuan_tarif ke profil karyawan
  update public.profiles pr set
    tarif = (l->>'tarif')::numeric,
    satuan_tarif = coalesce(nullif(l->>'metode', ''), 'jam')
  from jsonb_array_elements(coalesce(p->'labors', '[]'::jsonb)) l
  where pr.id = (l->>'employee_id')::uuid
    and pr.business_id = a.biz
    and pr.role = 'karyawan';

  insert into public.product_overheads(product_id, komponen, harga)
    select v_id, o->>'komponen', (o->>'harga')::numeric
    from jsonb_array_elements(coalesce(p->'overheads', '[]'::jsonb)) o;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = v_id limit 1;
  return r;
end $$;

-- ---------- 6a. Sync tarif karyawan otomatis saat update_product ----------
create or replace function public.update_product(p_token text, p_id uuid, p jsonb) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; r jsonb;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if not exists (select 1 from public.products where id = p_id and business_id = a.biz) then
    raise exception 'not_found';
  end if;

  update public.products set
    category_id = nullif(p->>'category_id', '')::uuid,
    nama = trim(p->>'nama'),
    jumlah_produksi = (p->>'jumlah_produksi')::numeric,
    unit_id = nullif(p->>'unit_id', '')::uuid,
    overhead_mode = p->>'overhead_mode',
    overhead_persen = (p->>'overhead_persen')::numeric,
    margin_metode = p->>'margin_metode',
    margin_nilai = (p->>'margin_nilai')::numeric,
    service_charge_persen = coalesce((p->>'service_charge_persen')::numeric, 0),
    pajak_jenis = nullif(p->>'pajak_jenis', ''),
    pajak_persen = coalesce((p->>'pajak_persen')::numeric, 0),
    pajak_termasuk = coalesce((p->>'pajak_termasuk')::boolean, false),
    pembulatan = coalesce((p->>'pembulatan')::boolean, false),
    pembulatan_step = (p->>'pembulatan_step')::numeric,
    total_hpp = (p->>'total_hpp')::numeric,
    harga_jual = (p->>'harga_jual')::numeric,
    laba_bersih = (p->>'laba_bersih')::numeric,
    harga_net = (p->>'harga_net')::numeric,
    margin_target = (p->>'margin_target')::numeric,
    hpp_bahan = (p->>'hpp_bahan')::numeric,
    hpp_tenaga = (p->>'hpp_tenaga')::numeric,
    hpp_overhead = (p->>'hpp_overhead')::numeric,
    foto_url = coalesce(p->>'foto_url', foto_url)
  where id = p_id and business_id = a.biz;

  delete from public.product_materials where product_id = p_id;
  insert into public.product_materials(product_id, material_id, qty)
    select p_id, (m->>'material_id')::uuid, (m->>'qty')::numeric
    from jsonb_array_elements(p->'materials') m
    where exists (select 1 from public.materials x where x.id = (m->>'material_id')::uuid and x.business_id = a.biz);

  delete from public.product_labors where product_id = p_id;
  insert into public.product_labors(product_id, employee_id, jam_kerja, tarif_snapshot, metode)
    select p_id, (l->>'employee_id')::uuid, (l->>'qty')::numeric, (l->>'tarif')::numeric,
           coalesce(l->>'metode', 'jam')
    from jsonb_array_elements(coalesce(p->'labors', '[]'::jsonb)) l
    where exists (select 1 from public.profiles x where x.id = (l->>'employee_id')::uuid and x.business_id = a.biz);

  -- Sinkronkan tarif & satuan_tarif ke profil karyawan
  update public.profiles pr set
    tarif = (l->>'tarif')::numeric,
    satuan_tarif = coalesce(nullif(l->>'metode', ''), 'jam')
  from jsonb_array_elements(coalesce(p->'labors', '[]'::jsonb)) l
  where pr.id = (l->>'employee_id')::uuid
    and pr.business_id = a.biz
    and pr.role = 'karyawan';

  delete from public.product_overheads where product_id = p_id;
  insert into public.product_overheads(product_id, komponen, harga)
    select p_id, o->>'komponen', (o->>'harga')::numeric
    from jsonb_array_elements(coalesce(p->'overheads', '[]'::jsonb)) o;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = p_id limit 1;
  return r;
end $$;

-- ---------- 6b. Penjualan otomatis mengurangi stok produk secara real-time (anti-oversell) ----------
create or replace function public.create_sale(p_token text, p_items jsonb) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare
  a record;
  v_sale uuid;
  v_short text;
begin
  select * into a from public._auth(p_token);
  if jsonb_array_length(coalesce(p_items, '[]'::jsonb)) < 1 then
    raise exception 'empty_sale';
  end if;

  -- Kunci baris produk terkait (FOR UPDATE) agar 2 kasir bersamaan tidak bisa oversell
  perform p.id
  from public.products p
  where p.business_id = a.biz
    and p.id in (
      select (it->>'product_id')::uuid
      from jsonb_array_elements(p_items) it
      where coalesce((it->>'qty')::numeric, 0) > 0
    )
  order by p.id
  for update;

  -- Validasi kecukupan stok aktual sebelum mencatat transaksi
  select p.nama into v_short
  from (
    select (it->>'product_id')::uuid as product_id,
           sum((it->>'qty')::numeric) as qty
    from jsonb_array_elements(p_items) it
    where coalesce((it->>'qty')::numeric, 0) > 0
    group by (it->>'product_id')::uuid
  ) req
  join public.products p on p.id = req.product_id and p.business_id = a.biz
  where coalesce(p.stok, coalesce(p.jumlah_produksi, 0)) < req.qty
  limit 1;

  if v_short is not null then
    raise exception 'out_of_stock';
  end if;

  insert into public.sales(business_id, created_by)
    values (a.biz, a.uid)
    returning id into v_sale;

  insert into public.sale_items(sale_id, product_id, kuantitas, harga_satuan)
    select v_sale, (it->>'product_id')::uuid, (it->>'qty')::numeric, (it->>'harga_satuan')::numeric
    from jsonb_array_elements(p_items) it
    where (it->>'qty')::numeric > 0
      and exists (select 1 from public.products p
                  where p.id = (it->>'product_id')::uuid and p.business_id = a.biz);

  -- Kurangi stok aktual produk yang terjual (tidak mengubah jumlah_produksi / HPP)
  update public.products p
  set stok = greatest(0, coalesce(p.stok, coalesce(p.jumlah_produksi, 0)) - s.qty)
  from (
    select si.product_id, sum(si.kuantitas) as qty
    from public.sale_items si
    where si.sale_id = v_sale
    group by si.product_id
  ) s
  where p.id = s.product_id and p.business_id = a.biz;

  return v_sale;
end $$;

-- ---------- 6d. Indeks performa query (produk, penjualan, tenaga kerja, sesi) ----------
create index if not exists idx_products_biz_created on public.products(business_id, created_at desc);
create index if not exists idx_sales_biz_created on public.sales(business_id, created_at desc);
create index if not exists idx_sale_items_sale on public.sale_items(sale_id);
create index if not exists idx_sale_items_product on public.sale_items(product_id);
create index if not exists idx_product_labors_emp on public.product_labors(employee_id);
create index if not exists idx_product_labors_prod on public.product_labors(product_id);
create index if not exists idx_app_sessions_user on public.app_sessions(user_id);

-- ---------- 6c. Bos tambah / atur stok aktual tanpa mengubah HPP ----------
create or replace function public.update_product_stock(
  p_token text,
  p_id uuid,
  p_nilai numeric,
  p_mode text default 'add'   -- 'add' = tambah stok, 'set' = atur stok langsung
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; r jsonb;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if coalesce(p_nilai, 0) < 0 then raise exception 'invalid_stock'; end if;

  update public.products
  set stok = case
    when lower(coalesce(p_mode, 'add')) = 'set' then greatest(0, coalesce(p_nilai, 0))
    else greatest(0, coalesce(stok, coalesce(jumlah_produksi, 0)) + coalesce(p_nilai, 0))
  end
  where id = p_id and business_id = a.biz;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = p_id limit 1;
  return r;
end $$;

-- ---------- 6e. Bootstrap mengembalikan maksimal 10 aktivitas produk terbaru ----------
create or replace function public.bootstrap(p_token text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  a record;
  v_rev numeric;
  v_profit numeric;
  v_pcount int;
begin
  select * into a from public._auth(p_token);
  perform public._seed_defaults(a.biz);

  select count(*) into v_pcount
  from public.products
  where business_id = a.biz and coalesce(is_deleted, false) = false;

  select
    coalesce(sum(si.kuantitas * si.harga_satuan), 0),
    coalesce(sum(
      si.kuantitas * (
        si.harga_satuan -
        case when coalesce(p.jumlah_produksi, 0) > 0
             then coalesce(p.total_hpp, 0) / p.jumlah_produksi
             else 0 end
      )
    ), 0)
  into v_rev, v_profit
  from public.sales s
  join public.sale_items si on si.sale_id = s.id
  left join public.products p on p.id = si.product_id
  where s.business_id = a.biz and s.created_at >= date_trunc('day', now());

  return jsonb_build_object(
    'profile', (select jsonb_build_object('id', p.id, 'username', p.username, 'role', p.role,
                 'foto_url', p.foto_url) from public.profiles p where p.id = a.uid),
    'business', (select jsonb_build_object('id', b.id, 'nama', b.nama, 'kategori', b.kategori,
                 'deskripsi', b.deskripsi, 'logo_url', b.logo_url)
                 from public.businesses b where b.id = a.biz),
    'units', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'nama', nama)
                 order by array_position(array['pcs','porsi','pack','Liter','kg','gram'], nama), nama)
                 from public.units where business_id = a.biz), '[]'::jsonb),
    'categories', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'nama', nama)
                 order by array_position(array['Makanan','Minuman','Pakaian','Elektronik'], nama), nama)
                 from public.product_categories where business_id = a.biz), '[]'::jsonb),
    'materials', coalesce((select jsonb_agg(public._material_json(id) order by nama)
                 from public.materials where business_id = a.biz), '[]'::jsonb),
    'employees', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'username', username,
                 'foto_url', foto_url, 'tarif', coalesce(tarif, 0), 'satuan_tarif', coalesce(satuan_tarif, 'jam'))
                 order by username)
                 from public.profiles where business_id = a.biz and role = 'karyawan'), '[]'::jsonb),
    'stats', jsonb_build_object(
      'product_count', coalesce(v_pcount, 0),
      'pendapatan', coalesce(v_rev, 0),
      'keuntungan', coalesce(v_profit, 0)
    ),
    'recent', public._products_json(a.biz, 10)
  );
end $$;

-- ---------- 6f. Pastikan get_product selalu menyertakan employee_id ----------
create or replace function public.get_product(p_token text, p_id uuid) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; r jsonb;
begin
  select * into a from public._auth(p_token);
  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = p_id limit 1;
  if r is null then raise exception 'not_found'; end if;
  return r || jsonb_build_object(
    'materials', coalesce((select jsonb_agg(jsonb_build_object(
        'material_id', m.id, 'nama', m.nama, 'qty', pm.qty,
        'unit', u.nama, 'harga_beli', m.harga_beli, 'jumlah_beli', m.jumlah_beli,
        'penyusutan', coalesce(m.penyusutan, 0)))
        from public.product_materials pm join public.materials m on m.id = pm.material_id
        left join public.units u on u.id = m.unit_id where pm.product_id = p_id), '[]'::jsonb),
    'labors', coalesce((select jsonb_agg(jsonb_build_object(
        'employee_id', pr.id, 'nama', pr.username, 'qty', pl.jam_kerja,
        'tarif', pl.tarif_snapshot, 'metode', pl.metode))
        from public.product_labors pl join public.profiles pr on pr.id = pl.employee_id
        where pl.product_id = p_id), '[]'::jsonb),
    'overheads', coalesce((select jsonb_agg(jsonb_build_object('komponen', komponen, 'harga', harga))
        from public.product_overheads where product_id = p_id), '[]'::jsonb));
end $$;

grant execute on function public.bootstrap(text) to anon, authenticated;
grant execute on function public.get_product(text, uuid) to anon, authenticated;
grant execute on function public.login_check(text, text) to anon, authenticated;
grant execute on function public.login_user(text, text, text) to anon, authenticated;
grant execute on function public.reset_pin(text, text, text, text) to anon, authenticated;
grant execute on function public.reset_password(text, text, text, text) to anon, authenticated;
grant execute on function public.change_password(text, text) to anon, authenticated;
grant execute on function public.change_pin(text, text) to anon, authenticated;
grant execute on function public.update_employee(text, uuid, text, text, numeric, text, text, text) to anon, authenticated;
grant execute on function public.set_product_discount(text, uuid, text, numeric, numeric) to anon, authenticated;
grant execute on function public.save_product(text, jsonb) to anon, authenticated;
grant execute on function public.update_product(text, uuid, jsonb) to anon, authenticated;
grant execute on function public.create_sale(text, jsonb) to anon, authenticated;
grant execute on function public.update_product_stock(text, uuid, numeric, text) to anon, authenticated;
