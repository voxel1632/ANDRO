'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
export function AccountMenu() { const [email,setEmail]=useState<string|null>(null); useEffect(()=>{supabase.auth.getSession().then(({data})=>setEmail(data.session?.user.email??null)); const {data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>setEmail(s?.user.email??null)); return()=>subscription.unsubscribe();},[]); async function logout(){await supabase.auth.signOut(); location.href='/';} return email?<div className="account"><span>{email}</span><button className="link-button" onClick={logout}>Sign out</button></div>:<Link className="button small" href="/login">Sign in</Link>; }
