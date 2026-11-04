import {useState,useEffect,useCallback} from 'react';
import {CheckCircle2,X,ArrowLeft} from 'lucide-react';
import ProtectedRoute from '../components/ProtectedRoute';
import Layout from '../components/Layout';
import {Loading,ErrorBox,Empty} from '../components/UI';
import Login from '../pages/LoginView';
import Dashboard from '../pages/DashboardView';
import Workers from '../pages/WorkersView';
import WorkerForm from '../pages/WorkerForm';
import WorkerDetail from '../pages/WorkerDetail';
import Credentials from '../pages/CredentialsView';
import Reports from '../pages/ReportsView';
import Verify from '../pages/PublicVerifyView';
import Scanner from '../pages/ScannerView';
import Settings from '../pages/SettingsView';
import {api} from './api';
function currentRoute(){return window.location.hash.slice(1)||'/';}
function decodedToken(value){try{return decodeURIComponent(value);}catch{return '__invalid_token__';}}
export default function App(){const[path,setPath]=useState(currentRoute),[user,setUser]=useState(null),[authLoading,setAuthLoading]=useState(true),[workers,setWorkers]=useState([]),[loading,setLoading]=useState(false),[error,setError]=useState(''),[toast,setToast]=useState('');
 useEffect(()=>{const listener=()=>{setPath(currentRoute());window.scrollTo(0,0);};window.addEventListener('hashchange',listener);return()=>window.removeEventListener('hashchange',listener);},[]);
 const isPublic=path.startsWith('/verificar/');
 const refresh=useCallback(async()=>{setLoading(true);setError('');try{setWorkers(await api.workers());}catch(e){setError(e.message);if(e.status===401)setUser(null);}finally{setLoading(false);}},[]);
 useEffect(()=>{let active=true;api.me().then(u=>{if(active)setUser(u);}).catch(()=>{if(active)setUser(null);}).finally(()=>{if(active)setAuthLoading(false);});return()=>{active=false;};},[]);
 useEffect(()=>{if(user&&!isPublic)refresh();},[user,refresh,isPublic]);
 useEffect(()=>{if(!toast)return;const t=setTimeout(()=>setToast(''),4500);return()=>clearTimeout(t);},[toast]);
 // Actualiza los estados al regresar a la pestaña y cada minuto, incluidos cambios de fecha.
 useEffect(()=>{if(!user||isPublic)return;const tick=()=>{api.workers().then(setWorkers).catch(()=>{});};const t=setInterval(tick,60000);window.addEventListener('focus',tick);return()=>{clearInterval(t);window.removeEventListener('focus',tick);};},[user,isPublic]);
 if(isPublic)return <Verify token={decodedToken(path.slice('/verificar/'.length))}/>;
 if(authLoading)return <Loading/>;
 if(!user)return <ProtectedRoute user={user} fallback={<Login onLogin={setUser}/>}/>;
 async function logout(){try{await api.logout();setUser(null);window.location.hash='/';}catch(e){setToast(e.message);}}
 async function saved(w){await refresh();window.location.hash=`/trabajadores/${w.id}`;setToast('Información guardada correctamente.');}
 const parts=path.split('/').filter(Boolean);const worker=workers.find(w=>String(w.id)===parts[1]);let content;
 if(loading)content=<Loading/>;
 else if(error)content=<ErrorBox message={error} retry={refresh}/>;
 else if(path==='/')content=<Dashboard workers={workers}/>;
 else if(path==='/trabajadores')content=<Workers workers={workers}/>;
 else if(path==='/trabajadores/nuevo')content=<WorkerForm key="new" onSaved={saved} workers={workers}/>;
 else if(parts[0]==='trabajadores'&&worker&&parts[2]==='editar')content=<WorkerForm key={worker.id} worker={worker} onSaved={saved} workers={workers}/>;
 else if(parts[0]==='trabajadores'&&worker)content=<WorkerDetail worker={worker} onChanged={refresh} notify={setToast}/>;
 else if(path==='/credenciales')content=<Credentials workers={workers}/>;
 else if(path==='/escanear')content=<Scanner/>;
 else if(path==='/reportes')content=<Reports workers={workers}/>;
 else if(path==='/configuracion')content=<Settings reload={refresh} notify={setToast}/>;
 else content=<Empty title="Página no encontrada" text="La página o el trabajador solicitado no está disponible."><a href="#/" className="btn btn-primary"><ArrowLeft size={16}/>Volver al resumen</a></Empty>;
 return <Layout path={path} user={user} onLogout={logout}>{content}{toast&&<div className="toast" role="status"><CheckCircle2 size={19}/><span>{toast}</span><button className="icon-button" aria-label="Cerrar aviso" onClick={()=>setToast('')}><X size={17}/></button></div>}</Layout>;
}
