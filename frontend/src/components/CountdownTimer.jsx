import React, { useState, useEffect } from "react";
import { Clock, AlertTriangle } from "lucide-react";

export default function CountdownTimer({ onTimeout, initialSeconds = 300 }) {
  const [seconds, setSeconds] = useState(initialSeconds);

  useEffect(() => {
    if (seconds <= 0) {
      if (onTimeout) onTimeout();
      return;
    }

    const timer = setInterval(() => {
      setSeconds((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [seconds, onTimeout]);

  const minutes = Math.floor(seconds / 60);
  const remainingSecs = seconds % 60;
  const formattedTime = `${String(minutes).padStart(2, "0")}:${String(remainingSecs).padStart(2, "0")}`;

  // Determinación de color según urgencia
  let bgStyle = "rgba(16, 185, 129, 0.2)";
  let textStyle = "#34d399";
  let borderStyle = "1px solid rgba(52, 211, 153, 0.4)";
  let isUrgent = false;

  if (seconds <= 60) {
    bgStyle = "rgba(239, 68, 68, 0.3)";
    textStyle = "#fca5a5";
    borderStyle = "1px solid #ef4444";
    isUrgent = true;
  } else if (seconds <= 120) {
    bgStyle = "rgba(245, 158, 11, 0.25)";
    textStyle = "#fcd34d";
    borderStyle = "1px solid #f59e0b";
  }

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: "8px",
        background: bgStyle,
        border: borderStyle,
        color: textStyle,
        padding: "6px 16px",
        borderRadius: "20px",
        fontWeight: "700",
        fontSize: "14px",
        boxShadow: isUrgent ? "0 0 12px rgba(239,68,68,0.5)" : "none",
        animation: isUrgent ? "pulseRed 1s infinite" : "none",
      }}
    >
      {isUrgent ? <AlertTriangle size={18} /> : <Clock size={18} />}
      <span>TIEMPO RESTANTE: {formattedTime}</span>
    </div>
  );
}
