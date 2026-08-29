function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function tableHtml(headers, rows, className) {
  const cls = className ? ' class="' + className + '"' : "";
  let html = "<table" + cls + "><thead><tr>";
  headers.forEach((h, i) => {
    const align = i > 0 ? ' class="num"' : "";
    html += "<th" + align + ">" + escapeHtml(h) + "</th>";
  });
  html += "</tr></thead><tbody>";
  rows.forEach((row) => {
    html += "<tr>";
    row.forEach((cell, i) => {
      const align = i > 0 ? ' class="num"' : "";
      html += "<td" + align + ">" + escapeHtml(cell) + "</td>";
    });
    html += "</tr>";
  });
  html += "</tbody></table>";
  return html;
}

function sectionHtml(title, bodyHtml, sectionId) {
  const idAttr = sectionId ? ' id="' + escapeHtml(sectionId) + '"' : "";
  return "<section" + idAttr + ' class="report-section"><h3>' + escapeHtml(title) + "</h3>" + bodyHtml + "</section>";
}

function parseKeyValueLines(text) {
  const rows = [];
  text.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || /^=+$/.test(trimmed)) return;
    const match = trimmed.match(/^([^:]+):\s*(.+)$/);
    if (match) {
      rows.push([match[1].trim(), match[2].trim()]);
    }
  });
  return rows;
}

function renderKeyValueTable(text, headers) {
  const rows = parseKeyValueLines(text);
  if (!rows.length) return '<p class="report-empty">No data.</p>';
  return tableHtml(headers || ["Item", "Value"], rows, "report-table");
}

function renderMeanInfo(text) {
  const rows = parseKeyValueLines(text);
  if (!rows.length) return "";
  return sectionHtml("Mean / Reference", tableHtml(["Setting", "Value"], rows, "report-table"));
}

function renderTimeRange(text) {
  const kv = {};
  parseKeyValueLines(text).forEach(([key, value]) => {
    kv[key] = value;
  });
  if (!kv["Start GPS"] && !kv["End GPS"]) return "";

  const tz = window.gnssDisplayTz;
  const formatLocal = (utcText, fallback) => (
    tz ? tz.formatLocalFromUtcText(utcText, fallback) : (fallback || utcText || "—")
  );
  const localHeader = tz ? tz.getLocalColumnLabel() : "Local Time";

  const hasAts = !!(kv["ATS Start UTC"] || kv["ATS End UTC"]);
  const gnssStartLabel = hasAts ? "Start (GNSS)" : "Start";
  const gnssEndLabel = hasAts ? "End (GNSS)" : "End";

  const rows = [
    [
      gnssStartLabel,
      kv["Start GPS"] || "—",
      kv["Start UTC"] || "—",
      formatLocal(kv["Start UTC"], kv["Start Local"])
    ],
    [
      gnssEndLabel,
      kv["End GPS"] || "—",
      kv["End UTC"] || "—",
      formatLocal(kv["End UTC"], kv["End Local"])
    ]
  ];

  if (hasAts) {
    rows.push([
      "Start (ATS)",
      "—",
      kv["ATS Start UTC"] || "—",
      formatLocal(kv["ATS Start UTC"], kv["ATS Start Local"])
    ]);
    rows.push([
      "End (ATS)",
      "—",
      kv["ATS End UTC"] || "—",
      formatLocal(kv["ATS End UTC"], kv["ATS End Local"])
    ]);
  }

  return sectionHtml(
    "Session Time Range",
    tableHtml(["", "GPS", "UTC", localHeader], rows, "report-table"),
    "session-time-range-section"
  );
}

function normalizeReferenceRow(name, decimal, dms, std) {
  if (name !== "Height") {
    return [name, decimal || "—", dms || "—", std || "n/a"];
  }

  let dec = String(decimal || "").trim();
  let dmsVal = String(dms || "").trim();
  const stdVal = String(std || "").trim() || "n/a";

  if (!dec || dec === "—") {
    return [name, "—", dmsVal || "—", stdVal];
  }

  if (/ m$/i.test(dec)) {
    dec = dec.replace(/\s*m$/i, "").trim();
  }

  if (!dmsVal || dmsVal === "—") {
    dmsVal = dec + " m";
  } else if (!/ m$/i.test(dmsVal)) {
    dmsVal = dmsVal + " m";
  }

  return [name, dec, dmsVal, stdVal];
}

function parseReferenceTable(text) {
  const rows = [];
  const seen = new Set();
  let inTable = false;
  text.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim();
    if (trimmed === "REFERENCE_TABLE") {
      inTable = true;
      return;
    }
    if (trimmed === "END_REFERENCE_TABLE") {
      inTable = false;
      return;
    }
    if (!inTable || !trimmed) return;

    const firstPipe = trimmed.indexOf("|");
    if (firstPipe < 0) return;

    const name = trimmed.slice(0, firstPipe).trim();
    if (!name || seen.has(name)) return;
    seen.add(name);

    const fields = trimmed.slice(firstPipe + 1).split("|").map((part) => part.trim());
    if (!fields.length) return;

    let decimal = fields[0] || "";
    let dms = "";
    let std = "n/a";

    if (name === "Height") {
      if (fields.length >= 3) {
        dms = fields[1] || "";
        std = fields[2] || "n/a";
      } else if (fields.length === 2) {
        const second = fields[1] || "";
        if (/ m$/i.test(second) || /^-?[\d.]+$/.test(second) && Number(second) > 100) {
          dms = second;
        } else {
          dms = "";
          std = second || "n/a";
        }
      }
    } else if (fields.length >= 3) {
      dms = fields[1] || "";
      std = fields[2] || "n/a";
    } else if (fields.length === 2) {
      dms = fields[1] || "";
    }

    rows.push(normalizeReferenceRow(name, decimal, dms, std));
  });
  return rows;
}

function parseReferenceCoords(text) {
  const rows = parseReferenceTable(text);
  let lat = NaN;
  let lon = NaN;
  let height = NaN;

  if (rows.length) {
    rows.forEach(([name, decimal]) => {
      if (name === "Latitude") lat = parseFloat(decimal);
      else if (name === "Longitude") lon = parseFloat(decimal);
      else if (name === "Height") {
        const match = String(decimal).match(/(-?[\d.]+)/);
        height = match ? parseFloat(match[1]) : NaN;
      }
    });
  } else {
    let section = "";
    text.split(/\r?\n/).forEach((line) => {
      const trimmed = line.trim();
      if (/^Decimal degrees:/i.test(trimmed)) {
        section = "decimal";
        return;
      }
      if (!/^[^:]+:\s*.+$/.test(trimmed) || section !== "decimal") return;
      const kv = trimmed.match(/^([^:]+):\s*(.+)$/);
      if (!kv) return;
      const name = kv[1].trim();
      const value = kv[2].trim();
      if (name === "Latitude") lat = parseFloat(value);
      else if (name === "Longitude") lon = parseFloat(value);
      else if (name === "Height") height = parseFloat(value);
    });
  }

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return null;
  return {
    lat,
    lon,
    height: Number.isFinite(height) ? height : null
  };
}

function osmEmbedUrl(lat, lon) {
  const latPad = 0.015;
  const lonPad = 0.015 / Math.max(0.3, Math.cos((lat * Math.PI) / 180));
  const bbox = [lon - lonPad, lat - latPad, lon + lonPad, lat + latPad]
    .map((value) => value.toFixed(6))
    .join("%2C");
  const marker = encodeURIComponent(lat.toFixed(6) + "," + lon.toFixed(6));
  return "https://www.openstreetmap.org/export/embed.html?bbox=" + bbox +
    "&layer=mapnik&marker=" + marker;
}

function gpsJamUrl(lat, lon) {
  return "https://gpsjam.org/?lat=" + lat.toFixed(5) + "&lon=" + lon.toFixed(5) + "&z=8.0";
}

function parsePlotFilterFlags(text) {
  const flags = { truth: false };
  text.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim();
    if (trimmed.startsWith("truth:")) {
      flags.truth = trimmed.slice(6).trim() === "yes";
    }
  });
  return flags;
}

function parseSessionType(text) {
  const kv = {};
  parseKeyValueLines(text).forEach(([key, value]) => {
    kv[key] = value;
  });
  return kv;
}

function parsePlotFilterSession(text) {
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (trimmed.startsWith("session:")) {
      return trimmed.slice(8).trim();
    }
  }
  return "static";
}

function sessionRequestLabel(value) {
  if (value === "Automatic" || value === "-1" || value === "") return "Automatic";
  if (value === "Static" || value === "0") return "Static";
  if (value === "Moving" || value === "1") return "Moving";
  return value || "Automatic";
}

function parseAtsFilename(line) {
  const match = String(line || "").match(/\(([^)]+)\)/);
  return match ? match[1].trim() : "";
}

function parseAtsTruthStatus(sessionKv, plotFilterText) {
  const line = sessionKv["ATS truth file"] || sessionKv["Truth file"];
  const filename = sessionKv["ATS filename"] || parseAtsFilename(line);
  if (line) {
    if (/not used/i.test(line)) {
      return filename
        ? `Provided (${filename}) — not used (no GNSS time overlap; processed as normal)`
        : "Provided — not used (no GNSS time overlap; processed as normal)";
    }
    if (/applied/i.test(line)) {
      return filename
        ? `Yes — ${filename} applied (error plots vs interpolated ATS truth)`
        : "Yes — applied (error plots vs interpolated ATS truth)";
    }
    if (/^yes\b/i.test(line)) {
      const detail = line.replace(/^yes\b/i, "").trim().replace(/^\(/, "").replace(/\)$/, "");
      return detail
        ? "Yes — " + detail + " (error plots vs interpolated ATS truth)"
        : "Yes — error plots vs interpolated ATS truth";
    }
    if (/^no\b/i.test(line)) return "No";
  }
  return parsePlotFilterFlags(plotFilterText).truth
    ? "Yes — error plots vs interpolated ATS truth"
    : "No";
}

function renderSessionType(text, plotFilterText) {
  const kv = parseSessionType(text);
  const sessionUsed = kv["Session used"] || parsePlotFilterSession(plotFilterText);
  const isMoving = sessionUsed === "moving";

  let body = "";
  const rows = [];
  if (kv["Session requested"]) {
    rows.push(["Session requested", sessionRequestLabel(kv["Session requested"])]);
  }
  rows.push(["Session used", isMoving ? "Moving" : "Static"]);
  const atsFilename = kv["ATS filename"] || parseAtsFilename(kv["ATS truth file"]);
  if (atsFilename) {
    rows.push(["ATS file", atsFilename]);
  }
  rows.push(["ATS truth", parseAtsTruthStatus(kv, plotFilterText)]);
  if (kv["Detection ran"] === "yes") {
    rows.push(["Motion detection", "Ran (2D, >10σ threshold)"]);
    if (kv["Outlier fraction"]) {
      rows.push(["Outlier fraction", kv["Outlier fraction"]]);
    }
    if (kv["Outlier epochs"]) {
      rows.push(["Outlier epochs", kv["Outlier epochs"]]);
    }
  } else if (kv["Detection ran"] === "no") {
    rows.push(["Motion detection", "Skipped (database point or forced mode)"]);
  }
  body += tableHtml(["Setting", "Value"], rows, "report-table");

  if (kv["Drive test warning"] === "yes") {
    body += '<p class="report-warning">Static mode was requested, but the data looks like a drive test. Error plots and reference statistics may not be meaningful.</p>';
  }

  return sectionHtml("Session Type", body);
}

function isTrajectorySession(text) {
  return /^TRAJECTORY_SESSION/m.test(text.trim());
}

function parseTrajectoryCoords(text) {
  const kv = {};
  parseKeyValueLines(text).forEach(([key, value]) => {
    kv[key] = value;
  });
  const latMin = parseFloat(kv["Latitude min"]);
  const latMax = parseFloat(kv["Latitude max"]);
  const lonMin = parseFloat(kv["Longitude min"]);
  const lonMax = parseFloat(kv["Longitude max"]);
  if (!Number.isFinite(latMin) || !Number.isFinite(latMax) ||
      !Number.isFinite(lonMin) || !Number.isFinite(lonMax)) {
    return null;
  }
  const heightMin = parseFloat(String(kv["Height min"] || "").replace(/ m$/i, ""));
  const heightMax = parseFloat(String(kv["Height max"] || "").replace(/ m$/i, ""));
  return {
    lat: (latMin + latMax) / 2,
    lon: (lonMin + lonMax) / 2,
    height: Number.isFinite(heightMin) && Number.isFinite(heightMax)
      ? (heightMin + heightMax) / 2
      : null
  };
}

function isAtsTruthSession(text) {
  return /Source:\s*ATS truth file/m.test(text);
}

function renderAtsTruthSummary(text, sessionKv) {
  if (!text.trim() || !isAtsTruthSession(text)) return "";

  const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const intro = lines.filter((line) => /^Moving session with ATS truth/i.test(line));
  const rows = parseKeyValueLines(
    lines.filter((line) =>
      !/^TRAJECTORY_SESSION$/i.test(line) &&
      !/^TRUTH_SESSION$/i.test(line) &&
      !/^Moving session with ATS truth/i.test(line)
    ).join("\n")
  ).filter(([key]) => key !== "truth_height_offset");

  const atsFilename = sessionKv?.["ATS filename"] || parseAtsFilename(sessionKv?.["ATS truth file"]);
  if (atsFilename && !rows.some(([key]) => key === "ATS file")) {
    rows.unshift(["ATS file", atsFilename]);
  }

  let body = "";
  if (intro.length) {
    body += '<div class="report-meta">' + intro.map(escapeHtml).join("<br>") + "</div>";
  }
  if (rows.length) {
    body += tableHtml(["Metric", "Value"], rows, "report-table");
  }
  return sectionHtml("ATS Truth", body);
}

function renderTrajectorySummary(text) {
  if (!text.trim() || !isTrajectorySession(text) || isAtsTruthSession(text)) return "";

  const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const intro = lines.filter((line) =>
    /^TRAJECTORY_SESSION$/i.test(line) ||
    /^Moving session/i.test(line)
  );
  const rows = parseKeyValueLines(
    lines.filter((line) =>
      !/^TRAJECTORY_SESSION$/i.test(line) &&
      !/^Moving session/i.test(line)
    ).join("\n")
  );

  let body = "";
  if (intro.length) {
    body += '<div class="report-meta">' + intro.map(escapeHtml).join("<br>") + "</div>";
  }
  if (rows.length) {
    body += tableHtml(["Metric", "Value"], rows, "report-table");
  }
  return sectionHtml("Trajectory Summary", body);
}

function renderLocationMap(coords, isMoving) {
  if (!coords) {
    const msg = isMoving
      ? "Location map unavailable (no trajectory coordinates)."
      : "Location map unavailable (no reference coordinates).";
    return '<p class="report-empty">' + msg + "</p>";
  }

  const { lat, lon, height } = coords;
  const osmUrl = osmEmbedUrl(lat, lon);
  const jamUrl = gpsJamUrl(lat, lon);
  const heightText = Number.isFinite(height) ? " · Height " + height.toFixed(3) + " m" : "";
  const label = isMoving ? "Trajectory center" : "Reference";

  let html = '<section class="report-location">';
  html += '<p class="report-location-coords">';
  html += label + ": " + lat.toFixed(6) + "°, " + lon.toFixed(6) + "°" + escapeHtml(heightText);
  html += ' · <a href="' + escapeHtml(jamUrl) + '" target="_blank" rel="noopener noreferrer">';
  html += "GPS interference map (GPSJam)</a>";
  html += "</p>";
  html += '<div class="report-location-map-wrap">';
  html += '<iframe class="report-location-map" title="Position map" loading="lazy"';
  html += ' src="' + escapeHtml(osmUrl) + '"></iframe>';
  html += '<div class="report-location-map-shield" role="button" tabindex="0"';
  html += ' aria-label="Click to interact with map.">';
  html += "<span>Click map to zoom and pan</span>";
  html += "</div></div>";
  html += "</section>";
  return html;
}

function attachLocationMapGuards(root) {
  if (!root) return;

  root.querySelectorAll(".report-location-map-wrap").forEach((wrap) => {
    const shield = wrap.querySelector(".report-location-map-shield");
    if (!shield || wrap.dataset.mapGuardInit === "1") return;
    wrap.dataset.mapGuardInit = "1";

    const activate = () => {
      wrap.classList.add("is-active");
    };
    const deactivate = () => {
      wrap.classList.remove("is-active");
    };

    shield.addEventListener("click", activate);
    shield.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        activate();
      }
    });

    document.addEventListener("pointerdown", (event) => {
      if (!wrap.classList.contains("is-active")) return;
      if (wrap.contains(event.target)) return;
      deactivate();
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && wrap.classList.contains("is-active")) {
        deactivate();
      }
    });
  });
}

function referenceModeLabel(text) {
  const first = text.split(/\r?\n/).map((line) => line.trim()).find(Boolean);
  if (/^Computed$/i.test(first)) return "Computed";
  if (/^(Database|Truth from|From Database)/i.test(first)) return "From database";
  return "";
}

function isReferenceMetaLine(line) {
  return /^(Mean computed from:|Standard deviations from )/i.test(line.trim());
}

function copyColumnValues(rows, colIndex) {
  return rows
    .map((row) => row[colIndex])
    .filter((value) => value && value !== "—" && value !== "n/a")
    .join("\n");
}

async function copyTextToClipboard(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
    return;
  }
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.select();
  document.execCommand("copy");
  document.body.removeChild(textarea);
}

function attachReferenceCopyButtons(root) {
  root.querySelectorAll(".report-reference-block").forEach((block) => {
    const raw = block.getAttribute("data-ref-rows");
    if (!raw) return;
    let rows;
    try {
      rows = JSON.parse(decodeURIComponent(raw));
    } catch (_) {
      return;
    }
    block.querySelectorAll(".report-copy-btn").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const col = parseInt(btn.getAttribute("data-copy-col"), 10);
        const text = copyColumnValues(rows, col);
        if (!text) return;
        const label = btn.textContent;
        try {
          await copyTextToClipboard(text);
          btn.textContent = "Copied";
          setTimeout(() => {
            btn.textContent = label;
          }, 1500);
        } catch (_) {
          btn.textContent = "Copy failed";
          setTimeout(() => {
            btn.textContent = label;
          }, 1500);
        }
      });
    });
  });
}

function stdDegToMmLat(stdDeg) {
  return stdDeg * 111320 * 1000;
}

function stdDegToMmLon(stdDeg, latDeg) {
  return stdDeg * 111320 * Math.cos((latDeg * Math.PI) / 180) * 1000;
}

function parseStdDegFromLine(value) {
  const match = String(value).match(/(-?[\d.]+)\s*deg/i);
  return match ? parseFloat(match[1]) : NaN;
}

function parseStdHeightMmFromLine(value) {
  const match = String(value).match(/(-?[\d.]+)\s*m/i);
  return match ? parseFloat(match[1]) * 1000 : NaN;
}

function fmtStdMm(value) {
  return Number.isFinite(value) ? value.toFixed(2) : "n/a";
}

function buildLegacyReferenceRows(decimal, dms, stddev) {
  const byName = {};
  decimal.forEach(([name, value]) => {
    byName[name] = { decimal: value, dms: "—", stdMm: "n/a" };
  });
  dms.forEach(([name, value]) => {
    if (!byName[name]) byName[name] = { decimal: "—", dms: value, stdMm: "n/a" };
    else byName[name].dms = value;
  });

  let latDeg = NaN;
  decimal.forEach(([name, value]) => {
    if (name === "Latitude") latDeg = parseFloat(value);
  });

  stddev.forEach(([name, value]) => {
    const base = name.replace(/\s+Std Dev$/i, "");
    if (!byName[base]) byName[base] = { decimal: "—", dms: "—", stdMm: "n/a" };
    if (base === "Latitude") {
      byName[base].stdMm = fmtStdMm(stdDegToMmLat(parseStdDegFromLine(value)));
    } else if (base === "Longitude") {
      byName[base].stdMm = fmtStdMm(stdDegToMmLon(parseStdDegFromLine(value), latDeg));
    } else if (base === "Height") {
      byName[base].stdMm = fmtStdMm(parseStdHeightMmFromLine(value));
    }
  });

  const order = ["Latitude", "Longitude", "Height"];
  return order
    .filter((name) => byName[name])
    .map((name) => normalizeReferenceRow(
      name,
      byName[name].decimal,
      byName[name].dms,
      byName[name].stdMm
    ));
}

function renderLlhMean(text) {
  if (!text.trim()) return "";

  const lines = text.split(/\r?\n/);
  const meta = [];
  const decimal = [];
  const dms = [];
  const stddev = [];
  let section = "";

  lines.forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed) return;

    if (/^Decimal degrees:/i.test(trimmed)) {
      section = "decimal";
      return;
    }
    if (/^Latitude \/ Longitude \/ Height:/i.test(trimmed)) {
      section = "dms";
      return;
    }
    if (/^Standard deviations/i.test(trimmed)) {
      section = "stddev";
      if (!/:$/.test(trimmed)) meta.push(trimmed);
      return;
    }
    if (/^(Computed|Truth from|From Database|Mean computed from:)/i.test(trimmed)) {
      meta.push(trimmed);
      return;
    }
    if (/^Standard deviations from /i.test(trimmed)) {
      meta.push(trimmed);
      return;
    }

    const kv = trimmed.match(/^([^:]+):\s*(.+)$/);
    if (!kv) return;

    const row = [kv[1].trim(), kv[2].trim()];
    if (section === "decimal") decimal.push(row);
    else if (section === "dms") dms.push(row);
    else if (section === "stddev") stddev.push(row);
  });

  const tableRows = parseReferenceTable(text);
  const rows = (tableRows.length
    ? tableRows
    : buildLegacyReferenceRows(decimal, dms, stddev)
  ).map((row) => normalizeReferenceRow(row[0], row[1], row[2], row[3]));

  const modeLabel = referenceModeLabel(text);
  const metaDisplay = meta.filter((line) => !isReferenceMetaLine(line));

  let body = "";
  if (modeLabel) {
    body += '<div class="report-meta report-source">' + escapeHtml(modeLabel) + "</div>";
  } else if (metaDisplay.length) {
    body += '<div class="report-meta">' + metaDisplay.map(escapeHtml).join("<br>") + "</div>";
  }

  if (rows.length) {
    const encodedRows = encodeURIComponent(JSON.stringify(rows));
    body += '<div class="report-reference-block" data-ref-rows="' + encodedRows + '">';
    body += '<div class="report-copy-bar">';
    body += '<button type="button" class="report-copy-btn" data-copy-col="1">Copy decimal column</button>';
    body += '<button type="button" class="report-copy-btn" data-copy-col="2">Copy DMS column</button>';
    body += "</div>";
    body += tableHtml(
      ["", "Decimal", "DMS", "Std Dev (mm)"],
      rows,
      "report-table"
    );
    body += "</div>";
  } else if (meta.some((m) => /^Standard deviations:/i.test(m))) {
    body += '<p class="report-meta">' + escapeHtml(meta.find((m) => /^Standard deviations:/i.test(m))) + "</p>";
  }
  return sectionHtml("Reference Position", body);
}

function parseSumTxt(text) {
  const result = {
    counts: [],
    latency: [],
    positionTypes: [],
    unusedSv: [],
    unusedHeader: ""
  };

  let section = "counts";
  text.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || /^=+$/.test(trimmed)) return;

    if (/^Solution Age Report:/i.test(trimmed)) {
      section = "latency";
      return;
    }
    if (/^Position Type Report:/i.test(trimmed)) {
      section = "position";
      return;
    }
    if (/^Unused SV/i.test(trimmed)) {
      section = "unused";
      result.unusedHeader = trimmed;
      return;
    }

    const countMatch = trimmed.match(/^(Total Records|Filtered Records):\s+(\d+)/i);
    if (countMatch) {
      result.counts.push([countMatch[1], countMatch[2]]);
      return;
    }

    const latencyMatch = trimmed.match(/^(.+?):\s+(\d+)\s+\(([\d.]+)%\)/);
    if (section === "latency" && latencyMatch) {
      result.latency.push([
        latencyMatch[1].trim(),
        latencyMatch[2],
        formatPercentOneDecimal(latencyMatch[3] + "%")
      ]);
      return;
    }

    const typeMatch = trimmed.match(/^(.+?):\s+(\d+)\s+\(([\d.]+)%\)/);
    if (section === "position" && typeMatch) {
      result.positionTypes.push([typeMatch[1].trim(), typeMatch[2], typeMatch[3] + "%"]);
      return;
    }

    if (section === "unused" && typeMatch) {
      result.unusedSv.push([typeMatch[1].trim(), typeMatch[2], formatPercentOneDecimal(typeMatch[3] + "%")]);
    }
  });

  return result;
}

function renderSumTxt(text) {
  if (!text.trim()) return "";

  const data = parseSumTxt(text);
  let html = "";

  if (data.counts.length) {
    html += sectionHtml("Record Counts", tableHtml(["Metric", "Count"], data.counts, "report-table"));
  }
  if (data.positionTypes.length) {
    html += sectionHtml(
      "Position Types",
      tableHtml(["Solution type", "Records", "Percent"], data.positionTypes, "report-table")
    );
  }
  if (data.unusedSv.length) {
    const title = data.unusedHeader || "Unused SVs";
    html += sectionHtml(
      title,
      tableHtml(["Category", "Records", "Percent"], data.unusedSv, "report-table")
    );
  }
  if (data.latency.length) {
    html += sectionHtml(
      "Solution Age (Latency)",
      tableHtml(["Latency", "Records", "Percent"], data.latency, "report-table")
    );
  }
  return html;
}

function formatPercentOneDecimal(value) {
  const match = String(value).match(/(-?[\d.]+)/);
  if (!match) return value;
  return Number(match[1]).toFixed(1) + "%";
}

function parseNeeMeanKv(text) {
  const kv = {};
  text.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed) return;

    const pctMatch = trimmed.match(/^(North|East|Elev)(\s+Sigma)?\s+(68|95)%:\s*(.+)$/);
    if (pctMatch) {
      const key = pctMatch[1] + (pctMatch[2] ? " Sigma" : "") + " " + pctMatch[3] + "%";
      kv[key] = pctMatch[4].trim();
      return;
    }

    const match = trimmed.match(/^([^:]+):\s*(.+)$/);
    if (match) {
      kv[match[1].trim()] = match[2].trim();
    }
  });
  return kv;
}

function renderNeeMean(text) {
  if (!text.trim()) return "";

  const kv = parseNeeMeanKv(text);

  const cell = (key) => (key && kv[key] !== undefined ? kv[key] : "—");

  const neuTableRows = [
    ["Mean", cell("North"), cell("East"), cell("Elev")],
    ["Min", cell("North Min"), cell("East Min"), cell("Elev Min")],
    ["Max", cell("North Max"), cell("East Max"), cell("Elev Max")],
    ["Range", cell("North Range"), cell("East Range"), cell("Elev Range")],
    ["68%", cell("North 68%"), cell("East 68%"), cell("Elev 68%")],
    ["95%", cell("North 95%"), cell("East 95%"), cell("Elev 95%")],
    ["Sigma 68%", cell("North Sigma 68%"), cell("East Sigma 68%"), cell("Elev Sigma 68%")],
    ["Sigma 95%", cell("North Sigma 95%"), cell("East Sigma 95%"), cell("Elev Sigma 95%")]
  ];

  const plotRows = [];
  const metaRows = [];

  Object.keys(kv).forEach((key) => {
    if (/^(North|East|Elev)/.test(key)) return;
    if (/Range|Fixed Range|Horizontal Range|Vertical Range|3D Range/i.test(key)) {
      plotRows.push([key, kv[key]]);
    } else {
      metaRows.push([key, kv[key]]);
    }
  });

  let html = sectionHtml("NEU Error Statistics", "");
  html += tableHtml(
    ["Statistic", "North (m)", "East (m)", "Elevation (m)"],
    neuTableRows,
    "report-table"
  );
  if (plotRows.length) {
    html += "<h4>Plot ranges</h4>" + tableHtml(["Setting", "Value"], plotRows, "report-table");
  }
  if (metaRows.length) {
    html += "<h4>Summary</h4>" + tableHtml(["Item", "Value"], metaRows, "report-table");
  }
  return html;
}

function formatCountPercentValue(value) {
  const trimmed = String(value).trim();
  const match = trimmed.match(/^(\d+)\s+([\d.]+%)$/);
  if (match) {
    return match[1] + " (" + match[2] + ")";
  }
  return trimmed;
}

function renderRangeSum(text, title) {
  if (!text.trim()) {
    return sectionHtml(title, '<p class="report-empty">No data.</p>');
  }
  const rows = parseKeyValueLines(text).map(([key, value]) => [
    key,
    formatCountPercentValue(value)
  ]);
  return sectionHtml(title, tableHtml(["Metric", "Value"], rows, "report-table"));
}

function rawFromDom(id) {
  const el = document.getElementById(id);
  return el ? el.textContent : "";
}

let cachedTimeRangeText = "";

function refreshTimeRangeSection() {
  if (!cachedTimeRangeText) return;
  const section = document.getElementById("session-time-range-section");
  if (!section) return;
  section.outerHTML = renderTimeRange(cachedTimeRangeText);
}

async function loadText(id, url) {
  const embedded = rawFromDom(id).trim();
  if (embedded) return embedded;
  try {
    const resp = await fetch(url, { cache: "no-store" });
    if (resp.ok) return await resp.text();
  } catch (_) {
    /* ignore */
  }
  return "";
}

async function buildReportTables() {
  const root = document.getElementById("report-summary-root");
  if (!root) return;

  const [meanInfo, timeRange, llhMean, sumTxt, neeMean, sessionType, plotFilter] = await Promise.all([
    loadText("raw-mean-info", "mean.info"),
    loadText("raw-time-range", "time_range.txt"),
    loadText("raw-llh-mean", "llh.mean"),
    loadText("raw-sum-txt", "sum.txt"),
    loadText("raw-nee-mean", "nee.mean"),
    loadText("raw-session-type", "session_type.txt"),
    loadText("raw-plot-filter", "plot_filter.txt")
  ]);

  cachedTimeRangeText = timeRange;
  if (window.gnssDisplayTz) {
    window.gnssDisplayTz.initFromTimeRange(timeRange);
    window.gnssDisplayTz.attachPanelListeners();
  }

  const sessionKv = parseSessionType(sessionType);
  const sessionUsed = sessionKv["Session used"] || parsePlotFilterSession(plotFilter);
  const plotFilterFlags = parsePlotFilterFlags(plotFilter);
  const isMoving = sessionUsed === "moving" && !plotFilterFlags.truth;

  document.querySelectorAll(".plot-static-only").forEach((el) => {
    el.style.display = isMoving ? "none" : "";
  });

  const locationRoot = document.getElementById("report-location-root");
  if (locationRoot) {
    const coords = isMoving
      ? parseTrajectoryCoords(llhMean)
      : parseReferenceCoords(llhMean);
    locationRoot.innerHTML = renderLocationMap(coords, isMoving);
    attachLocationMapGuards(locationRoot);
  }

  let html = "";
  html += renderTimeRange(timeRange);
  html += renderSessionType(sessionType, plotFilter);
  if (isMoving) {
    html += renderTrajectorySummary(llhMean);
  } else if (plotFilterFlags.truth) {
    html += renderAtsTruthSummary(llhMean, sessionKv);
    html += renderMeanInfo(meanInfo);
    html += renderNeeMean(neeMean);
  } else {
    html += renderMeanInfo(meanInfo);
    html += renderLlhMean(llhMean);
    html += renderNeeMean(neeMean);
  }
  html += renderSumTxt(sumTxt);

  if (!html.trim()) {
    root.innerHTML = '<p class="report-empty">Summary data is not available.</p>';
  } else {
    root.innerHTML = html;
    attachReferenceCopyButtons(root);
  }

  const rangeRoot = document.getElementById("range-summaries-root");
  if (!rangeRoot || isMoving) return;

  const rangeSpecs = [
    { id: "raw-range1cm", url: "range1cm.sum", title: "Height < 1 cm" },
    { id: "raw-range2cm", url: "range2cm.sum", title: "Height < 2 cm" },
    { id: "raw-range2sig", url: "range2sig.sum", title: "Height < 2 sigma" },
    { id: "raw-range3sig", url: "range3sig.sum", title: "Height < 3 sigma" }
  ];

  const rangeTexts = await Promise.all(
    rangeSpecs.map((spec) => loadText(spec.id, spec.url))
  );

  rangeRoot.innerHTML = rangeSpecs
    .map((spec, i) => renderRangeSum(rangeTexts[i], spec.title))
    .join("");
}

function loadReportTables() {
  if (window.gnssDisplayTz && !window.gnssDisplayTz._reportHooked) {
    window.gnssDisplayTz._reportHooked = true;
    window.gnssDisplayTz.onChange(() => {
      refreshTimeRangeSection();
    });
  }
  buildReportTables().catch((err) => {
    const root = document.getElementById("report-summary-root");
    if (root) {
      root.innerHTML = '<p class="report-error">Could not build summary tables: ' +
        escapeHtml(err.message) + "</p>";
    }
  });
}
