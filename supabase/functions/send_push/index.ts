import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";

interface SendPushRequest {
  title: string;
  body: string;
  data?: Record<string, unknown>;
  token?: string;
  topic?: string;
  pet_id?: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const firebaseServiceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
      return json(500, { error: "Supabase environment is incomplete." });
    }

    if (!firebaseServiceAccountJson) {
      return json(500, { error: "FIREBASE_SERVICE_ACCOUNT_JSON is missing." });
    }

    const body = (await req.json()) as SendPushRequest;
    if (!body.title || !body.body) {
      return json(400, { error: "title and body are required." });
    }

    const targets = [body.token, body.topic, body.pet_id].filter(Boolean);
    if (targets.length !== 1) {
      return json(400, {
        error: "Exactly one target is required: token, topic, or pet_id.",
      });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const apiKeyHeader = req.headers.get("apikey") ?? "";
    const bearer = authHeader.replace(/^Bearer\s+/i, "").trim();

    const isServiceRoleCaller =
      (bearer.length > 0 && bearer === supabaseServiceRoleKey) ||
      apiKeyHeader === supabaseServiceRoleKey;

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    let callerUserId: string | null = null;

    if (!isServiceRoleCaller) {
      if (!authHeader) {
        return json(401, { error: "Missing Authorization header." });
      }

      const userClient = createClient(supabaseUrl, supabaseAnonKey, {
        auth: { persistSession: false, autoRefreshToken: false },
        global: { headers: { Authorization: authHeader } },
      });

      const { data, error } = await userClient.auth.getUser();
      if (error || !data.user) {
        return json(401, { error: "Invalid user token." });
      }
      callerUserId = data.user.id;
    }

    if (body.topic && !isServiceRoleCaller) {
      return json(403, { error: "Only service-role callers can send topic pushes." });
    }

    let tokens: string[] = [];

    if (body.token) {
      if (!isServiceRoleCaller) {
        const { data, error } = await adminClient
          .from("fcm_tokens")
          .select("token")
          .eq("owner_id", callerUserId)
          .eq("token", body.token)
          .maybeSingle();

        if (error || !data) {
          return json(403, { error: "Token does not belong to current user." });
        }
      }
      tokens = [body.token];
    }

    if (body.pet_id) {
      let query = adminClient
        .from("fcm_tokens")
        .select("token")
        .eq("pet_id", body.pet_id);

      if (!isServiceRoleCaller) {
        query = query.eq("owner_id", callerUserId);
      }

      const { data, error } = await query;
      if (error) {
        return json(500, { error: "Failed to resolve pet tokens." });
      }

      tokens = (data ?? []).map((item) => item.token as string).filter(Boolean);
      if (tokens.length === 0) {
        return json(404, { error: "No tokens found for the requested pet_id." });
      }
    }

    const serviceAccount = JSON.parse(firebaseServiceAccountJson) as {
      project_id: string;
      client_email: string;
      private_key: string;
    };

    const projectId = firebaseProjectId ?? serviceAccount.project_id;
    if (!projectId) {
      return json(500, { error: "FIREBASE_PROJECT_ID is missing." });
    }

    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const authClient = await auth.getClient();
    const accessTokenResponse = await authClient.getAccessToken();
    const accessToken =
      typeof accessTokenResponse === "string"
        ? accessTokenResponse
        : accessTokenResponse?.token;

    if (!accessToken) {
      return json(500, { error: "Failed to obtain Firebase access token." });
    }

    const dataPayload: Record<string, string> = Object.fromEntries(
      Object.entries(body.data ?? {}).map(([k, v]) => [k, String(v)]),
    );

    const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    if (body.topic) {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            topic: body.topic,
            notification: {
              title: body.title,
              body: body.body,
            },
            data: dataPayload,
          },
        }),
      });

      const payload = await response.json();
      return json(response.ok ? 200 : response.status, {
        target: "topic",
        topic: body.topic,
        ok: response.ok,
        payload,
      });
    }

    const results: Array<Record<string, unknown>> = [];

    for (const token of tokens) {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: body.title,
              body: body.body,
            },
            data: dataPayload,
          },
        }),
      });

      let payload: unknown = null;
      try {
        payload = await response.json();
      } catch {
        payload = { parse_error: "non-json response" };
      }

      results.push({
        token,
        ok: response.ok,
        status: response.status,
        payload,
      });
    }

    const sent = results.filter((item) => item.ok === true).length;
    const failed = results.length - sent;

    return json(failed === 0 ? 200 : 207, {
      target: body.pet_id ? "pet_id" : "token",
      pet_id: body.pet_id ?? null,
      sent,
      failed,
      results,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json(500, { error: message });
  }
});

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
