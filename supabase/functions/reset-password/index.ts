// Deploy: supabase functions deploy reset-password
// Lupa kata sandi tanpa email: identitas dibuktikan dengan PIN (dibatasi 3x/5 menit di DB).
import { createClient } from 'jsr:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    const { slug, username, pin, new_password } = await req.json();
    if (!slug || !username || !/^\d{6}$/.test(pin ?? '') || (new_password ?? '').length < 6) {
      return json({ ok: false, left: 0, error: 'bad_request' }, 400);
    }
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: uid } = await admin.rpc('find_user', { p_slug: slug, p_username: username });
    if (!uid) return json({ ok: false, left: 0, error: 'user_invalid' }, 404);

    const { data: r, error } = await admin.rpc('verify_pin_for', { p_uid: uid, p_pin: pin });
    if (error) return json({ ok: false, left: 0, error: error.message }, 500);
    if (!r.ok) return json(r);

    const { error: e2 } = await admin.auth.admin.updateUserById(uid, { password: new_password });
    if (e2) return json({ ok: false, left: 0, error: e2.message }, 500);
    return json({ ok: true, left: 3 });
  } catch (e) {
    return json({ ok: false, left: 0, error: String(e) }, 500);
  }
});
