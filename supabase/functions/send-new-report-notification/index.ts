import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Report {
  id: number
  reporter_id: string | null
  incident_type: string
  location: string
  description: string
}

// Manual JWT creation for Google service account (same as reply notification)
async function createJWT(serviceAccount: any): Promise<string> {
  const header = {
    alg: "RS256",
    typ: "JWT"
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600, // 1 hour
    iat: now
  }

  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  
  const message = `${headerB64}.${payloadB64}`
  
  // Import private key - handle different formats
  console.log('Original private key length:', serviceAccount.private_key?.length || 'undefined');
  console.log('Original private key starts with:', serviceAccount.private_key?.substring(0, 50) || 'undefined');
  
  if (!serviceAccount.private_key) {
    throw new Error('Private key is missing from service account credentials');
  }
  
  let cleanPrivateKey = serviceAccount.private_key;
  
  // Remove PEM headers and footers
  cleanPrivateKey = cleanPrivateKey.replace(/-----BEGIN PRIVATE KEY-----/g, '');
  cleanPrivateKey = cleanPrivateKey.replace(/-----END PRIVATE KEY-----/g, '');
  
  // Handle different newline formats
  cleanPrivateKey = cleanPrivateKey.replace(/\\n/g, '\n'); // Handle escaped newlines (\n as literal string)
  cleanPrivateKey = cleanPrivateKey.replace(/\r\n/g, '\n'); // Handle Windows line endings
  cleanPrivateKey = cleanPrivateKey.replace(/\r/g, '\n');   // Handle Mac line endings
  cleanPrivateKey = cleanPrivateKey.replace(/\n/g, '');     // Remove all actual newlines
  cleanPrivateKey = cleanPrivateKey.replace(/\s/g, '');     // Remove all whitespace
  
  console.log('Private key length after cleaning:', cleanPrivateKey.length);
  console.log('Private key first 50 chars:', cleanPrivateKey.substring(0, 50));
  console.log('Private key last 50 chars:', cleanPrivateKey.substring(cleanPrivateKey.length - 50));
  
  // Check if it's valid base64
  const base64Regex = /^[A-Za-z0-9+/]*={0,2}$/;
  if (!base64Regex.test(cleanPrivateKey)) {
    console.error('Private key is not valid base64 format');
    console.error('Invalid characters found in private key');
    throw new Error('Private key contains invalid base64 characters');
  }
  
  let privateKeyBytes: Uint8Array;
  try {
    privateKeyBytes = new Uint8Array(atob(cleanPrivateKey).split('').map(c => c.charCodeAt(0)));
    console.log('Successfully decoded private key, byte length:', privateKeyBytes.length);
  } catch (base64Error) {
    console.error('Base64 decode error:', base64Error);
    console.error('Cleaned private key sample (first 100):', cleanPrivateKey.substring(0, 100));
    console.error('Cleaned private key sample (last 100):', cleanPrivateKey.substring(cleanPrivateKey.length - 100));
    throw new Error(`Failed to decode private key base64: ${base64Error.message}`);
  }
  
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyBytes,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  )

  // Sign the message
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    encoder.encode(message)
  )

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  return `${message}.${signatureB64}`
}

// Get access token using JWT
async function getAccessToken(serviceAccount: any): Promise<string> {
  const jwt = await createJWT(serviceAccount)
  
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Failed to get access token: ${error}`)
  }

  const data = await response.json()
  return data.access_token
}

serve(async (req) => {
  try {
    console.log('=== Send New Report Notification Function Started ===')
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let payload: { record: Report }
    let newReport: Report
    
    try {
      const rawBody = await req.text()
      console.log('Raw request body:', rawBody)
      
      if (!rawBody || rawBody.trim() === '') {
        throw new Error('Empty request body')
      }
      
      payload = JSON.parse(rawBody)
      console.log('Parsed payload:', JSON.stringify(payload, null, 2))
      
      newReport = payload.record
      console.log('New report data:', JSON.stringify(newReport, null, 2))
      
      if (!newReport) {
        throw new Error('No record found in payload')
      }
    } catch (parseError) {
      console.error('JSON parsing error:', parseError)
      return new Response(JSON.stringify({ 
        error: `JSON parsing failed: ${parseError.message}` 
      }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      })
    }

    // Ambil semua admin (role = 'tppk')
    const { data: admins, error: adminError } = await supabaseClient
      .from('profiles')
      .select('id, full_name')
      .eq('role', 'tppk')

    if (adminError) throw adminError
    if (!admins || admins.length === 0) {
      return new Response("OK - Tidak ada TPPK ditemukan.")
    }

    // Ambil FCM tokens untuk semua admin
    const adminIds = admins.map(admin => admin.id)
    const { data: tokens, error: tokenError } = await supabaseClient
      .from('notifications')
      .select('fcm_token')
      .in('user_id', adminIds)

    if (tokenError) throw tokenError
    if (!tokens || tokens.length === 0) {
      return new Response("OK - Tidak ada FCM token ditemukan untuk TPPK.")
    }

    const fcmTokens = tokens.map(item => item.fcm_token)

    // Dapatkan kredensial dari Environment Variables yang terpisah
    console.log('Getting Google Service Account credentials from environment variables...')
    
    const credentials = {
      type: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_TYPE") || "service_account",
      project_id: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_PROJECT_ID"),
      private_key_id: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY_ID"),
      private_key: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY"),
      client_email: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL"),
      client_id: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_CLIENT_ID"),
      auth_uri: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_AUTH_URI") || "https://accounts.google.com/o/oauth2/auth",
      token_uri: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_TOKEN_URI") || "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_AUTH_PROVIDER_X509_CERT_URL") || "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_CLIENT_X509_CERT_URL"),
      universe_domain: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_UNIVERSE_DOMAIN") || "googleapis.com"
    }
    
    // Check required fields
    const requiredFields = ['project_id', 'private_key_id', 'private_key', 'client_email', 'client_id', 'client_x509_cert_url']
    const missingFields = requiredFields.filter(field => !credentials[field])
    
    if (missingFields.length > 0) {
      console.error('Missing required service account fields:', missingFields)
      throw new Error(`Missing required service account environment variables: ${missingFields.join(', ')}`)
    }
    
    console.log('Service account credentials loaded successfully')
    console.log('Project ID:', credentials.project_id)
    console.log('Client Email:', credentials.client_email)
    
    const projectId = credentials.project_id;

    // Dapatkan access token
    const accessToken = await getAccessToken(credentials);

    // Tentukan jenis laporan untuk notifikasi
    const reportType = newReport.title || 'Laporan Baru'
    const isAnonymous = !newReport.reporter_id
    
    let reporterInfo = 'dari Anonim'
    if (!isAnonymous) {
      // Ambil nama pelapor
      const { data: reporter, error: reporterError } = await supabaseClient
        .from('profiles')
        .select('full_name')
        .eq('id', newReport.reporter_id)
        .single()
      
      if (!reporterError && reporter?.full_name) {
        reporterInfo = `dari ${reporter.full_name}`
      } else {
        reporterInfo = 'dari Pengguna Teridentifikasi'
      }
    }

    // Kirim notifikasi ke setiap TPPK token satu per satu (FCM v1 tidak support multiple tokens)
    console.log('Sending FCM notifications to', fcmTokens.length, 'TPPK tokens...')
    
    const results = []
    for (const token of fcmTokens) {
      try {
        const notificationPayload = {
          message: {
            token: token,
            notification: {
              title: "📋 Laporan Baru Masuk",
              body: `"${reportType}" ${reporterInfo}`,
            },
            data: {
              'screen': '/admin/kelola-laporan',
              'report_id': newReport.id.toString(),
              'report_type': reportType,
              'is_anonymous': isAnonymous.toString(),
            }
          }
        };

        console.log('Sending to TPPK token:', token.substring(0, 20) + '...')
        
        const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify(notificationPayload),
        });

        if (fcmResponse.ok) {
          const responseBody = await fcmResponse.text()
          console.log('FCM success for TPPK token:', token.substring(0, 20) + '...', responseBody)
          results.push({ token, success: true })
        } else {
          const errorBody = await fcmResponse.text()
          console.error('FCM error for TPPK token:', token.substring(0, 20) + '...', errorBody)
          results.push({ token, success: false, error: errorBody })
        }
      } catch (tokenError) {
        console.error('Error sending to TPPK token:', token.substring(0, 20) + '...', tokenError)
        results.push({ token, success: false, error: tokenError.message })
      }
    }
    
    const successCount = results.filter(r => r.success).length
    console.log(`Notifikasi laporan baru berhasil dikirim ke ${successCount}/${fcmTokens.length} TPPK`)
    return new Response("OK")

  } catch (error) {
    console.error("Error dalam Edge Function:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
}) 