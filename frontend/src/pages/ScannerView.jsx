import {useEffect,useRef,useState} from 'react';
import jsQR from 'jsqr';
import {PageHeading,ErrorBox} from '../components/UI';
import {credentialToken} from '../services/qr';
export default function Scanner(){
 const video=useRef(null),stream=useRef(null),frame=useRef(null),generation=useRef(0);
 const [error,setError]=useState(''),[active,setActive]=useState(false),[value,setValue]=useState('');
 function stop(){generation.current++;cancelAnimationFrame(frame.current);stream.current?.getTracks().forEach(t=>t.stop());stream.current=null;setActive(false);}
 useEffect(()=>{start();return()=>{generation.current++;cancelAnimationFrame(frame.current);stream.current?.getTracks().forEach(t=>t.stop());};},[]);
 function open(raw){const token=credentialToken(raw);stop();window.location.hash='/verificar/'+token;}
 function pixels(source,w,h){const canvas=document.createElement('canvas');canvas.width=w;canvas.height=h;const ctx=canvas.getContext('2d',{willReadFrequently:true});ctx.drawImage(source,0,0,w,h);const data=ctx.getImageData(0,0,w,h);return jsQR(data.data,w,h,{inversionAttempts:'attemptBoth'})?.data;}
 async function start(){stop();setError('');const gen=generation.current;try{
  if(!navigator.mediaDevices?.getUserMedia)throw Error('Abre el sistema mediante HTTPS y permite el acceso a la cámara. También puedes cargar una imagen del QR.');
  const media=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'}},audio:false});
  if(gen!==generation.current){media.getTracks().forEach(t=>t.stop());return;}
  stream.current=media;video.current.srcObject=media;await video.current.play();setActive(true);
  const tick=()=>{if(gen!==generation.current)return;try{const v=video.current;if(v?.readyState>=2){const width=Math.min(v.videoWidth,900),height=Math.round(v.videoHeight*width/v.videoWidth);const code=pixels(v,width,height);if(code){open(code);return;}}}catch(e){setError(e.message);stop();return;}frame.current=requestAnimationFrame(tick);};tick();
 }catch(e){stop();setError(e.name==='NotAllowedError'?'Permite el acceso a la cámara o carga una imagen.':e.message);}}
 async function image(e){stop();setError('');const file=e.target.files?.[0];if(!file)return;try{if(file.size>10*1024*1024)throw Error('La imagen debe pesar menos de 10 MB.');const bmp=await createImageBitmap(file);const scale=Math.min(1,1600/Math.max(bmp.width,bmp.height));const code=pixels(bmp,Math.round(bmp.width*scale),Math.round(bmp.height*scale));bmp.close();if(!code)throw Error('No se detectó un QR. Usa una imagen clara del código completo.');open(code);}catch(e){setError(e.message);}finally{e.target.value='';}}
 return <><PageHeading title="Escanear código" description="Permite el acceso a la cámara y enfoca el QR de la credencial."/><section className="panel settings-panel">{error&&<ErrorBox message={error}/>}<video ref={video} muted playsInline style={{width:'100%',maxWidth:560,background:'#111',borderRadius:8}}/><div className="modal-actions"><button className="btn btn-primary" onClick={start} disabled={active}>Abrir cámara</button><button className="btn btn-secondary" onClick={stop} disabled={!active}>Detener cámara</button></div><label>Cargar imagen del QR<input type="file" accept="image/*" onChange={image}/></label><form onSubmit={e=>{e.preventDefault();try{open(value);}catch(err){setError(err.message);}}}><label>O pega el enlace o identificador de la credencial<input value={value} onChange={e=>setValue(e.target.value)} required/></label><button className="btn btn-secondary">Consultar credencial</button></form><p>La consulta pública muestra nombre, fotografía, datos laborales y vigencia. CURP y contactos de emergencia quedan en el expediente administrativo.</p></section></>;
}
