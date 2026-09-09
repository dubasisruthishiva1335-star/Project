// lib/uploads-store.ts
// Multi-layer persistent storage helper for MyVault Admin

export interface PersistedAsset {
  id: string;
  hubType: "NOTE" | "COMPETITIVE_EXAM" | "COURSE" | "INTERNSHIP";
  hubLabel: string;
  title: string;
  subtitle: string;
  category: string;
  formatOrType: string;
  fileUrl?: string;
  externalUrl?: string;
  fileSize?: string;
  authorOrCompany?: string;
  uploadedAt: string;
  badgeColor: string;
  extraMeta?: string;
  rawItem?: any;
}

const STORAGE_KEY = "myvault_master_uploads_v2";

export function getPersistedUploads(): PersistedAsset[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

export function savePersistedUpload(asset: PersistedAsset): void {
  if (typeof window === "undefined" || !asset || !asset.id) return;
  try {
    const current = getPersistedUploads();
    const filtered = current.filter(item => item.id !== asset.id && !(item.title === asset.title && item.hubType === asset.hubType));
    const updated = [asset, ...filtered];
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
  } catch (err) {
    console.warn("Failed to persist upload to localStorage:", err);
  }
}

export function removePersistedUpload(id: string): void {
  if (typeof window === "undefined" || !id) return;
  try {
    const current = getPersistedUploads();
    const updated = current.filter(item => item.id !== id);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
  } catch (err) {
    console.warn("Failed to remove upload from localStorage:", err);
  }
}
