import { Suspense } from 'react'; import Dashboard from './Dashboard';
export default function Page(){return <Suspense fallback={<div className="page-wrap">Loading…</div>}><Dashboard/></Suspense>}
