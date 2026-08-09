// Redirects to the backend's APK route (see backend README — Render serves
// the built APK from public/ at GET /download-apk).
import { redirect } from "next/navigation";

export default function DownloadApkPage() {
  redirect("/myvault-app.apk");
}
