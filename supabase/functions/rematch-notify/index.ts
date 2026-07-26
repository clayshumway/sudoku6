// Emails "rematch started" invites to the players of the previous
// competition who haven't joined the rematch yet.
//
// Runs as an Edge Function because it needs two secrets the client can never
// hold: the service-role key (to read player email addresses out of
// auth.users) and the Resend API key. The client invokes it best-effort right
// after creating a rematch; everything user-visible works without it.
//
// Idempotent by design: rematch_notified_at is stamped on the rematch row
// after the first successful send, so repeated invocations (a second player
// pressing Rematch, a retry after a flaky network) can't re-spam the group.
//
// Secrets required (Edge Functions -> Secrets):
//   RESEND_API_KEY  -- a Resend key with sending access
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "npm:@supabase/supabase-js@2";

const SITE = "https://s6.clayshumway.com";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  try {
    const { competition_id } = await req.json().catch(() => ({}));
    if (!competition_id) {
      return json({ error: "competition_id required" }, 400);
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Identify the caller from the JWT the app sent.
    const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "not signed in" }, 401);
    const callerId = userData.user.id;

    // The rematch and the competition that spawned it.
    const { data: rematch } = await admin
      .from("competitions")
      .select("id, code, tier, rounds, rematch_notified_at")
      .eq("id", competition_id)
      .maybeSingle();
    if (!rematch) return json({ error: "no such competition" }, 404);
    if (rematch.rematch_notified_at) {
      return json({ ok: true, already_notified: true });
    }

    const { data: parent } = await admin
      .from("competitions")
      .select("id")
      .eq("rematch_id", competition_id)
      .maybeSingle();
    if (!parent) return json({ error: "not a rematch" }, 400);

    // Caller must belong to the chain being notified about.
    const { data: membership } = await admin
      .from("competition_players")
      .select("competition_id")
      .eq("user_id", callerId)
      .in("competition_id", [parent.id, rematch.id]);
    if (!membership?.length) return json({ error: "not a player" }, 403);

    // Recipients: previous players who haven't joined the rematch.
    const { data: parentPlayers } = await admin
      .from("competition_players")
      .select("user_id")
      .eq("competition_id", parent.id);
    const { data: rematchPlayers } = await admin
      .from("competition_players")
      .select("user_id")
      .eq("competition_id", rematch.id);
    const already = new Set((rematchPlayers ?? []).map((r) => r.user_id));
    const targets = (parentPlayers ?? [])
      .map((r) => r.user_id)
      .filter((id) => !already.has(id));

    const { data: profile } = await admin
      .from("profiles")
      .select("username")
      .eq("id", callerId)
      .maybeSingle();
    const who = profile?.username ?? "A player";
    const joinUrl = `${SITE}/#/c/${rematch.code}`;

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) return json({ error: "RESEND_API_KEY not configured" }, 500);

    let sent = 0;
    for (const id of targets) {
      const { data: u } = await admin.auth.admin.getUserById(id);
      const email = u?.user?.email;
      if (!email) continue;

      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: "Sudoku 6 <noreply@clayshumway.com>",
          to: [email],
          subject: `${who} wants a rematch!`,
          html: [
            `<h2>${who} started a rematch</h2>`,
            `<p>${rematch.rounds} round${rematch.rounds === 1 ? "" : "s"} of ${rematch.tier} — same group, new puzzles.</p>`,
            `<p><a href="${joinUrl}" style="font-size:18px;font-weight:700;">Join the rematch</a></p>`,
            `<p style="color:#666;font-size:13px;">Or open Sudoku 6 and find it under Compete &rarr; Your competitions. ` +
              `If the rematch already finished by the time you read this, you can start the next one from there.</p>`,
          ].join("\n"),
        }),
      });
      if (res.ok) sent++;
    }

    // Stamp only after attempting sends, so a hard failure earlier can retry.
    await admin
      .from("competitions")
      .update({ rematch_notified_at: new Date().toISOString() })
      .eq("id", competition_id);

    return json({ ok: true, sent });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
