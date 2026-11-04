export function credentialToken(raw){
 const text=String(raw||'').trim();
 const match=text.match(/^(?:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/i);
 if(match)return text.toLowerCase();
 let url;try{url=new URL(text);}catch{throw Error('El código no corresponde a una credencial.');}
 if(!['http:','https:'].includes(url.protocol))throw Error('Enlace de credencial inválido.');
 const token=url.hash.match(/^#\/verificar\/([0-9a-f-]{36})$/i)?.[1]||url.pathname.match(/^\/api\/verificar\/([0-9a-f-]{36})$/i)?.[1];
 if(!token)throw Error('El QR no pertenece al sistema de credenciales.');
 return credentialToken(token);
}
