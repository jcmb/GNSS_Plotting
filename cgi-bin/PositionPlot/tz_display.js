(function () {
  const listeners = [];
  let offsetMinutes = 0;

  function clampMinutes(value) {
    const n = Math.trunc(Number(value));
    if (!Number.isFinite(n)) return 0;
    return Math.max(0, Math.min(59, Math.abs(n)));
  }

  function clampHours(value) {
    const n = Math.trunc(Number(value));
    if (!Number.isFinite(n)) return 0;
    return Math.max(-14, Math.min(14, n));
  }

  function toOffsetMinutes(hours, minutes) {
    const h = clampHours(hours);
    const m = clampMinutes(minutes);
    if (h === 0) {
      return m;
    }
    return h * 60 + (h < 0 ? -m : m);
  }

  function fromOffsetMinutes(total) {
    const sign = total < 0 ? -1 : 1;
    const abs = Math.abs(Math.trunc(total));
    const hours = sign * Math.floor(abs / 60);
    const minutes = abs % 60;
    return { hours, minutes };
  }

  function formatOffsetLabel(totalMinutes) {
    if (totalMinutes === 0) {
      return "UTC+00:00";
    }
    const { hours, minutes } = fromOffsetMinutes(totalMinutes);
    const sign = totalMinutes < 0 ? "-" : "+";
    const absH = Math.abs(hours);
    return "UTC" + sign + String(absH).padStart(2, "0") + ":" + String(minutes).padStart(2, "0");
  }

  function parseOffsetLine(text) {
    const match = String(text || "").match(/^Display TZ offset:\s*([+-]?\d+):(\d{2})\s*$/m);
    if (!match) {
      return null;
    }
    return toOffsetMinutes(Number(match[1]), Number(match[2]));
  }

  function parseUtcTimestamp(text) {
    if (!text || text === "—") return null;
    const raw = String(text).trim();
    const isoMatch = raw.match(/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/);
    if (isoMatch) {
      const parsed = new Date(isoMatch[1] + "T" + isoMatch[2] + "Z");
      return Number.isFinite(parsed.getTime()) ? parsed : null;
    }
    const atsMatch = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4}) (\d{2}:\d{2}:\d{2}(?:\.\d+)?)/);
    if (atsMatch) {
      const month = atsMatch[1].padStart(2, "0");
      const day = atsMatch[2].padStart(2, "0");
      const parsed = new Date(atsMatch[3] + "-" + month + "-" + day + "T" + atsMatch[4] + "Z");
      return Number.isFinite(parsed.getTime()) ? parsed : null;
    }
    return null;
  }

  function formatLocalFromUnix(unixSec) {
    const d = new Date(unixSec * 1000 + offsetMinutes * 60 * 1000);
    const pad = (value) => String(value).padStart(2, "0");
    return pad(d.getUTCFullYear()) + "-" + pad(d.getUTCMonth() + 1) + "-" + pad(d.getUTCDate()) + " "
      + pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds());
  }

  function formatLocalFromUtcText(utcText, fallback) {
    const parsed = parseUtcTimestamp(utcText);
    if (!parsed) return fallback || utcText || "—";
    return formatLocalFromUnix(parsed.getTime() / 1000);
  }

  function formatLocalClock(unixSec) {
    const d = new Date(unixSec * 1000 + offsetMinutes * 60 * 1000);
    const pad = (value) => String(value).padStart(2, "0");
    return pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds());
  }

  function plotDate(unixSec) {
    const displayMs = unixSec * 1000 + offsetMinutes * 60 * 1000;
    const d = new Date(displayMs);
    return new Date(d.getTime() + d.getTimezoneOffset() * 60000);
  }

  function syncPanel() {
    const current = document.getElementById("display-tz-current");
    const hoursInput = document.getElementById("display-tz-hours");
    const minutesInput = document.getElementById("display-tz-minutes");
    const parts = fromOffsetMinutes(offsetMinutes);
    if (current) {
      current.textContent = formatOffsetLabel(offsetMinutes);
    }
    if (hoursInput && document.activeElement !== hoursInput) {
      hoursInput.value = String(parts.hours);
    }
    if (minutesInput && document.activeElement !== minutesInput) {
      minutesInput.value = String(parts.minutes);
    }
  }

  function notifyChange() {
    syncPanel();
    listeners.forEach((fn) => {
      try {
        fn(offsetMinutes);
      } catch (_) {
        /* ignore listener errors */
      }
    });
  }

  function setOffsetMinutes(total) {
    offsetMinutes = Math.trunc(Number(total));
    if (!Number.isFinite(offsetMinutes)) {
      offsetMinutes = 0;
    }
    notifyChange();
  }

  function setOffset(hours, minutes) {
    setOffsetMinutes(toOffsetMinutes(hours, minutes));
  }

  function parseNaiveTimestamp(text) {
    const match = String(text || "").trim().match(/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/);
    if (!match) return null;
    const parsed = new Date(match[1] + "T" + match[2] + "Z");
    return Number.isFinite(parsed.getTime()) ? parsed : null;
  }

  function initFromTimeRange(text) {
    const parsed = parseOffsetLine(text);
    if (parsed !== null) {
      offsetMinutes = parsed;
      syncPanel();
      return;
    }

    const startUtcMatch = String(text || "").match(/^Start UTC:\s*(.+)$/m);
    const startLocalMatch = String(text || "").match(/^Start Local:\s*(.+)$/m);
    if (startUtcMatch && startLocalMatch) {
      const utcDate = parseUtcTimestamp(startUtcMatch[1].trim());
      const localDate = parseNaiveTimestamp(startLocalMatch[1].trim());
      if (utcDate && localDate) {
        const inferred = Math.round((localDate.getTime() - utcDate.getTime()) / 60000);
        if (Number.isFinite(inferred)) {
          offsetMinutes = inferred;
        }
      }
    }
    syncPanel();
  }

  function onChange(fn) {
    if (typeof fn === "function") {
      listeners.push(fn);
    }
  }

  function attachPanelListeners() {
    const hoursInput = document.getElementById("display-tz-hours");
    const minutesInput = document.getElementById("display-tz-minutes");
    if (!hoursInput || !minutesInput || hoursInput.dataset.bound === "1") {
      return;
    }
    hoursInput.dataset.bound = "1";
    minutesInput.dataset.bound = "1";

    const applyInputs = () => {
      setOffset(hoursInput.value, minutesInput.value);
    };

    hoursInput.addEventListener("change", applyInputs);
    minutesInput.addEventListener("change", applyInputs);
    hoursInput.addEventListener("input", syncPanel);
    minutesInput.addEventListener("input", syncPanel);
  }

  window.gnssDisplayTz = {
    getOffsetMinutes: () => offsetMinutes,
    getOffsetLabel: () => formatOffsetLabel(offsetMinutes),
    getLocalColumnLabel: () => "Local Time (" + formatOffsetLabel(offsetMinutes) + ")",
    formatLocalFromUtcText,
    formatLocalClock,
    plotDate,
    initFromTimeRange,
    setOffset,
    setOffsetMinutes,
    onChange,
    attachPanelListeners
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attachPanelListeners);
  } else {
    attachPanelListeners();
  }
})();
