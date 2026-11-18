import { NextRequest, NextResponse } from "next/server";

const flutterProductionOrigin = "https://wonderlaguestuser.vercel.app";

function allowedOrigin(origin: string | null): origin is string {
  if (!origin) return false;
  const configuredOrigin = process.env.FLUTTER_WEB_ORIGIN;
  if (origin === (configuredOrigin || flutterProductionOrigin)) return true;

  // Flutter's local Chrome debug port changes unless --web-port is specified.
  return (
    process.env.NODE_ENV !== "production" &&
    /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin)
  );
}

function addCorsHeaders(response: NextResponse, origin: string) {
  response.headers.set("Access-Control-Allow-Origin", origin);
  response.headers.set("Access-Control-Allow-Credentials", "true");
  response.headers.set(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  );
  response.headers.set("Access-Control-Allow-Headers", "Content-Type, Accept");
  response.headers.set("Access-Control-Max-Age", "600");
  response.headers.append("Vary", "Origin");
  return response;
}

export function middleware(request: NextRequest) {
  const origin = request.headers.get("origin");
  if (request.method === "OPTIONS") {
    if (!allowedOrigin(origin)) return new NextResponse(null, { status: 403 });
    return addCorsHeaders(new NextResponse(null, { status: 204 }), origin);
  }

  const response = NextResponse.next();
  return allowedOrigin(origin) ? addCorsHeaders(response, origin) : response;
}

export const config = { matcher: "/qr-code/api/:path*" };
