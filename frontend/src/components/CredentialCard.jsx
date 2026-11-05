import { QRCodeSVG } from 'qrcode.react';
import { ScanLine } from 'lucide-react';
import { dateLabel } from '../services/domain';
import { verificationURL } from '../services/api';
import { Avatar } from './UI';

export const INSTITUTION = import.meta.env.VITE_INSTITUTION || 'CACAO DEL SUR';

export default function Credential({ worker }) {
  return (
    <div className="credential-pair">
      {/* ANVERSO */}
      <div className="credential-face">
        <div className="credential-header">
          <img src="/assets/logo_cacao.jpg" alt="Logo Cacao del Sur" className="card-header-logo" />
          <span>
            {INSTITUTION}
            <small>IDENTIFICACIÓN OFICIAL DE PERSONAL</small>
          </span>
        </div>
        <div className="credential-front-body">
          <Avatar worker={worker} large />
          <div>
            <span className="credential-label">NOMBRE COMPLETO</span>
            <h3>{worker.nombre_completo}</h3>
            <p>{worker.cargo}</p>
            <strong>{worker.area}</strong>
            <span className="credential-label mt-3">NÚMERO DE TRABAJADOR</span>
            <span className="mono">{worker.numero_trabajador}</span>
          </div>
        </div>
        <div className="credential-footer">
          <span>PERSONAL INSTITUCIONAL</span>
          <span>ANVERSO</span>
        </div>
      </div>

      {/* REVERSO */}
      <div className="credential-face credential-back">
        <div className="credential-back-content">
          <div className="qr-frame">
            <QRCodeSVG value={verificationURL(worker)} size={112} level="M" marginSize={4} />
          </div>
          <div>
            <span className="credential-label">NÚMERO DE TARJETA</span>
            <h3 className="mono">{worker.numero_tarjeta}</h3>
            <span className="credential-label mt-3">VIGENCIA</span>
            <p>
              {dateLabel(worker.fecha_inicio)}
              <br />
              al {dateLabel(worker.fecha_vencimiento)}
            </p>
          </div>
        </div>
        <div className="credential-instructions">
          <ScanLine size={17} />
          <span>
            Escanea para verificar la identidad
            <br />
            y el estado actual de esta credencial en línea.
          </span>
        </div>
        <div className="credential-footer">
          <span>CACAO DEL SUR S.A. DE C.V.</span>
          <span>REVERSO</span>
        </div>
      </div>
    </div>
  );
}
