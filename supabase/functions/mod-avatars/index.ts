import { createClient } from '@supabase/supabase-js';

const MAGIC_BYTES: Record<string, number[]> = {
  'image/jpeg': [0xFF, 0xD8, 0xFF],
  'image/png': [0x89, 0x50, 0x4E, 0x47],
};

function isUnsafe(nudity: Record<string, unknown>, offensive: Record<string, unknown>): boolean {
  const sa = (nudity.sexual_activity as number) ?? 0;
  const sd = (nudity.sexual_display as number) ?? 0;
  const erotica = (nudity.erotica as number) ?? 0;

  const saThreshold = parseFloat(Deno.env.get('SE_SA_THRESHOLD') ?? '0.3');
  const sdThreshold = parseFloat(Deno.env.get('SE_SD_THRESHOLD') ?? '0.3');
  const eroticaThreshold = parseFloat(Deno.env.get('SE_EROTICA_THRESHOLD') ?? '0.5');

  const isNudityUnsafe = sa >= saThreshold || sd >= sdThreshold || erotica >= eroticaThreshold;

  const middleFinger = (offensive.middle_finger as number) ?? 0;
  const offensiveThreshold = parseFloat(Deno.env.get('SE_OFFENSIVE_THRESHOLD') ?? '0.3');

  const isOffensiveUnsafe = middleFinger >= offensiveThreshold;

  return isNudityUnsafe || isOffensiveUnsafe;
}

Deno.serve(async (req: Request) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
  const json = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'غير مصرح به', code: 'UNAUTHORIZED' }, 401);
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return json({ error: 'غير مصرح به', code: 'UNAUTHORIZED' }, 401);
    }

    const userId = user.id;
    const maxSize = parseInt(Deno.env.get('MAX_FILE_SIZE') ?? '50000');
    const contentLength = parseInt(req.headers.get('Content-Length') ?? '0');

    if (contentLength > maxSize) {
      return json({ error: 'الملف كبير جداً (الحد الأقصى 50 كيلوبايت)', code: 'INVALID_FILE' }, 400);
    }

    const reqContentType = req.headers.get('Content-Type') ?? '';
    if (!['image/jpeg', 'image/png'].includes(reqContentType)) {
      return json({ error: 'نوع الملف غير مدعوم. يرجى رفع صورة JPEG أو PNG', code: 'INVALID_FILE' }, 400);
    }

    const bodyBytes = await req.arrayBuffer();
    const bytes = new Uint8Array(bodyBytes);

    if (bytes.length === 0) {
      return json({ error: 'الملف فارغ', code: 'INVALID_FILE' }, 400);
    }

    const expectedMagic = MAGIC_BYTES[reqContentType];
    for (let i = 0; i < expectedMagic.length; i++) {
      if (bytes[i] !== expectedMagic[i]) {
        return json({ error: 'الملف غير صالح أو تالف', code: 'INVALID_FILE' }, 400);
      }
    }

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('image_violation_count, image_blocked_until, has_bad_tag, last_violation_at')
      .eq('id', userId)
      .single();

    if (profileError) {
      return json({ error: 'خطأ في التحقق من الحساب', code: 'SERVER_ERROR' }, 500);
    }

    if (profile.has_bad_tag) {
      return json({ error: 'تم حظر رفع الصور بشكل دائم', code: 'PERMANENT_BLOCKED' }, 403);
    }

    if (profile.image_blocked_until) {
      const blockedUntil = new Date(profile.image_blocked_until).getTime();
      if (blockedUntil > Date.now()) {
        const remainingMinutes = Math.ceil((blockedUntil - Date.now()) / 60000);
        return json({
          error: `محظور مؤقتاً. يرجى المحاولة بعد ${remainingMinutes} دقيقة`,
          code: 'TEMPORARILY_BLOCKED',
          blockedUntil: profile.image_blocked_until,
        }, 403);
      }
    }

    // Reset violation count if last violation was more than 7 days ago
    let violationCount = profile.image_violation_count ?? 0;
    if (profile.last_violation_at) {
      const lastViolation = new Date(profile.last_violation_at).getTime();
      const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      if (lastViolation < sevenDaysAgo) {
        violationCount = 0;
      }
    }

    // Collect all available Sightengine API key pairs (SE_API_USER, SE_API_SECRET, SE_API_USER2, SE_API_SECRET2, ...)
    const apiKeys: Array<{ user: string; secret: string }> = [];
    let index = 1;
    while (true) {
      const user = index === 1 ? Deno.env.get('SE_API_USER') : Deno.env.get(`SE_API_USER${index}`);
      const secret = index === 1 ? Deno.env.get('SE_API_SECRET') : Deno.env.get(`SE_API_SECRET${index}`);
      if (user && secret) {
        apiKeys.push({ user, secret });
        index++;
      } else {
        break;
      }
    }

    if (apiKeys.length === 0) {
      return json({ error: 'خدمة الفحص غير مهيأة', code: 'SCAN_FAILED' }, 503);
    }

    // Try each API key pair until one succeeds
    let seData: Record<string, unknown> | null = null;
    let lastError: string | null = null;

    for (const { user: seApiUser, secret: seApiSecret } of apiKeys) {
      const formData = new FormData();
      formData.append('media', new Blob([bytes], { type: reqContentType }), `avatar.${reqContentType === 'image/png' ? 'png' : 'jpg'}`);
      formData.append('models', 'nudity-2.1,offensive');
      formData.append('api_user', seApiUser);
      formData.append('api_secret', seApiSecret);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3000);

      let seResponse: Response;
      try {
        seResponse = await fetch('https://api.sightengine.com/1.0/check.json', {
          method: 'POST',
          body: formData,
          signal: controller.signal,
        });
      } catch (e) {
        clearTimeout(timeoutId);
        lastError = 'تعذر الاتصال بخدمة الفحص';
        continue;
      }
      clearTimeout(timeoutId);

      if (!seResponse.ok) {
        const errorText = await seResponse.text().catch(() => '');
        // Fallback on rate limit (429) or server errors (5xx)
        if (seResponse.status === 429 || seResponse.status >= 500) {
          lastError = `خطأ في خدمة الفحص (${seResponse.status}): ${errorText}`;
          continue;
        }
        // For other errors (400, 401, 403), don't retry with other keys
        return json({ error: 'تعذر فحص الصورة، حاول مرة أخرى', code: 'SCAN_FAILED' }, 503);
      }

      try {
        seData = await seResponse.json();
        break; // Success
      } catch {
        lastError = 'رد غير صالح من خدمة الفحص';
        continue;
      }
    }

    if (!seData) {
      return json({ error: lastError ?? 'تعذر فحص الصورة، حاول مرة أخرى', code: 'SCAN_FAILED' }, 503);
    }

    const nudity = (seData.nudity as Record<string, unknown>) ?? {};
    const offensive = (seData.offensive as Record<string, unknown>) ?? {};

    if (isUnsafe(nudity, offensive)) {
      const newCount = violationCount + 1;
      const blockDurationMinutes = parseInt(Deno.env.get('BLOCK_DURATION_MINUTES') ?? '30');
      const placeholderUrl = Deno.env.get('PLACEHOLDER_URL') ?? '';
      const now = new Date().toISOString();

      const updateData: Record<string, unknown> = {
        image_violation_count: newCount,
        avatar_url: placeholderUrl,
        avatar_updated_at: now,
        last_violation_at: now,
      };

      if (newCount === 2) {
        updateData.image_blocked_until = new Date(
          Date.now() + blockDurationMinutes * 60 * 1000,
        ).toISOString();
      }

      if (newCount >= 3) {
        updateData.has_bad_tag = true;
      }

      await supabaseAdmin.from('profiles').update(updateData).eq('id', userId);

      return json({
        status: 'rejected',
        violationCount: newCount,
        blockedUntil: updateData.image_blocked_until ?? null,
        hasBadTag: updateData.has_bad_tag ?? false,
      });
    }

    const fileName = `${userId}.jpg`;
    const { error: uploadError } = await supabaseAdmin.storage
      .from('avatars')
      .upload(fileName, bytes, {
        contentType: 'image/jpeg',
        upsert: true,
      });

    if (uploadError) {
      return json({ error: 'خطأ في رفع الصورة', code: 'UPLOAD_ERROR' }, 500);
    }

    const { data: publicUrlData } = supabaseAdmin.storage.from('avatars').getPublicUrl(fileName);
    const publicUrl = publicUrlData?.publicUrl ?? '';

    await supabaseAdmin.from('profiles').update({
      avatar_url: publicUrl,
      avatar_updated_at: new Date().toISOString(),
    }).eq('id', userId);

    return json({ status: 'accepted', avatarUrl: publicUrl });
  } catch (e) {
    console.error('mod-avatars internal error:', e);
    return json({ error: 'حدث خطأ داخلي', code: 'INTERNAL_ERROR' }, 500);
  }
});
