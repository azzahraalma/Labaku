-- =====================================================================
-- LABAKU - MIGRASI HOMEPAGE / PRODUK / HPP  (jalankan SETELAH setup.sql)
-- Aman dijalankan ulang. Menambah kolom + RPC; tidak menghapus data.
-- Semua data diakses lewat RPC bertoken (tanpa email / Supabase Auth).
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

-- ---------- 1. kolom tambahan ----------
alter table public.products
  add column if not exists foto_url        text,
  add column if not exists pajak_persen    numeric default 0,
  add column if not exists pajak_termasuk  boolean default false,
  add column if not exists pembulatan_step numeric,
  add column if not exists harga_net       numeric,   -- harga jual sebelum pajak & layanan
  add column if not exists margin_target   numeric,   -- margin (% dari harga jual) sebelum pajak
  add column if not exists hpp_bahan       numeric,
  add column if not exists hpp_tenaga      numeric,
  add column if not exists hpp_overhead    numeric;

alter table public.product_labors
  add column if not exists metode text default 'jam';  -- jam | hari | output | manual

-- ---------- 2. sesi bertoken ----------
create table if not exists public.app_sessions (
  token_hash text primary key,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);
alter table public.app_sessions enable row level security;

create or replace function public._new_session(p_uid uuid) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare v_tok text := encode(gen_random_bytes(24), 'hex');
begin
  delete from public.app_sessions where expires_at < now();
  insert into public.app_sessions(token_hash, user_id)
    values (encode(digest(v_tok, 'sha256'), 'hex'), p_uid);
  return v_tok;
end $$;

create or replace function public._auth(p_token text, out uid uuid, out biz uuid, out urole text)
language plpgsql security definer set search_path = public, extensions as $$
begin
  select s.user_id, p.business_id, p.role into uid, biz, urole
  from public.app_sessions s join public.profiles p on p.id = s.user_id
  where s.token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
    and s.expires_at > now();
  if uid is null then raise exception 'unauthorized'; end if;
end $$;

-- verify_pin sekarang mengembalikan token sesi saat PIN benar
create or replace function public.verify_pin(p_uid uuid, p_pin text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare r jsonb;
begin
  r := public._check_pin(p_uid, p_pin);
  if (r->>'ok')::boolean then
    r := r || jsonb_build_object('token', public._new_session(p_uid));
  end if;
  return r;
end $$;

-- register_owner sekarang mengembalikan {uid, token}
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
  insert into public.profiles(id, business_id, username, role, foto_url, password_hash, pin_hash)
    values (v_uid, v_biz, trim(p_username), 'bos', p_foto_url,
            crypt(p_password, gen_salt('bf')), crypt(p_pin, gen_salt('bf')));
  return jsonb_build_object('uid', v_uid, 'token', public._new_session(v_uid));
end $$;

create or replace function public.logout(p_token text) returns void
language sql security definer set search_path = public, extensions as
$$ delete from public.app_sessions where token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex') $$;

-- ---------- 3. helper data ----------
create or replace function public._seed_defaults(p_biz uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.units where business_id = p_biz) then
    insert into public.units(business_id, nama)
      select p_biz, n from unnest(array['pcs','porsi','pack','Liter','kg','gram']) n;
  end if;
  if not exists (select 1 from public.product_categories where business_id = p_biz) then
    insert into public.product_categories(business_id, nama)
      select p_biz, n from unnest(array['Makanan','Minuman','Pakaian','Elektronik']) n;
  end if;
end $$;

create or replace function public._material_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', m.id, 'nama', m.nama, 'harga_beli', m.harga_beli,
         'jumlah_beli', m.jumlah_beli, 'unit_id', m.unit_id, 'unit', u.nama,
         'penyusutan', coalesce(m.penyusutan, 0))
  from public.materials m left join public.units u on u.id = m.unit_id where m.id = p_id $$;

create or replace function public._products_json(p_biz uuid, p_limit int) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by (x->>'created_at') desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', p.id, 'nama', p.nama, 'created_at', p.created_at,
      'jumlah_produksi', p.jumlah_produksi, 'unit', u.nama, 'kategori', c.nama,
      'total_hpp', p.total_hpp, 'harga_jual', p.harga_jual, 'laba_bersih', p.laba_bersih,
      'harga_net', p.harga_net, 'margin_target', p.margin_target,
      'service_charge_persen', coalesce(p.service_charge_persen, 0),
      'pajak_jenis', p.pajak_jenis, 'pajak_persen', coalesce(p.pajak_persen, 0),
      'pajak_termasuk', coalesce(p.pajak_termasuk, false),
      'pembulatan', coalesce(p.pembulatan, false), 'foto_url', p.foto_url) as x
    from public.products p
    left join public.units u on u.id = p.unit_id
    left join public.product_categories c on c.id = p.category_id
    where p.business_id = p_biz and coalesce(p.is_deleted, false) = false
    order by p.created_at desc
    limit p_limit) t $$;

-- ---------- 4. RPC aplikasi ----------
create or replace function public.bootstrap(p_token text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  perform public._seed_defaults(a.biz);
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
                 'foto_url', foto_url, 'tarif', coalesce(tarif, 0), 'satuan_tarif', satuan_tarif)
                 order by username)
                 from public.profiles where business_id = a.biz and role = 'karyawan'), '[]'::jsonb),
    'stats', (select jsonb_build_object('product_count', count(*),
                 'pendapatan', coalesce(sum(harga_net), 0),
                 'keuntungan', coalesce(sum(laba_bersih), 0))
                 from public.products where business_id = a.biz and coalesce(is_deleted, false) = false),
    'recent', public._products_json(a.biz, 1)
  );
end $$;

create or replace function public.list_products(p_token text, p_limit int default 100) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  return public._products_json(a.biz, greatest(1, least(coalesce(p_limit, 100), 500)));
end $$;

create or replace function public.add_unit(p_token text, p_nama text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_id uuid; v_n text := trim(coalesce(p_nama, ''));
begin
  select * into a from public._auth(p_token);
  if v_n = '' then raise exception 'empty_name'; end if;
  select id into v_id from public.units where business_id = a.biz and lower(nama) = lower(v_n);
  if v_id is null then
    insert into public.units(business_id, nama) values (a.biz, v_n) returning id into v_id;
  end if;
  return jsonb_build_object('id', v_id, 'nama', (select nama from public.units where id = v_id));
end $$;

create or replace function public.add_category(p_token text, p_nama text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_id uuid; v_n text := trim(coalesce(p_nama, ''));
begin
  select * into a from public._auth(p_token);
  if v_n = '' then raise exception 'empty_name'; end if;
  select id into v_id from public.product_categories
    where business_id = a.biz and lower(nama) = lower(v_n);
  if v_id is null then
    insert into public.product_categories(business_id, nama) values (a.biz, v_n) returning id into v_id;
  end if;
  return jsonb_build_object('id', v_id,
    'nama', (select nama from public.product_categories where id = v_id));
end $$;

create or replace function public.save_material(
  p_token text, p_id uuid, p_nama text, p_harga numeric, p_jumlah numeric,
  p_unit_id uuid, p_penyusutan numeric
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare a record; v_id uuid;
begin
  select * into a from public._auth(p_token);
  if trim(coalesce(p_nama, '')) = '' or coalesce(p_harga, 0) <= 0 or coalesce(p_jumlah, 0) <= 0
     or coalesce(p_penyusutan, 0) < 0 or coalesce(p_penyusutan, 0) >= 100 then
    raise exception 'invalid_material';
  end if;
  if p_unit_id is not null and not exists
     (select 1 from public.units where id = p_unit_id and business_id = a.biz) then
    raise exception 'invalid_unit';
  end if;
  if p_id is null then
    insert into public.materials(business_id, nama, harga_beli, jumlah_beli, unit_id, penyusutan)
      values (a.biz, trim(p_nama), p_harga, p_jumlah, p_unit_id, coalesce(p_penyusutan, 0))
      returning id into v_id;
  else
    update public.materials set nama = trim(p_nama), harga_beli = p_harga, jumlah_beli = p_jumlah,
           unit_id = p_unit_id, penyusutan = coalesce(p_penyusutan, 0)
      where id = p_id and business_id = a.biz returning id into v_id;
    if v_id is null then raise exception 'not_found'; end if;
  end if;
  return public._material_json(v_id);
end $$;

-- hanya Bos yang boleh membuat akun karyawan
create or replace function public.create_employee(
  p_token text, p_username text, p_password text, p_pin text, p_foto_url text
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
  insert into public.profiles(id, business_id, username, role, foto_url, password_hash, pin_hash)
    values (v_id, a.biz, trim(p_username), 'karyawan', p_foto_url,
            crypt(p_password, gen_salt('bf')), crypt(p_pin, gen_salt('bf')));
  return jsonb_build_object('id', v_id, 'username', trim(p_username), 'foto_url', p_foto_url,
                            'tarif', 0, 'satuan_tarif', 'jam');
end $$;

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

  insert into public.product_overheads(product_id, komponen, harga)
    select v_id, o->>'komponen', (o->>'harga')::numeric
    from jsonb_array_elements(coalesce(p->'overheads', '[]'::jsonb)) o;

  select x into r from jsonb_array_elements(public._products_json(a.biz, 500)) x
    where (x->>'id')::uuid = v_id limit 1;
  return r;
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
    'materials', coalesce((select jsonb_agg(jsonb_build_object('nama', m.nama, 'qty', pm.qty,
        'unit', u.nama, 'harga_beli', m.harga_beli, 'jumlah_beli', m.jumlah_beli,
        'penyusutan', coalesce(m.penyusutan, 0)))
        from public.product_materials pm join public.materials m on m.id = pm.material_id
        left join public.units u on u.id = m.unit_id where pm.product_id = p_id), '[]'::jsonb),
    'labors', coalesce((select jsonb_agg(jsonb_build_object('nama', pr.username, 'qty', pl.jam_kerja,
        'tarif', pl.tarif_snapshot, 'metode', pl.metode))
        from public.product_labors pl join public.profiles pr on pr.id = pl.employee_id
        where pl.product_id = p_id), '[]'::jsonb),
    'overheads', coalesce((select jsonb_agg(jsonb_build_object('komponen', komponen, 'harga', harga))
        from public.product_overheads where product_id = p_id), '[]'::jsonb));
end $$;

create or replace function public.delete_product(p_token text, p_id uuid) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare a record;
begin
  select * into a from public._auth(p_token);
  update public.products set is_deleted = true where id = p_id and business_id = a.biz;
end $$;

-- ---------- 5. hak akses ----------
revoke all on function public._new_session(uuid) from public, anon, authenticated;
revoke all on function public._auth(text) from public, anon, authenticated;
revoke all on function public._seed_defaults(uuid) from public, anon, authenticated;
revoke all on function public._material_json(uuid) from public, anon, authenticated;
revoke all on function public._products_json(uuid, int) from public, anon, authenticated;

grant execute on function public.verify_pin(uuid, text) to anon, authenticated;
grant execute on function public.register_owner(text,text,text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.logout(text) to anon, authenticated;
grant execute on function public.bootstrap(text) to anon, authenticated;
grant execute on function public.list_products(text, int) to anon, authenticated;
grant execute on function public.add_unit(text, text) to anon, authenticated;
grant execute on function public.add_category(text, text) to anon, authenticated;
grant execute on function public.save_material(text, uuid, text, numeric, numeric, uuid, numeric) to anon, authenticated;
grant execute on function public.create_employee(text, text, text, text, text) to anon, authenticated;
grant execute on function public.save_product(text, jsonb) to anon, authenticated;
grant execute on function public.get_product(text, uuid) to anon, authenticated;
grant execute on function public.delete_product(text, uuid) to anon, authenticated;

-- tabel data TIDAK boleh diakses langsung dari client (hanya lewat RPC di atas)
alter table public.units               enable row level security;
alter table public.product_categories  enable row level security;
alter table public.materials           enable row level security;
alter table public.products            enable row level security;
alter table public.product_materials   enable row level security;
alter table public.product_labors      enable row level security;
alter table public.product_overheads   enable row level security;
alter table public.sales               enable row level security;
alter table public.sale_items          enable row level security;
revoke all on public.units, public.product_categories, public.materials, public.products,
  public.product_materials, public.product_labors, public.product_overheads,
  public.sales, public.sale_items, public.businesses, public.profiles, public.app_sessions
  from anon, authenticated;

-- bucket foto produk memakai bucket 'logos' yang sudah ada (path: produk/...)
