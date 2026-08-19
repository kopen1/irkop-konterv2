export const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || (typeof window !== 'undefined' ? window.location.origin : 'https://api.irkop.workers.dev')).replace(/\/$/, '');
export const API_PREFIX = (process.env.NEXT_PUBLIC_API_PREFIX || (typeof window !== 'undefined' ? '/api/irkop/v1/konter' : '/v1/konter')).replace(/\/$/, '');

export type ApiRequest = { method?: string; body?: unknown; query?: Record<string,string|number|boolean|undefined>; signal?: AbortSignal };

function token(){ if(typeof window==='undefined') return null; return localStorage.getItem('irkop.jwt'); }
export function setToken(value:string|null){ if(typeof window==='undefined') return; if(value) localStorage.setItem('irkop.jwt',value); else localStorage.removeItem('irkop.jwt'); }
export function getStoredUser<T=any>():T|null{ if(typeof window==='undefined') return null; try{return JSON.parse(localStorage.getItem('irkop.user')||'null')}catch{return null} }
export function setStoredUser(value:unknown|null){ if(typeof window==='undefined') return; if(value) localStorage.setItem('irkop.user',JSON.stringify(value)); else localStorage.removeItem('irkop.user'); }

function extractPayload(json:any){ return json?.data ?? json?.result ?? json; }
function extractToken(json:any){ const p=extractPayload(json); return p?.token || p?.access_token || p?.jwt || json?.token || json?.access_token || null; }

export async function apiFetch<T=any>(path:string, opts:ApiRequest={}):Promise<T>{
  const url=new URL(`${API_BASE}${API_PREFIX}${path.startsWith('/')?path:`/${path}`}`);
  Object.entries(opts.query||{}).forEach(([k,v])=>{if(v!==undefined) url.searchParams.set(k,String(v));});
  const headers:Record<string,string>={Accept:'application/json'};
  const t=token(); if(t) headers.Authorization=`Bearer ${t}`;
  if(opts.body!==undefined) headers['Content-Type']='application/json';
  const res=await fetch(url.toString(),{method:opts.method||'GET',headers,body:opts.body===undefined?undefined:JSON.stringify(opts.body),signal:opts.signal,cache:'no-store'});
  const text=await res.text(); let json:any=null; try{json=text?JSON.parse(text):null}catch{json={message:text}};
  if(!res.ok){ if(res.status===401){setToken(null);setStoredUser(null)} const msg=json?.message||json?.error?.message||json?.error||`HTTP ${res.status}`; throw new Error(String(msg)); }
  return json as T;
}

export async function login(email:string,password:string){
  const json:any=await apiFetch('/auth/login',{method:'POST',body:{email,password}});
  const jwt=extractToken(json); if(jwt) setToken(jwt);
  const user=extractPayload(json)?.user || extractPayload(json)?.account || extractPayload(json);
  if(user) setStoredUser(user);
  return {json,token:jwt,user};
}
export async function logout(){ try{await apiFetch('/auth/logout',{method:'POST'});}catch{} finally{setToken(null);setStoredUser(null)} }
export async function me(){ const json:any=await apiFetch('/auth/me'); const user=extractPayload(json)?.user || extractPayload(json); if(user) setStoredUser(user); return user; }

export const resources={
  dashboard:'/dashboard/summary', transactions:'/transaksi', todayTransactions:'/transaksi/hari-ini',
  cashier:'/kasir/sesi', reports:'/laporan', products:'/barang', categories:'/barang/kategori',
  services:'/service', serviceReports:'/service/laporan', kasbon:'/kasbon/profil', customers:'/pelanggan',
  expenses:'/pengeluaran', employees:'/karyawan', users:'/pengaturan/user', roles:'/pengaturan/role',
  accounts:'/pengaturan/master-akun', audit:'/pengaturan/audit-log', notifSources:'/notifhook/sumber', notifStatus:'/notifhook/status'
} as const;

export async function listResource(path:string,query?:ApiRequest['query']){return apiFetch(path,{query});}
export async function createResource(path:string,body:unknown){return apiFetch(path,{method:'POST',body});}
export async function updateResource(path:string,body:unknown){return apiFetch(path,{method:'PUT',body});}
export async function deleteResource(path:string){return apiFetch(path,{method:'DELETE'});}
