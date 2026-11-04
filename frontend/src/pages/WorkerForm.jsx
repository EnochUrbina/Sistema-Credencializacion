import {useState, useMemo} from 'react';
import {ArrowLeft, Camera, Save, UserRound, BriefcaseBusiness, ContactRound, ShieldCheck, Check, AlertTriangle, XCircle, Calendar, Lock} from 'lucide-react';
import {PageHeading, ErrorBox, Avatar, Modal} from '../components/UI';
import {AREAS} from '../data/demo';
import {api} from '../services/api';
import {today} from '../services/domain';

export default function WorkerForm({worker, onSaved, workers = []}){
  const isEditing = !!worker;
  const [form, setForm] = useState(worker || {
    nombre_completo: '',
    numero_trabajador: '',
    numero_tarjeta: '',
    edad: '',
    sexo: '',
    curp: '',
    area: '',
    cargo: '',
    fotografia: '',
    emergencia_nombre: '',
    emergencia_telefono: '',
    correo: '',
    fecha_inicio: today(),
    fecha_vencimiento: '',
    activa: true
  });

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  // Helper de actualización directa
  const update = (key, value) => {
    setForm(f => ({ ...f, [key]: value }));
  };

  // --- MÁSCARAS DE ENTRADA EN TIEMPO REAL (Bloqueo al teclear) ---
  const handleNameChange = (key, e) => {
    // Solo letras (con acentos, diéresis, ñ), espacios, puntos y guiones. Bloquea números y símbolos.
    const clean = e.target.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\.\-]/g, '').replace(/\s{2,}/g, ' ');
    update(key, clean);
  };

  const handleCurpChange = (e) => {
    // Convierte a mayúsculas, solo alfanumérico, máximo 18 caracteres. Bloquea espacios y símbolos.
    const clean = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 18);
    update('curp', clean);
  };

  const handleCodeChange = (key, e) => {
    // Alfanumérico, guiones y puntos (sin espacios ni caracteres especiales).
    const clean = e.target.value.toUpperCase().replace(/[^A-Z0-9\-_.]/g, '');
    update(key, clean);
  };

  const handleAgeChange = (e) => {
    // Solo números enteros positivos de hasta 2 dígitos.
    const clean = e.target.value.replace(/\D/g, '').slice(0, 2);
    update('edad', clean);
  };

  const handlePhoneChange = (e) => {
    // Solo números (dígitos), exactamente hasta 10 dígitos obligatorios. Bloquea letras y símbolos.
    const clean = e.target.value.replace(/\D/g, '').slice(0, 10);
    update('emergencia_telefono', clean);
  };

  const handleEmailChange = (e) => {
    // Minúsculas y sin espacios.
    const clean = e.target.value.toLowerCase().replace(/\s/g, '');
    update('correo', clean);
  };

  // --- EVALUACIONES EN TIEMPO REAL (Cálculos en memoria) ---
  const validation = useMemo(() => {
    const v = {};
    const currentId = worker?.id;

    // 1. Nombre completo
    const nombre = (form.nombre_completo || '').trim();
    if (!nombre) {
      v.nombre_completo = { status: 'empty', msg: 'Requerido' };
    } else if (nombre.length < 3) {
      v.nombre_completo = { status: 'warn', msg: `Mínimo 3 caracteres (llevas ${nombre.length})` };
    } else {
      v.nombre_completo = { status: 'ok', msg: 'Nombre válido' };
    }

    // 2. Edad
    if (!form.edad) {
      v.edad = { status: 'empty', msg: 'Requerido' };
    } else {
      const edadNum = Number(form.edad);
      if (edadNum < 18) {
        v.edad = { status: 'error', msg: 'La edad mínima legal es 18 años' };
      } else if (edadNum > 99) {
        v.edad = { status: 'error', msg: 'Rango institucional entre 18 y 99 años' };
      } else {
        v.edad = { status: 'ok', msg: `${edadNum} años` };
      }
    }

    // 3. Sexo
    if (!form.sexo) {
      v.sexo = { status: 'empty', msg: 'Selecciona una opción' };
    } else {
      v.sexo = { status: 'ok', msg: form.sexo };
    }

    // 4. CURP (18 caracteres + RENAPO + Duplicados + Cruce con Sexo/Edad)
    const curp = (form.curp || '').trim().toUpperCase();
    const renapoRegex = /^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$/;
    if (!curp) {
      v.curp = { status: 'empty', msg: '18 caracteres oficiales requeridos' };
    } else if (curp.length < 18) {
      v.curp = { status: 'warn', msg: `Faltan ${18 - curp.length} caracteres para completar la CURP` };
    } else if (!renapoRegex.test(curp)) {
      v.curp = { status: 'error', msg: 'Estructura inválida según estándar oficial de RENAPO' };
    } else {
      // Checar duplicado
      const dupCurp = workers.find(w => String(w.id) !== String(currentId) && (w.curp || '').toUpperCase() === curp);
      if (dupCurp) {
        v.curp = { status: 'error', msg: `Ya registrada para: ${dupCurp.nombre_completo}` };
      } else {
        // Cruce con Sexo
        const curpSexChar = curp[10];
        let sexMismatch = false;
        if (form.sexo === 'Masculino' && curpSexChar !== 'H') sexMismatch = true;
        if (form.sexo === 'Femenino' && curpSexChar !== 'M') sexMismatch = true;

        if (sexMismatch) {
          v.curp = { status: 'warn', msg: `Inconsistencia: Sexo es '${form.sexo}' pero CURP indica '${curpSexChar === 'H' ? 'Hombre' : 'Mujer'}'` };
        } else {
          v.curp = { status: 'ok', msg: 'CURP oficial válida y disponible' };
        }
      }
    }

    // 5. Correo electrónico (Formato + Duplicados)
    const correo = (form.correo || '').trim().toLowerCase();
    const emailRegex = /^[\w\.\+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+$/;
    if (!correo) {
      v.correo = { status: 'empty', msg: 'Requerido para notificaciones institucionales' };
    } else if (!emailRegex.test(correo)) {
      v.correo = { status: 'warn', msg: 'Formato incompleto (ej. usuario@dominio.com)' };
    } else {
      const dupEmail = workers.find(w => String(w.id) !== String(currentId) && (w.correo || '').toLowerCase() === correo);
      if (dupEmail) {
        v.correo = { status: 'error', msg: `Correo en uso por: ${dupEmail.nombre_completo}` };
      } else {
        v.correo = { status: 'ok', msg: 'Correo válido y disponible' };
      }
    }

    // 6. Número de trabajador (Duplicados)
    const numTrab = (form.numero_trabajador || '').trim().toUpperCase();
    if (!numTrab) {
      v.numero_trabajador = { status: 'empty', msg: 'Identificador único requerido' };
    } else if (numTrab.length < 2) {
      v.numero_trabajador = { status: 'warn', msg: 'Mínimo 2 caracteres' };
    } else {
      const dupTrab = workers.find(w => String(w.id) !== String(currentId) && (w.numero_trabajador || '').toUpperCase() === numTrab);
      if (dupTrab) {
        v.numero_trabajador = { status: 'error', msg: `Ya asignado a: ${dupTrab.nombre_completo}` };
      } else {
        v.numero_trabajador = { status: 'ok', msg: 'Número disponible' };
      }
    }

    // 7. Número de tarjeta (Folio único + Duplicados)
    const numTarj = (form.numero_tarjeta || '').trim().toUpperCase();
    if (!numTarj) {
      v.numero_tarjeta = { status: 'empty', msg: 'Folio único de credencial requerido' };
    } else if (numTarj.length < 3) {
      v.numero_tarjeta = { status: 'warn', msg: 'Mínimo 3 caracteres' };
    } else {
      const dupTarj = workers.find(w => String(w.id) !== String(currentId) && (w.numero_tarjeta || '').toUpperCase() === numTarj);
      if (dupTarj) {
        v.numero_tarjeta = { status: 'error', msg: `Ya asignado a: ${dupTarj.nombre_completo}` };
      } else {
        v.numero_tarjeta = { status: 'ok', msg: 'Folio disponible' };
      }
    }

    // 8. Área y Cargo
    v.area = form.area?.trim() ? { status: 'ok', msg: 'Área seleccionada' } : { status: 'empty', msg: 'Requerido' };
    v.cargo = form.cargo?.trim() ? { status: 'ok', msg: 'Cargo registrado' } : { status: 'empty', msg: 'Requerido' };

    // 9. Contacto de emergencia
    const emNom = (form.emergencia_nombre || '').trim();
    if (!emNom) {
      v.emergencia_nombre = { status: 'empty', msg: 'Requerido' };
    } else if (emNom.length < 3) {
      v.emergencia_nombre = { status: 'warn', msg: 'Mínimo 3 caracteres' };
    } else {
      v.emergencia_nombre = { status: 'ok', msg: 'Nombre válido' };
    }

    const emTel = (form.emergencia_telefono || '').trim();
    const telDigits = emTel.replace(/\D/g, '');
    if (!emTel) {
      v.emergencia_telefono = { status: 'empty', msg: 'Requerido (exactamente 10 dígitos)' };
    } else if (telDigits.length < 10) {
      v.emergencia_telefono = { status: 'error', msg: `Faltan ${10 - telDigits.length} dígitos (${telDigits.length}/10 obligatorios)` };
    } else if (telDigits.length > 10) {
      v.emergencia_telefono = { status: 'error', msg: 'Debe contener exactamente 10 dígitos' };
    } else {
      v.emergencia_telefono = { status: 'ok', msg: '10 dígitos completados' };
    }

    // 10. Vigencia
    if (!form.fecha_inicio) {
      v.fecha_inicio = { status: 'empty', msg: 'Fecha requerida' };
    } else {
      v.fecha_inicio = { status: 'ok', msg: form.fecha_inicio };
    }

    if (!form.fecha_vencimiento) {
      v.fecha_vencimiento = { status: 'empty', msg: 'Fecha requerida' };
    } else if (form.fecha_inicio && form.fecha_vencimiento < form.fecha_inicio) {
      v.fecha_vencimiento = { status: 'error', msg: 'El vencimiento no puede ser anterior a la fecha de inicio' };
    } else {
      v.fecha_vencimiento = { status: 'ok', msg: form.fecha_vencimiento };
    }

    // 11. Fotografía
    v.fotografia = form.fotografia ? { status: 'ok', msg: 'Fotografía cargada' } : { status: 'empty', msg: 'Fotografía obligatoria' };

    // Resumen global: ¿Todo válido para guardar?
    const hasErrors = Object.values(v).some(item => item.status === 'error' || item.status === 'empty' || item.status === 'warn');
    v._isValid = !hasErrors;
    return v;
  }, [form, worker, workers]);

  // Asignar vigencia con atajos rápidos (+1 año, +2 años, +3 años)
  const addYearsToVencimiento = (years) => {
    const base = form.fecha_inicio ? new Date(form.fecha_inicio) : new Date();
    base.setFullYear(base.getFullYear() + years);
    const yyyy = base.getFullYear();
    const mm = String(base.getMonth() + 1).padStart(2, '0');
    const dd = String(base.getDate()).padStart(2, '0');
    update('fecha_vencimiento', `${yyyy}-${mm}-${dd}`);
  };

  // Manejo de carga de fotografía
  async function photo(e){
    const file = e.target.files?.[0];
    if (!file) return;
    setError('');
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 5 * 1024 * 1024) {
      setError('Selecciona una fotografía JPEG, PNG o WebP válida de hasta 5 MB.');
      e.target.value = '';
      return;
    }
    try {
      const reader = new FileReader();
      reader.onload = () => update('fotografia', reader.result);
      reader.onerror = () => setError('No se pudo leer el archivo de la fotografía.');
      reader.readAsDataURL(file);
    } catch {
      setError('No se pudo cargar la fotografía.');
    }
  }

  // Paso 1: Validar datos y abrir Modal de Doble Verificación
  async function submit(e){
    e.preventDefault();
    setSubmitAttempted(true);
    setError('');

    if (!validation._isValid) {
      // Buscar el primer error o campo incompleto
      const firstFault = Object.entries(validation).find(([k, v]) => k !== '_isValid' && (v.status === 'error' || v.status === 'warn' || v.status === 'empty'));
      setError(firstFault ? `Atención en ${firstFault[0].replace('_', ' ')}: ${firstFault[1].msg}` : 'Por favor corrige los campos indicados antes de continuar.');
      return;
    }

    // Abre el diálogo de doble verificación institucional
    setShowConfirm(true);
  }

  // Paso 2: Ejecutar el guardado institucional una vez confirmado en el modal
  async function executeSave(){
    setBusy(true);
    try {
      const payload = {
        ...form,
        nombre_completo: form.nombre_completo.trim(),
        numero_trabajador: isEditing ? worker.numero_trabajador : form.numero_trabajador.trim().toUpperCase(),
        numero_tarjeta: form.numero_tarjeta.trim().toUpperCase(),
        curp: form.curp.trim().toUpperCase(),
        correo: form.correo.trim().toLowerCase(),
        area: form.area.trim(),
        cargo: form.cargo.trim(),
        emergencia_nombre: form.emergencia_nombre.trim(),
        emergencia_telefono: form.emergencia_telefono.trim(),
        edad: Number(form.edad)
      };
      const result = await api.save(payload, worker?.id);
      setShowConfirm(false);
      await onSaved(result);
    } catch (e) {
      setError(e.message || 'Error al guardar el trabajador.');
      setShowConfirm(false);
    } finally {
      setBusy(false);
    }
  }

  // Componente inline de feedback en tiempo real
  const Feedback = ({fieldKey}) => {
    const info = validation[fieldKey];
    if (!info) return null;
    if (info.status === 'error') {
      return (
        <span style={{color: '#dc2626', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px', fontWeight: '500'}}>
          <XCircle size={13}/> {info.msg}
        </span>
      );
    }
    if (info.status === 'warn') {
      return (
        <span style={{color: '#d97706', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px', fontWeight: '500'}}>
          <AlertTriangle size={13}/> {info.msg}
        </span>
      );
    }
    if (info.status === 'ok') {
      return (
        <span style={{color: '#16a34a', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px', fontWeight: '500'}}>
          <Check size={13}/> {info.msg}
        </span>
      );
    }
    if (submitAttempted && info.status === 'empty') {
      return (
        <span style={{color: '#dc2626', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px', fontWeight: '500'}}>
          <XCircle size={13}/> Este campo es obligatorio
        </span>
      );
    }
    return null;
  };

  return (
    <>
      <a className="back-link" href={worker ? `#/trabajadores/${worker.id}` : '#/trabajadores'}>
        <ArrowLeft size={17}/> Volver {worker ? 'al expediente' : 'a trabajadores'}
      </a>
      <PageHeading
        title={worker ? 'Editar trabajador' : 'Registrar trabajador'}
        description="El formulario cuenta con filtros por pulsación de tecla y verificaciones en tiempo real para garantizar datos institucionales limpios."
      />

      <form onSubmit={submit} noValidate>
        <div className="form-layout">
          <div className="form-sections">
            {/* Sección 1: Información Personal */}
            <section className="panel form-panel">
              <h2><UserRound size={19}/> Información personal</h2>
              <p className="muted">Las entradas numéricas o símbolos no permitidos se bloquean automáticamente al teclear.</p>
              
              <div className="form-grid">
                {/* Nombre completo */}
                <label>
                  <span>
                    Nombre completo
                    <small style={{marginLeft: '6px', color: '#64748b', fontWeight: 'normal'}}>(solo letras y espacios)</small>
                  </span>
                  <input
                    value={form.nombre_completo}
                    onChange={e => handleNameChange('nombre_completo', e)}
                    maxLength={150}
                    placeholder="Ej. Ana Sofía López Morales"
                    aria-invalid={validation.nombre_completo.status === 'error' || (submitAttempted && validation.nombre_completo.status === 'empty')}
                  />
                  <Feedback fieldKey="nombre_completo"/>
                </label>

                {/* Edad */}
                <label>
                  <span>
                    Edad
                    <small style={{marginLeft: '6px', color: '#64748b', fontWeight: 'normal'}}>(18 a 99 años)</small>
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    value={form.edad}
                    onChange={handleAgeChange}
                    placeholder="18"
                    maxLength={2}
                    aria-invalid={validation.edad.status === 'error' || (submitAttempted && validation.edad.status === 'empty')}
                  />
                  <Feedback fieldKey="edad"/>
                </label>

                {/* Sexo */}
                <label>
                  <span>Sexo</span>
                  <select
                    value={form.sexo}
                    onChange={e => update('sexo', e.target.value)}
                    aria-invalid={submitAttempted && validation.sexo.status === 'empty'}
                  >
                    <option value="">Seleccionar opción...</option>
                    <option value="Femenino">Femenino</option>
                    <option value="Masculino">Masculino</option>
                    <option value="Otro">Otro</option>
                    <option value="Prefiere no indicar">Prefiere no indicar</option>
                  </select>
                  <Feedback fieldKey="sexo"/>
                </label>

                {/* CURP con contador en vivo y protección en edición */}
                <label>
                  <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                    <span>
                      CURP Oficial {isEditing && <span style={{fontSize: '10px', color: '#64748b', fontWeight: 'normal'}}>🔒 (Inmutable)</span>}
                    </span>
                    <span style={{
                      fontSize: '11px',
                      fontWeight: '600',
                      padding: '1px 6px',
                      borderRadius: '4px',
                      background: form.curp.length === 18 ? '#eaf5eb' : '#f1f5f9',
                      color: form.curp.length === 18 ? '#16a34a' : '#64748b'
                    }}>
                      {form.curp.length}/18
                    </span>
                  </div>
                  <input
                    value={form.curp}
                    onChange={handleCurpChange}
                    maxLength={18}
                    placeholder="Ej. LOMA970315MCFRLN01"
                    aria-invalid={validation.curp.status === 'error' || (submitAttempted && validation.curp.status === 'empty')}
                  />
                  <Feedback fieldKey="curp"/>
                </label>

                {/* Correo Electrónico con comprobación de duplicados en tiempo real */}
                <label style={{gridColumn: '1 / -1'}}>
                  <span>Correo electrónico institucional o de contacto</span>
                  <input
                    type="email"
                    value={form.correo}
                    onChange={handleEmailChange}
                    maxLength={120}
                    placeholder="ejemplo@institucion.edu.mx"
                    aria-invalid={validation.correo.status === 'error' || (submitAttempted && validation.correo.status === 'empty')}
                  />
                  <Feedback fieldKey="correo"/>
                </label>
              </div>
            </section>

            {/* Sección 2: Información Laboral */}
            <section className="panel form-panel">
              <h2><BriefcaseBusiness size={19}/> Información laboral</h2>
              <p className="muted">Los identificadores son únicos institucionales y se valida su disponibilidad mientras escribes.</p>

              <div className="form-grid">
                {/* Número de trabajador */}
                <label>
                  <span>
                    Número de trabajador {isEditing ? <span style={{fontSize: '10px', color: '#64748b', fontWeight: 'normal'}}>🔒 (Inmutable)</span> : '(Único)'}
                  </span>
                  <input
                    value={form.numero_trabajador}
                    onChange={e => handleCodeChange('numero_trabajador', e)}
                    maxLength={20}
                    disabled={isEditing}
                    style={isEditing ? {background: '#f8fafc', color: '#475569', cursor: 'not-allowed', borderColor: '#e2e8f0'} : {}}
                    placeholder="Ej. TR-011"
                    aria-invalid={validation.numero_trabajador.status === 'error' || (submitAttempted && validation.numero_trabajador.status === 'empty')}
                  />
                  {isEditing ? (
                    <span style={{color: '#64748b', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px'}}>
                      <Lock size={12}/> Matrícula institucional permanente (inmutable tras el registro).
                    </span>
                  ) : (
                    <Feedback fieldKey="numero_trabajador"/>
                  )}
                </label>

                {/* Número de tarjeta */}
                <label>
                  <span>Número de tarjeta (Folio único)</span>
                  <input
                    value={form.numero_tarjeta}
                    onChange={e => handleCodeChange('numero_tarjeta', e)}
                    maxLength={50}
                    placeholder="Ej. TAR-1011"
                    aria-invalid={validation.numero_tarjeta.status === 'error' || (submitAttempted && validation.numero_tarjeta.status === 'empty')}
                  />
                  <Feedback fieldKey="numero_tarjeta"/>
                </label>

                {/* Área de adscripción */}
                <label>
                  <span>Área de adscripción</span>
                  <input
                    list="areas-list"
                    value={form.area}
                    onChange={e => update('area', e.target.value)}
                    maxLength={100}
                    placeholder="Seleccionar o escribir área"
                    aria-invalid={submitAttempted && validation.area.status === 'empty'}
                  />
                  <datalist id="areas-list">
                    {AREAS.map(a => <option value={a} key={a}/>)}
                    <option value="Sistemas"/>
                    <option value="Recursos Humanos"/>
                    <option value="Administración"/>
                    <option value="Biblioteca"/>
                    <option value="Mantenimiento"/>
                    <option value="Dirección General"/>
                  </datalist>
                  <Feedback fieldKey="area"/>
                </label>

                {/* Cargo */}
                <label>
                  <span>Cargo o puesto</span>
                  <input
                    value={form.cargo}
                    onChange={e => update('cargo', e.target.value)}
                    maxLength={100}
                    placeholder="Ej. Líder de Desarrollo Web"
                    aria-invalid={submitAttempted && validation.cargo.status === 'empty'}
                  />
                  <Feedback fieldKey="cargo"/>
                </label>
              </div>
            </section>

            {/* Sección 3: Contacto de Emergencia */}
            <section className="panel form-panel">
              <h2><ContactRound size={19}/> Contacto de emergencia</h2>
              <p className="muted">Protegido por privacidad institucional: estos datos no son visibles en el portal público del QR.</p>
              
              <div className="form-grid">
                {/* Nombre de contacto */}
                <label>
                  <span>Nombre del contacto</span>
                  <input
                    value={form.emergencia_nombre}
                    onChange={e => handleNameChange('emergencia_nombre', e)}
                    maxLength={150}
                    placeholder="Ej. Roberto López Morales"
                    aria-invalid={validation.emergencia_nombre.status === 'error' || (submitAttempted && validation.emergencia_nombre.status === 'empty')}
                  />
                  <Feedback fieldKey="emergencia_nombre"/>
                </label>

                {/* Teléfono con contador de 10 dígitos obligatorios */}
                <label>
                  <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                    <span>Teléfono de contacto</span>
                    <span style={{
                      fontSize: '11px',
                      fontWeight: '600',
                      padding: '1px 6px',
                      borderRadius: '4px',
                      background: form.emergencia_telefono.replace(/\D/g, '').length === 10 ? '#eaf5eb' : '#fef2f2',
                      color: form.emergencia_telefono.replace(/\D/g, '').length === 10 ? '#16a34a' : '#dc2626'
                    }}>
                      {form.emergencia_telefono.replace(/\D/g, '').length}/10 dígitos
                    </span>
                  </div>
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={form.emergencia_telefono}
                    onChange={handlePhoneChange}
                    maxLength={10}
                    placeholder="10 dígitos numéricos (ej. 9611234567)"
                    aria-invalid={validation.emergencia_telefono.status === 'error' || (submitAttempted && validation.emergencia_telefono.status === 'empty')}
                  />
                  <Feedback fieldKey="emergencia_telefono"/>
                </label>
              </div>
            </section>

            {/* Sección 4: Vigencia */}
            <section className="panel form-panel">
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '10px'}}>
                <h2><ShieldCheck size={19}/> Vigencia de la credencial</h2>
                <div style={{display: 'flex', gap: '6px', flexWrap: 'wrap', alignItems: 'center'}}>
                  <span style={{fontSize: '11px', color: '#64748b', alignSelf: 'center'}}>Vigencia rápida:</span>
                  <button type="button" className="btn btn-secondary" style={{padding: '3px 8px', fontSize: '11px'}} onClick={() => addYearsToVencimiento(1)}>+1 Año</button>
                  <button type="button" className="btn btn-secondary" style={{padding: '3px 8px', fontSize: '11px'}} onClick={() => addYearsToVencimiento(2)}>+2 Años</button>
                  <button type="button" className="btn btn-secondary" style={{padding: '3px 8px', fontSize: '11px'}} onClick={() => addYearsToVencimiento(3)}>+3 Años</button>
                </div>
              </div>

              <div className="form-grid" style={{marginTop: '14px'}}>
                <label>
                  <span>Fecha de inicio</span>
                  <input
                    type="date"
                    min="2000-01-01"
                    max="2050-12-31"
                    value={form.fecha_inicio}
                    onChange={e => update('fecha_inicio', e.target.value)}
                    aria-invalid={submitAttempted && validation.fecha_inicio.status === 'empty'}
                  />
                  <Feedback fieldKey="fecha_inicio"/>
                </label>

                <label>
                  <span>Fecha de vencimiento</span>
                  <input
                    type="date"
                    min={form.fecha_inicio || "2000-01-01"}
                    max="2050-12-31"
                    value={form.fecha_vencimiento}
                    onChange={e => update('fecha_vencimiento', e.target.value)}
                    aria-invalid={validation.fecha_vencimiento.status === 'error' || (submitAttempted && validation.fecha_vencimiento.status === 'empty')}
                  />
                  <Feedback fieldKey="fecha_vencimiento"/>
                </label>
              </div>

              <label className="checkbox-label" style={{marginTop: '14px'}}>
                <input
                  type="checkbox"
                  checked={form.activa}
                  onChange={e => update('activa', e.target.checked)}
                />
                Credencial activa para emisión
              </label>
              <p className="footnote">El estado operativo final (Vigente, Inactiva o Vencida) es calculado dinámicamente por la base de datos comparando estas fechas con el día de hoy.</p>
            </section>
          </div>

          {/* Barra Lateral: Fotografía y Resumen en vivo */}
          <aside>
            <section className="panel photo-panel">
              <h2>Fotografía del trabajador</h2>
              <div className="photo-preview">
                {form.fotografia ? (
                  <Avatar worker={form} large/>
                ) : (
                  <div className="photo-placeholder">
                    <Camera size={36}/>
                    <span>Fotografía individual</span>
                  </div>
                )}
              </div>
              <label className="btn btn-secondary upload-button">
                <Camera size={16}/>
                {form.fotografia ? 'Cambiar fotografía' : 'Cargar fotografía'}
                <input
                  className="sr-only"
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  onChange={photo}
                />
              </label>
              <Feedback fieldKey="fotografia"/>
              <p className="footnote">Formatos permitidos: JPEG, PNG o WebP · Máximo 5 MB<br/>Rostro visible, de frente y con buena iluminación.</p>
            </section>

            <div className="info-card">
              <ShieldCheck size={22} style={{color: validation._isValid ? '#16a34a' : '#315c87'}}/>
              <h3>Estado del formulario</h3>
              <p style={{fontSize: '12px', marginTop: '6px', lineHeight: '1.5'}}>
                {validation._isValid ? (
                  <span style={{color: '#16a34a', fontWeight: '600'}}>
                    ✓ Todos los datos han sido verificados y son válidos para registrar la credencial.
                  </span>
                ) : (
                  <span style={{color: '#64748b'}}>
                    El formulario valida instantáneamente formato de CURP, unicidad de folio, correspondencia de sexo y 10 dígitos telefónicos.
                  </span>
                )}
              </p>
            </div>
          </aside>
        </div>

        {error && <ErrorBox message={error}/>}

        <div className="form-actions">
          <a className="btn btn-secondary" href={worker ? `#/trabajadores/${worker.id}` : '#/trabajadores'}>
            Cancelar
          </a>
          <button className="btn btn-primary" disabled={busy}>
            <Save size={17}/> {busy ? 'Guardando…' : worker ? 'Guardar cambios' : 'Registrar y generar credencial'}
          </button>
        </div>
      </form>

      {/* MODAL DE DOBLE VERIFICACIÓN INSTITUCIONAL */}
      {showConfirm && (
        <Modal
          title={isEditing ? 'Doble verificación de actualización' : 'Doble verificación de registro'}
          onClose={() => !busy && setShowConfirm(false)}
        >
          <div style={{display: 'flex', flexDirection: 'column', gap: '14px'}}>
            <p className="muted" style={{fontSize: '12px', margin: 0, lineHeight: '1.5'}}>
              {isEditing
                ? 'Por seguridad institucional y cumplimiento de la normativa, revisa minuciosamente los datos antes de guardarlos en el expediente.'
                : 'Verifica los datos capturados antes de emitir la credencial oficial y dar de alta al trabajador en la institución.'}
            </p>

            <div style={{background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '8px', padding: '12px', fontSize: '12px', display: 'flex', flexDirection: 'column', gap: '8px'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>Trabajador:</span>
                <strong style={{color: '#1e293b'}}>{form.nombre_completo}</strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>Número de Trabajador:</span>
                <strong style={{fontFamily: 'monospace', color: '#1e293b'}}>
                  {isEditing ? worker.numero_trabajador : form.numero_trabajador} {isEditing && <span style={{fontSize: '10px', color: '#64748b', fontWeight: 'normal'}}>🔒 (Inmutable)</span>}
                </strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>Folio de Tarjeta:</span>
                <strong style={{fontFamily: 'monospace', color: '#1e293b'}}>
                  {form.numero_tarjeta}
                </strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>CURP oficial:</span>
                <strong style={{fontFamily: 'monospace', color: '#1e293b'}}>
                  {form.curp}
                </strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>Área y Cargo:</span>
                <strong style={{color: '#1e293b'}}>{form.cargo} · {form.area}</strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '6px'}}>
                <span style={{color: '#64748b'}}>Vigencia asignada:</span>
                <strong style={{color: '#16a34a'}}>{form.fecha_inicio} al {form.fecha_vencimiento}</strong>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between'}}>
                <span style={{color: '#64748b'}}>Notificaciones a:</span>
                <span style={{color: '#2563eb', fontWeight: '500'}}>{form.correo}</span>
              </div>
            </div>

            {/* Alerta si cambió el folio de tarjeta */}
            {isEditing && worker.numero_tarjeta !== form.numero_tarjeta && (
              <div style={{background: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: '8px', padding: '10px 12px', fontSize: '11px', color: '#166534', display: 'flex', gap: '8px', alignItems: 'flex-start'}}>
                <span>💳</span>
                <span>
                  <strong>Reposición física de credencial:</strong> El folio de tarjeta se actualizará de <code>{worker.numero_tarjeta}</code> a <code>{form.numero_tarjeta}</code>.
                </span>
              </div>
            )}

            {/* Alerta si cambió la CURP */}
            {isEditing && worker.curp !== form.curp && (
              <div style={{background: '#faf5ff', border: '1px solid #e9d5ff', borderRadius: '8px', padding: '10px 12px', fontSize: '11px', color: '#6b21a8', display: 'flex', gap: '8px', alignItems: 'flex-start'}}>
                <span>🆔</span>
                <span>
                  <strong>Corrección de CURP:</strong> La clave oficial de RENAPO se actualizará de <code>{worker.curp}</code> a <code>{form.curp}</code>.
                </span>
              </div>
            )}

            {/* Alerta de notificación si cambió la vigencia */}
            {isEditing && worker.fecha_vencimiento !== form.fecha_vencimiento && (
              <div style={{background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: '8px', padding: '10px 12px', fontSize: '11px', color: '#1e40af', display: 'flex', gap: '8px', alignItems: 'flex-start'}}>
                <span>📧</span>
                <span>
                  <strong>Aviso de auditoría:</strong> La fecha de vencimiento cambiará de <code>{worker.fecha_vencimiento}</code> a <code>{form.fecha_vencimiento}</code>. Al confirmar, el sistema enviará un correo institucional automático de actualización al trabajador.
                </span>
              </div>
            )}

            {/* Aviso de inmutabilidad en edición */}
            {isEditing && (
              <div style={{background: '#fefce8', border: '1px solid #fef08a', borderRadius: '8px', padding: '8px 12px', fontSize: '11px', color: '#854d0e', display: 'flex', gap: '8px', alignItems: 'center'}}>
                <span>🔒</span>
                <span>La matrícula de trabajador (número de trabajador) se mantiene protegida e inalterable.</span>
              </div>
            )}

            <div className="modal-actions" style={{marginTop: '10px', display: 'flex', justifyContent: 'flex-end', gap: '10px'}}>
              <button
                type="button"
                className="btn btn-secondary"
                disabled={busy}
                onClick={() => setShowConfirm(false)}
              >
                Volver a revisar
              </button>
              <button
                type="button"
                className="btn btn-primary"
                disabled={busy}
                onClick={executeSave}
              >
                {busy ? 'Guardando…' : isEditing ? 'Confirmar y aplicar cambios' : 'Confirmar y registrar'}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </>
  );
}
