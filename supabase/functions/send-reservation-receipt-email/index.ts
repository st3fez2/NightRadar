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
    const guestName = String(payload.guestName ?? "").trim();

    if (!toEmail || !eventTitle || !guestName) {
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

    const venueName = String(payload.venueName ?? "").trim();
    const city = String(payload.city ?? "").trim();
    const startsAt = String(payload.startsAt ?? "").trim();
    const offerTitle = String(payload.offerTitle ?? "").trim();
    const listName = String(payload.listName ?? "").trim();
    const qrToken = String(payload.qrToken ?? "").trim();
    const entrySecretCode = String(payload.entrySecretCode ?? "").trim();
    const partySize = Number(payload.partySize ?? 1);
    const guestAccessType = String(payload.guestAccessType ?? "").trim();

    const lines = [
      `NightRadar - ricevuta iscrizione`,
      "",
      `Evento: ${eventTitle}`,
      venueName ? `Locale: ${venueName}` : "",
      city ? `Citta: ${city}` : "",
      startsAt ? `Data: ${startsAt}` : "",
      `Referente: ${guestName}`,
      `Numero persone: ${partySize}`,
      guestAccessType ? `Accesso: ${guestAccessType}` : "",
      offerTitle ? `Offerta: ${offerTitle}` : "",
      listName ? `Lista/Tavolo: ${listName}` : "",
      entrySecretCode ? `Codice segreto: ${entrySecretCode}` : "",
      qrToken ? `QR token: ${qrToken}` : "",
      "",
      "Conserva questa email e mostra all ingresso solo i dati richiesti dal PR.",
    ].filter(Boolean);

    await transporter.sendMail({
      from,
      to: toEmail,
      subject: `[NightRadar] Ricevuta iscrizione per ${eventTitle}`,
      text: lines.join("\n"),
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
