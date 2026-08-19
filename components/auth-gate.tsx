'use client';
import {useEffect,useState} from 'react'; import {useRouter} from 'next/navigation'; import {me,getStoredUser} from '../lib/api';
export function AuthGate({children}:{children:React.ReactNode}){const r=useRouter();const [ready,setReady]=useState(false);useEffect(()=>{let ok=!!localStorage.getItem('irkop.jwt')||!!getStoredUser(); if(!ok){r.replace('/login');return} me().catch(()=>r.replace('/login')).finally(()=>setReady(true))},[r]); if(!ready)return <div className="grid min-h-[60vh] place-items-center text-sm text-slate-500">Memeriksa sesi…</div>; return <>{children}</>}
