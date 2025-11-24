import './Orb.css';

interface OrbProps {
  hue?: number;
  hoverIntensity?: number;
  rotateOnHover?: boolean;
  forceHoverState?: boolean;
}

export default function Orb({
  hue = 0,
  hoverIntensity = 0.2,
  rotateOnHover = true,
  forceHoverState = false
}: OrbProps) {
  // Placeholder simplificado do Orb
  // TODO: Implementar versão completa com WebGL quando biblioteca estiver disponível
  return (
    <div className="orb-container">
      <div
        className="orb-placeholder"
        style={{
          width: '100%',
          height: '100%',
          background: `radial-gradient(circle,
            hsl(${hue}, 70%, 60%),
            hsl(${hue + 60}, 70%, 50%),
            transparent
          )`,
          filter: 'blur(40px)',
          opacity: forceHoverState ? 0.8 : 0.6,
          transition: 'all 0.3s ease',
        }}
      />
    </div>
  );
}
