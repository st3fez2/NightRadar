import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

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
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Supabase service role is not configured");
    }

    const payload = await request.json();
    const eventId = String(payload.eventId ?? "").trim();
    const viewerToken = String(payload.viewerToken ?? "").trim();

    if (!eventId || !viewerToken) {
      throw new Error("Missing required payload");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: eventRow, error: eventError } = await supabase
      .from("events")
      .select("id, is_public")
      .eq("id", eventId)
      .maybeSingle();

    if (eventError) {
      throw eventError;
    }

    if (!eventRow || eventRow.is_public !== true) {
      throw new Error("Event not available");
    }

    const { data: existingRow, error: existingError } = await supabase
      .from("event_likes")
      .select("id")
      .eq("event_id", eventId)
      .eq("viewer_token", viewerToken)
      .maybeSingle();

    if (existingError) {
      throw existingError;
    }

    let liked = false;
    if (existingRow?.id) {
      const { error: deleteError } = await supabase
        .from("event_likes")
        .delete()
        .eq("id", existingRow.id);

      if (deleteError) {
        throw deleteError;
      }
    } else {
      const { error: insertError } = await supabase
        .from("event_likes")
        .insert({
          event_id: eventId,
          viewer_token: viewerToken,
        });

      if (insertError) {
        throw insertError;
      }
      liked = true;
    }

    const { data: countRow, error: countError } = await supabase
      .from("event_like_totals")
      .select("like_count")
      .eq("event_id", eventId)
      .maybeSingle();

    if (countError) {
      throw countError;
    }

    return new Response(
      JSON.stringify({
        ok: true,
        liked,
        likeCount: countRow?.like_count ?? 0,
      }),
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
      error instanceof Error ? error.message : "Unexpected toggle error";

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
