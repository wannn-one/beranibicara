import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { JWT } from "npm:google-auth-library@9";

type WebhookPayload = {
  type?: string;
  table?: string;
  record?: {
    id?: number;
    user_id?: string;
    title?: string;
    body?: string;
    data?: Record<string, string> | null;
    notification_type?: string | null;
    related_entity_type?: string | null;
    related_entity_id?: string | null;
  };
};

const encoder = new TextEncoder();

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function getAccessToken(
  serviceAccount: { client_email: string; private_key: string },
): Promise<string> {
  const client = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tokens = await client.authorize();
  if (!tokens.access_token) {
    throw new Error("Failed to obtain FCM access token");
  }
  return tokens.access_token;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("FCM_WEBHOOK_SECRET");
  const provided = req.headers.get("x-webhook-secret");
  if (!webhookSecret || provided !== webhookSecret) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

  if (!supabaseUrl || !serviceKey || !serviceAccountRaw) {
    return jsonResponse({ error: "Missing server configuration" }, 500);
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const record = payload.record;
  if (!record?.user_id || !record.title || !record.body) {
    return jsonResponse({ ok: true, skipped: true });
  }

  const serviceAccount = JSON.parse(serviceAccountRaw) as {
    project_id: string;
    client_email: string;
    private_key: string;
  };

  const supabase = createClient(supabaseUrl, serviceKey);
  const { data: tokens, error: tokenError } = await supabase
    .from("device_tokens")
    .select("id, fcm_token")
    .eq("user_id", record.user_id)
    .eq("is_active", true);

  if (tokenError) {
    return jsonResponse({ error: tokenError.message }, 500);
  }
  if (!tokens?.length) {
    return jsonResponse({ ok: true, sent: 0 });
  }

  const accessToken = await getAccessToken(serviceAccount);
  const dataPayload: Record<string, string> = {
    notification_id: String(record.id ?? ""),
    type: record.notification_type ?? "",
    related_entity_type: record.related_entity_type ?? "",
    related_entity_id: record.related_entity_id ?? "",
  };
  if (record.data && typeof record.data === "object") {
    for (const [key, value] of Object.entries(record.data)) {
      dataPayload[key] = String(value);
    }
  }

  let sent = 0;
  for (const row of tokens) {
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: row.fcm_token,
            notification: {
              title: record.title,
              body: record.body,
            },
            data: dataPayload,
            android: {
              priority: "HIGH",
              notification: { channel_id: "beranibicara_alerts" },
            },
          },
        }),
      },
    );

    if (fcmResponse.ok) {
      sent += 1;
      continue;
    }

    const errText = await fcmResponse.text();
    if (errText.includes("UNREGISTERED") || errText.includes("NOT_FOUND")) {
      await supabase
        .from("device_tokens")
        .update({ is_active: false })
        .eq("id", row.id);
    } else {
      console.error("FCM send failed", encoder.encode(errText));
    }
  }

  return jsonResponse({ ok: true, sent });
});
