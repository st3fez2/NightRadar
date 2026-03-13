import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import nodemailer from "npm:nodemailer@6.10.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await request.json();
    const toEmail = String(payload.toEmail ?? "").trim();
    const eventTitle = String(payload.eventTitle ?? "").trim();
    const requesterName = String(payload.requesterName ?? "").trim();
    const message = String(payload.message ?? "").trim();

    if (!toEmail || !eventTitle || !requesterName || !message) {
      throw new Error("Missing required payload");
    }

    const host = Deno.env.get("NR_SMTP_HOST") ?? "smtp.gmail.com";
    const port = Number(Deno.env.get("NR_SMTP_PORT") ?? "465");
    const user = Deno.env.get("NR_SMTP_USER");
    const pass = Deno.env.get("NR_SMTP_PASS");
    const from = Deno.env.get("NR_SMTP_FROM") ?? user;

    if (!user || !pass || !from) {
      throw new Error("SMTP secrets not configured");
    }

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port == 465,
      auth: { user, pass },
    });

    const promoterName = String(payload.promoterName ?? "PR").trim();
    const offerTitle = String(payload.offerTitle ?? "").trim();
    const requesterEmail = String(payload.requesterEmail ?? "").trim();
    const requesterPhone = String(payload.requesterPhone ?? "").trim();
    const partySize = Number(payload.partySize ?? 1);
    const replyPreference = String(payload.replyPreference ?? "whatsapp").trim();

    const lines = [
      `NightRadar - nuova richiesta per ${eventTitle}`,
      "",
      `PR: ${promoterName}`,
      `Richiedente: ${requesterName}`,
      requesterEmail ? `Email: ${requesterEmail}` : "",
      requesterPhone ? `Telefono: ${requesterPhone}` : "",
      offerTitle ? `Offerta: ${offerTitle}` : "",
      `Numero persone: ${partySize}`,
      `Preferenza risposta: ${replyPreference}`,
      "",
      "Messaggio:",
      message,
    ].filter(Boolean);

    await transporter.sendMail({
      from,
      to: toEmail,
      subject: `[NightRadar] Nuova richiesta per ${eventTitle}`,
      text: lines.join("\n"),
      replyTo: requesterEmail || undefined,
    });

    return new Response(
      JSON.stringify({ ok: true }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unexpected send error";

    return new Response(
      JSON.stringify({ ok: false, error: message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});
