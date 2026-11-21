-- =====================================================================
-- LABAKU - MIGRASI V3 (Produk, Bahan Baku, Penjualan, Laporan, Akun, Role)
-- Jalankan SETELAH setup.sql & migration_homepage.sql di SQL Editor Supabase.
-- Aman dijalankan ulang.
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

-- ---------- 1. Hilangkan tarif / jam kerja untuk role 'bos' ----------
alter table public.profiles
  alter column tarif drop default,
  alter column satuan_tarif drop default;

update public.profiles
  set tarif = null, satuan_tarif = null
  where role = 'bos';

alter table public.profiles drop constraint if exists profiles_bos_no_tarif;
alter table public.profiles add constraint profiles_bos_no_tarif
  check (role <> 'bos' or (tarif is null and satuan_tarif is null));

-- Pastikan register_owner tidak pernah mengisi tarif/satuan_tarif untuk bos
drop function if exists public.register_owner(text,text,text,text,text,text,text,text,text);
create or replace function public.register_owner(
  p_username text, p_password text, p_nama text, p_slug text, p_kategori text,
  p_deskripsi text, p_logo_url text, p_foto_url text, p_pin text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := gen_random_uuid(); v_biz uuid;
begin
  if p_pin !~ '^\d{6}$' then raise exception 'invalid_pin'; end if;
  if length(coalesce(p_password, '')) < 6 then raise exception 'password_short'; end if;
  if exists (select 1 from public.businesses where slug = p_slug) then
    raise exception 'business_taken';
  end if;
  insert into public.businesses(owner_id, nama, slug, kategori, deskripsi, logo_url)
    values (v_uid, trim(p_nama), p_slug, p_kategori, p_deskripsi, p_logo_url)
    returning id into v_biz;
  insert into public.profiles(id, business_id, username, role, foto_url, password_hash, pin_hash, tarif, satuan_tarif)
    values (v_uid, v_biz, trim(p_username), 'bos', p_foto_url,
            crypt(p_password, gen_salt('bf')), crypt(p_pin, gen_salt('bf')), null, null);
  return jsonb_build_object('uid', v_uid, 'token', public._new_session(v_uid));
end $$;

-- ---------- 2. Update helper material & bootstrap ----------
create or replace function public._material_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', m.id,
    'nama', m.nama,
    'harga_beli', m.harga_beli,
    'jumlah_beli', m.jumlah_beli,
    'unit_id', m.unit_id,
    'unit', u.nama,
    'penyusutan', coalesce(m.penyusutan, 0),
    'used_count', (
      select count(distinct pm.product_id)
      from public.product_materials pm
      join public.products p on p.id = pm.product_id
      where pm.material_id = m.id and coalesce(p.is_deleted, false) = false
    )
  )
  from public.materials m
  left join public.units u on u.id = m.unit_id
  where m.id = p_id
$$;

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
      'foto_url', p.foto_url) as x
    from public.products p
    left join public.units u on u.id = p.unit_id
    left join public.product_categories c on c.id = p.category_id
    where p.business_id = p_biz and coalesce(p.is_deleted, false) = false
    order by p.created_at desc
    limit p_limit) t $$;

-- ---------- 3. Hapus bahan baku ----------
create or replace function public.delete_material(p_token text, p_id uuid) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  delete from public.product_materials where material_id = p_id;
  delete from public.materials where id = p_id and business_id = a.biz;
end $$;

-- ---------- 4. Edit produk ----------
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

  delete from public.product_overheads where product_id = p_id;
  insert into public.product_overheads(product_id, komponen, harga)
    select p_id, o->>'komponen', (o->>'harga')::numeric
    from jsonb_array_elements(coalesce(p->'overheads', '[]'::jsonb)) o;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = p_id limit 1;
  return r;
end $$;

-- ---------- 5. Penjualan (Karyawan & Bos) ----------
create or replace function public.create_sale(p_token text, p_items jsonb) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_sale uuid;
begin
  select * into a from public._auth(p_token);
  if jsonb_array_length(coalesce(p_items, '[]'::jsonb)) < 1 then
    raise exception 'empty_sale';
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

  return v_sale;
end $$;

-- ---------- 6. Laporan Penjualan & Laba Rugi (Filter H/M/B/T) ----------
create or replace function public.get_report(p_token text, p_range text default 'today') returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  a record;
  v_start timestamptz;
  v_tx int;
  v_rev numeric;
  v_profit numeric;
  v_items jsonb;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;

  case lower(coalesce(p_range, 'today'))
    when 'week'  then v_start := date_trunc('week', now());
    when 'month' then v_start := date_trunc('month', now());
    when 'year'  then v_start := date_trunc('year', now());
    else              v_start := date_trunc('day', now());
  end case;

  select
    count(distinct s.id),
    coalesce(sum(si.kuantitas * si.harga_satuan), 0),
    coalesce(sum(
      si.kuantitas * (
        si.harga_satuan -
        case when coalesce(p.jumlah_produksi, 0) > 0
             then coalesce(p.total_hpp, 0) / p.jumlah_produksi
             else 0 end
      )
    ), 0)
  into v_tx, v_rev, v_profit
  from public.sales s
  join public.sale_items si on si.sale_id = s.id
  left join public.products p on p.id = si.product_id
  where s.business_id = a.biz and s.created_at >= v_start;

  select coalesce(jsonb_agg(row_obj order by (row_obj->>'created_at') desc), '[]'::jsonb)
  into v_items
  from (
    select jsonb_build_object(
      'sale_id', s.id,
      'product_name', coalesce(p.nama, 'Produk'),
      'kategori', coalesce(c.nama, 'Lainnya'),
      'kuantitas', si.kuantitas,
      'harga_satuan', si.harga_satuan,
      'total', si.kuantitas * si.harga_satuan,
      'kasir', coalesce(pr.username, '-'),
      'created_at', s.created_at
    ) as row_obj
    from public.sales s
    join public.sale_items si on si.sale_id = s.id
    left join public.products p on p.id = si.product_id
    left join public.product_categories c on c.id = p.category_id
    left join public.profiles pr on pr.id = s.created_by
    where s.business_id = a.biz and s.created_at >= v_start
    order by s.created_at desc
    limit 200
  ) t;

  return jsonb_build_object(
    'tx_count', coalesce(v_tx, 0),
    'pendapatan', coalesce(v_rev, 0),
    'keuntungan', coalesce(v_profit, 0),
    'avg_margin', case when v_rev > 0 then round((v_profit / v_rev) * 100, 1) else 0 end,
    'items', v_items
  );
end $$;

-- ---------- 7. Profil, Usaha, & Kelola Akun Karyawan ----------
create or replace function public.update_profile(
  p_token text, p_username text, p_foto_url text
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  -- Karyawan hanya boleh ubah foto profil (sesuai diagram use case)
  if a.urole = 'karyawan' then
    update public.profiles
      set foto_url = coalesce(p_foto_url, foto_url)
      where id = a.uid;
  else
    if trim(coalesce(p_username, '')) = '' then raise exception 'empty_name'; end if;
    update public.profiles
      set username = trim(p_username),
          foto_url = coalesce(p_foto_url, foto_url)
      where id = a.uid;
  end if;
  return public.get_profile(a.uid);
end $$;

create or replace function public.change_password(p_token text, p_new_password text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if length(coalesce(p_new_password, '')) < 6 then raise exception 'password_short'; end if;
  update public.profiles
    set password_hash = crypt(p_new_password, gen_salt('bf'))
    where id = a.uid;
end $$;

create or replace function public.change_pin(p_token text, p_new_pin text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if p_new_pin !~ '^\d{6}$' then raise exception 'invalid_pin'; end if;
  update public.profiles
    set pin_hash = crypt(p_new_pin, gen_salt('bf'))
    where id = a.uid;
  delete from public.pin_attempts where user_id = a.uid;
end $$;

create or replace function public.update_business(
  p_token text, p_nama text, p_kategori text, p_deskripsi text, p_logo_url text
) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if trim(coalesce(p_nama, '')) = '' then raise exception 'empty_name'; end if;
  update public.businesses
    set nama = trim(p_nama),
        kategori = coalesce(nullif(trim(p_kategori), ''), kategori),
        deskripsi = trim(coalesce(p_deskripsi, '')),
        logo_url = coalesce(p_logo_url, logo_url)
    where id = a.biz;
end $$;

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

  return (select jsonb_build_object(
    'id', id, 'username', username, 'foto_url', foto_url,
    'tarif', coalesce(tarif, 0), 'satuan_tarif', coalesce(satuan_tarif, 'jam')
  ) from public.profiles where id = p_emp_id);
end $$;

-- Update create_employee agar bisa sekaligus menyimpan tarif & satuan_tarif
create or replace function public.create_employee_full(
  p_token text, p_username text, p_password text, p_pin text, p_foto_url text,
  p_tarif numeric default 0, p_satuan_tarif text default 'jam'
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_id uuid := gen_random_uuid();
begin
  select * into a from public._auth(p_token);
  if a.urole <> 'bos' then raise exception 'forbidden'; end if;
  if trim(coalesce(p_username, '')) = '' then raise exception 'empty_name'; end if;
  if length(coalesce(p_password, '')) < 6 then raise exception 'password_short'; end if;
  if p_pin !~ '^\d{6}$' then raise exception 'invalid_pin'; end if;
  if exists (select 1 from public.profiles
             where business_id = a.biz and lower(username) = lower(trim(p_username))) then
    raise exception 'user_taken';
  end if;
  insert into public.profiles(id, business_id, username, role, foto_url, password_hash, pin_hash, tarif, satuan_tarif)
    values (v_id, a.biz, trim(p_username), 'karyawan', p_foto_url,
            crypt(p_password, gen_salt('bf')), crypt(p_pin, gen_salt('bf')),
            coalesce(p_tarif, 0), coalesce(nullif(p_satuan_tarif, ''), 'jam'));
  return jsonb_build_object('id', v_id, 'username', trim(p_username), 'foto_url', p_foto_url,
                            'tarif', coalesce(p_tarif, 0), 'satuan_tarif', coalesce(nullif(p_satuan_tarif, ''), 'jam'));
end $$;

-- ---------- 8. Update bootstrap (Ringkasan Bisnis dari transaksi nyata hari ini) & get_product ----------
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
    'recent', public._products_json(a.biz, 1)
  );
end $$;

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

-- ---------- 9. Hak akses RPC baru ----------
grant execute on function public.bootstrap(text) to anon, authenticated;
grant execute on function public.get_product(text, uuid) to anon, authenticated;
grant execute on function public.register_owner(text,text,text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.delete_material(text, uuid) to anon, authenticated;
grant execute on function public.update_product(text, uuid, jsonb) to anon, authenticated;
grant execute on function public.create_sale(text, jsonb) to anon, authenticated;
grant execute on function public.get_report(text, text) to anon, authenticated;
grant execute on function public.update_profile(text, text, text) to anon, authenticated;
grant execute on function public.change_password(text, text) to anon, authenticated;
grant execute on function public.change_pin(text, text) to anon, authenticated;
grant execute on function public.update_business(text, text, text, text, text) to anon, authenticated;
grant execute on function public.update_employee(text, uuid, text, text, numeric, text, text, text) to anon, authenticated;
grant execute on function public.create_employee_full(text, text, text, text, text, numeric, text) to anon, authenticated;
