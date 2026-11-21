-- =====================================================================
-- LABAKU - MIGRASI V4 (Perbaikan Login Case-Sensitive, Sync Tarif Karyawan, Diskon Produk)
-- Jalankan di Supabase > SQL Editor. Aman dijalankan ulang.
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

-- ---------- 1. Kolom diskon produk (persen / nominal) ----------
alter table public.products
  add column if not exists diskon_mode  text,      -- 'persen' | 'nominal' | null
  add column if not exists diskon_nilai numeric default 0;

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
        coalesce(p.jumlah_produksi, 0) - coalesce((
          select sum(si.kuantitas) from public.sale_items si where si.product_id = p.id
        ), 0)
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
    business_id, category_id, nama, jumlah_produksi, unit_id, overhead_mode, overhead_persen,
    margin_metode, margin_nilai, service_charge_persen, pajak_jenis, pajak_persen, pajak_termasuk,
    pembulatan, pembulatan_step, diskon_persen, total_hpp, harga_jual, laba_bersih, harga_net,
    margin_target, hpp_bahan, hpp_tenaga, hpp_overhead, foto_url)
  values (
    a.biz, nullif(p->>'category_id', '')::uuid, trim(p->>'nama'), (p->>'jumlah_produksi')::numeric,
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

-- ---------- 7. Hak akses ----------
grant execute on function public.login_check(text, text) to anon, authenticated;
grant execute on function public.login_user(text, text, text) to anon, authenticated;
grant execute on function public.reset_pin(text, text, text, text) to anon, authenticated;
grant execute on function public.reset_password(text, text, text, text) to anon, authenticated;
grant execute on function public.change_password(text, text) to anon, authenticated;
grant execute on function public.change_pin(text, text) to anon, authenticated;
grant execute on function public.update_employee(text, uuid, text, text, numeric, text, text, text) to anon, authenticated;
grant execute on function public.set_product_discount(text, uuid, text, numeric, numeric) to anon, authenticated;
grant execute on function public.save_product(text, jsonb) to anon, authenticated;
