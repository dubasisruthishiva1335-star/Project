const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:4000';

export interface User {
  id: string;
  hallTicket: string;
  fullName: string;
  email?: string;
  role: 'STUDENT' | 'ADMIN' | 'SUPER_ADMIN';
  courseType: string;
  branch: string;
  semester: number;
}

export function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('myvault_token');
}

export function setStoredToken(token: string) {
  if (typeof window !== 'undefined') {
    localStorage.setItem('myvault_token', token);
  }
}

export function getStoredUser(): User | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem('myvault_user');
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function setStoredUser(user: User) {
  if (typeof window !== 'undefined') {
    localStorage.setItem('myvault_user', JSON.stringify(user));
  }
}

export function clearAuth() {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('myvault_token');
    localStorage.removeItem('myvault_user');
  }
}

export async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getStoredToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.message || 'API request failed');
  }

  return data as T;
}
