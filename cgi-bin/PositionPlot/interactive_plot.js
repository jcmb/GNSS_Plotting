const GPS_EPOCH_SEC = 315964800;
const SECONDS_IN_WEEK = 604800;
const GNSS_LEAP_SECONDS = 18;

function gpsWeekSecondsToUnix(week, seconds) {
  return GPS_EPOCH_SEC + week * SECONDS_IN_WEEK + seconds - GNSS_LEAP_SECONDS;
}

function unixToGpsWeekSeconds(plotUnix) {
  const gpsTotal = plotUnix + GNSS_LEAP_SECONDS - GPS_EPOCH_SEC;
  const gpsWeek = Math.floor(gpsTotal / SECONDS_IN_WEEK);
  const gpsSec = gpsTotal - gpsWeek * SECONDS_IN_WEEK;
  return { gpsWeek, gpsSec };
}

function parseGpsTimeFromFields(fields, unixT) {
  const weekRaw = fields[0];
  const secRaw = fields[1];
  const week = weekRaw !== "" && weekRaw != null ? Number(weekRaw) : NaN;
  const sow = Number(secRaw);
  if (Number.isFinite(week) && week >= 0 && Number.isFinite(sow) && sow < 1e9) {
    return { gpsWeek: week, gpsSec: sow };
  }
  return unixToGpsWeekSeconds(unixT);
}

function parseTimestamp(fields) {
  const seconds = Number(fields[1]);
  if (!Number.isFinite(seconds)) return NaN;
  if (seconds > 1e9) return seconds;
  const weekRaw = fields[0];
  if (weekRaw !== "" && weekRaw != null) {
    const week = Number(weekRaw);
    if (Number.isFinite(week) && week >= 0) {
      return gpsWeekSecondsToUnix(week, seconds);
    }
  }
  return seconds;
}

const SOLUTION_TYPE_NAMES = {
  0: "Autonomous",
  1: "RTCM",
  2: "SBAS",
  3: "Float",
  4: "Fixed",
  5: "OmniSTAR",
  6: "Net Fixed",
  7: "Net Float",
  8: "Type 8",
  9: "Kalman Auton",
  10: "Kalman DGNSS",
  11: "Kalman SBAS",
  12: "Type 12",
  13: "Type 13",
  14: "Type 14",
  15: "RTX",
  16: "xFill",
  17: "QZSS",
  18: "HAS"
};

function solutionTypeName(id) {
  return SOLUTION_TYPE_NAMES[id] || ("Type " + id);
}

const ERROR_COLORS = {
  north: "#1f77b4",
  east: "#ff7f0e",
  up: "#2ca02c",
  d2: "#d62728",
  d3: "#9467bd"
};

const ERROR_COLORWAY = [
  ERROR_COLORS.north,
  ERROR_COLORS.east,
  ERROR_COLORS.up,
  ERROR_COLORS.d2,
  ERROR_COLORS.d3
];

const LATENCY_COLOR = "#7f7f7f";

const SOLUTION_TYPE_LINE_COLOR = "#2563eb";
const LATENCY_COMBINED_COLOR = "#ea580c";

const DOP_COLORS = {
  PDOP: "#636efa",
  HDOP: "#ef553b",
  VDOP: "#17becf"
};

const Y2_AXIS_RIGHT_MARGIN = 50;

function reservedRightY2Axis(overrides) {
  return {
    overlaying: "y",
    side: "right",
    showgrid: false,
    showticklabels: false,
    showline: false,
    title: "",
    ticklen: 0,
    ...(overrides || {})
  };
}

const TRACE_NAME_TO_COLOR = {
  "North Error": "north",
  "East Error": "east",
  "Height Error": "up",
  "U Error": "up",
  "H Error": "d2",
  "H Sigma": "d2",
  "V Sigma": "up",
  "+1σ": "up",
  "-1σ": "up",
  "+2σ": "up",
  "-2σ": "up",
  "+3σ": "up",
  "-3σ": "up",
  "+1σ H": "d2",
  "-1σ H": "d2",
  "+2σ H": "d2",
  "-2σ H": "d2",
  "+3σ H": "d2",
  "-3σ H": "d2",
  "+1σ U": "up",
  "-1σ U": "up",
  "+2σ U": "up",
  "-2σ U": "up",
  "+3σ U": "up",
  "-3σ U": "up",
  "North velocity": "north",
  "East velocity": "east",
  "Up velocity": "up",
  "vLat": "north",
  "vLon": "east",
  "vHgt": "up",
  "Horizontal speed": "d2",
  "3D speed": "d3",
  "North Cumulative": "north",
  "East Cumulative": "east",
  "Height Cumulative": "up",
  "2D Cumulative": "d2",
  "1D Error/Sigma": "up",
  "2D Error/Sigma": "d2",
  "3D Error/Sigma": "d3",
  "1D Error |U|": "up",
  "2D Error (H)": "d2",
  "3D Error": "d3",
  "1D Sigma (V)": "up",
  "2D Sigma (H)": "d2",
  "3D Sigma": "d3",
  "2D Sigma Ratio": "d2",
  "3D Sigma Ratio": "d3",
  "1D Sigma Ratio": "up",
  "GNSS error |Δ|": "up",
  "1σ (V)": "up",
  "Error/Sigma": "d2"
};

function resolveTraceColor(trace) {
  if (!trace || !trace.name) return null;
  if (trace.name === "Latency (s)") return LATENCY_COLOR;
  if (DOP_COLORS[trace.name]) return DOP_COLORS[trace.name];
  const key = TRACE_NAME_TO_COLOR[trace.name];
  return key ? ERROR_COLORS[key] : null;
}

function applyTraceColor(trace) {
  if (!trace) return trace;
  if (trace.marker && (trace.marker.colorscale || trace.marker.colorbar)) return trace;

  const color = trace.line && trace.line.color ? trace.line.color : resolveTraceColor(trace);
  if (!color) return trace;

  if (trace.type === "bar") {
    return {
      ...trace,
      marker: { ...(trace.marker || {}), color }
    };
  }

  return {
    ...trace,
    type: trace.type || "scatter",
    mode: trace.mode || "lines",
    line: { width: 2, ...(trace.line || {}), color },
    marker: { ...(trace.marker || {}), color }
  };
}

function drawPlot(elementId, traces, layout, config) {
  return Plotly.newPlot(
    elementId,
    traces.map(applyTraceColor),
    { ...layout, colorway: ERROR_COLORWAY },
    { responsive: true, ...(config || {}) }
  );
}

function coloredLine(x, y, name, colorKey, opts = {}) {
  const color = ERROR_COLORS[colorKey];
  const { line: lineOpts, ...rest } = opts;
  return applyTraceColor({
    type: "scatter",
    x,
    y,
    name,
    mode: "lines",
    ...rest,
    line: { color, width: 2, ...(lineOpts || {}) },
    marker: { color }
  });
}

function latencyTrace(x, latency, yaxis) {
  return applyTraceColor({
    type: "scatter",
    x,
    y: latency,
    name: "Latency (s)",
    mode: "lines",
    yaxis: yaxis || "y",
    line: { color: LATENCY_COLOR, width: 2 },
    marker: { color: LATENCY_COLOR }
  });
}

function latencyYAxis(overrides) {
  return {
    title: "Latency (s)",
    rangemode: "tozero",
    zeroline: true,
    ...(overrides || {})
  };
}

function latencyPrimaryYAxis(overrides) {
  return latencyYAxis({ side: "right", ...(overrides || {}) });
}

function overlayLeftYAxis(config) {
  return { overlaying: "y", side: "left", ...config };
}

function assignTraceYAxis(traces, yaxis) {
  return traces.map((trace) => ({ ...trace, yaxis }));
}

function traceIsShownOnPlot(trace) {
  return trace.visible !== false && trace.visible !== "legendonly";
}

function syncOverlayAxesFromTraces(elementId, axisConfig) {
  const el = document.getElementById(elementId);
  if (!el || !el.data) return;

  const update = {};
  Object.entries(axisConfig).forEach(([axisKey, cfg]) => {
    const anyVisible = el.data.some((trace) =>
      cfg.traces.includes(trace.name) && traceIsShownOnPlot(trace)
    );
    update[axisKey + ".visible"] = true;
    update[axisKey + ".showticklabels"] = anyVisible;
    update[axisKey + ".showline"] = anyVisible;
    update[axisKey + ".title"] = anyVisible ? cfg.title : "";
    update[axisKey + ".ticklen"] = anyVisible ? 5 : 0;
  });
  Plotly.relayout(elementId, update);
}

function attachOverlayAxisLegendSync(elementId, axisConfig) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const runSync = () => syncOverlayAxesFromTraces(elementId, axisConfig);
  el.removeAllListeners("plotly_restyle");
  el.on("plotly_restyle", (eventData) => {
    if (eventData && Object.prototype.hasOwnProperty.call(eventData, "visible")) {
      runSync();
    }
  });
  runSync();
}

function mapSolutionType(raw) {
  const n = Number(raw);
  if (!Number.isFinite(n)) return null;
  if (n === 28) return 16;
  if (n === 37) return 17;
  if (n === 41) return 18;
  return n;
}

function parseX29Csv(text) {
  const rows = text.trim().split(/\r?\n/);
  const data = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 29) continue;
    const t = parseTimestamp(f);
    const solution = mapSolutionType(f[8]);
    const tracked = Number(f[3]);
    const used = Number(f[4]);
    const latency = Number(f[28]);
    if (!Number.isFinite(t) || solution == null) continue;
    const gps = parseGpsTimeFromFields(f, t);
    data.push({
      t, solution, tracked, used, latency, gpsWeek: gps.gpsWeek, gpsSec: gps.gpsSec
    });
  }
  return data;
}

function parsePositionCsv(text, isMoving) {
  const rows = text.trim().split(/\r?\n/);
  const data = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 29) continue;
    const t = parseTimestamp(f);
    const pdop = Number(f[18]);
    const hdop = Number(f[19]);
    const vdop = Number(f[20]);
    const tracked = Number(f[3]);
    const used = Number(f[4]);
    const hprec = Number(f[23]);
    const vprec = Number(f[24]);
    const latency = Number(f[28]);
    const solution = mapSolutionType(f[8]);
    if (!Number.isFinite(t)) continue;
    const gps = parseGpsTimeFromFields(f, t);
    if (isMoving) {
      data.push({
        t,
        lat: Number(f[10]),
        lon: Number(f[11]),
        absHeight: Number(f[12]),
        vLat: Number(f[13]),
        vLon: Number(f[14]),
        vHgt: Number(f[15]),
        n: 0,
        e: 0,
        u: Number(f[12]),
        pdop, hdop, vdop, hprec, vprec, latency, solution, tracked, used,
        gpsWeek: gps.gpsWeek, gpsSec: gps.gpsSec
      });
    } else {
      data.push({
        t,
        n: Number(f[10]),
        e: Number(f[11]),
        u: Number(f[12]),
        pdop, hdop, vdop, hprec, vprec, latency, solution, tracked, used,
        gpsWeek: gps.gpsWeek, gpsSec: gps.gpsSec
      });
    }
  }
  return data;
}

function parseGnssHeightCsv(text) {
  const rows = String(text || "").trim().split(/\r?\n/);
  if (rows.length < 2) return [];
  const data = [];
  for (let i = 1; i < rows.length; i += 1) {
    const row = rows[i];
    if (!row) continue;
    const parts = row.split(",");
    if (parts.length < 2) continue;
    const t = Number(parts[0]);
    const height = Number(parts[1]);
    if (!Number.isFinite(t) || !Number.isFinite(height)) continue;
    const gps = unixToGpsWeekSeconds(t);
    data.push({
      t,
      height,
      gpsWeek: gps.gpsWeek,
      gpsSec: gps.gpsSec
    });
  }
  return data;
}

function parseAtsCsv(text) {
  const rows = String(text || "").trim().split(/\r?\n/);
  if (rows.length < 2) return [];
  const data = [];
  for (let i = 1; i < rows.length; i += 1) {
    const row = rows[i];
    if (!row) continue;
    const parts = row.split(",");
    if (parts.length < 4) continue;
    const t = Number(parts[0]);
    const n = Number(parts[1]);
    const e = Number(parts[2]);
    const ele = Number(parts[3]);
    if (!Number.isFinite(t) || !Number.isFinite(ele)) continue;
    const gps = unixToGpsWeekSeconds(t);
    data.push({
      t,
      n,
      e,
      ele,
      gpsWeek: gps.gpsWeek,
      gpsSec: gps.gpsSec
    });
  }
  return data;
}

function attachSolutionTypes(positionPoints, solutionPoints) {
  if (!solutionPoints.length) return positionPoints;
  const byTime = new Map();
  const byRounded = new Map();
  solutionPoints.forEach((p) => {
    byTime.set(p.t, p);
    byRounded.set(timeMatchKey(p.t), p);
  });
  return positionPoints.map((p) => {
    const sol = byTime.get(p.t) ?? byRounded.get(timeMatchKey(p.t));
    if (!sol) return p;
    return {
      ...p,
      solution: p.solution != null ? p.solution : sol.solution,
      tracked: Number.isFinite(p.tracked) ? p.tracked : sol.tracked,
      used: Number.isFinite(p.used) ? p.used : sol.used,
      latency: Number.isFinite(p.latency) ? p.latency : sol.latency
    };
  });
}

function timeMatchKey(t) {
  return Math.round(t * 1000);
}

function solutionTypesInData(positionPoints, solutionPoints) {
  const tickSet = new Set();
  positionPoints.forEach((p) => {
    if (p.solution != null) tickSet.add(p.solution);
  });
  solutionPoints.forEach((p) => tickSet.add(p.solution));
  return Array.from(tickSet).sort((a, b) => a - b);
}

function getEnabledSolutionTypes() {
  const boxes = document.querySelectorAll("#sol-type-filters input[type=checkbox]:checked");
  return new Set(Array.from(boxes).map((cb) => Number(cb.value)));
}

function filterBySolutionTypes(data, enabled) {
  if (!enabled.size) return [];
  return data.filter((p) => p.solution != null && enabled.has(p.solution));
}

function applySolutionFilter(positionPoints, solutionPoints, enabled) {
  if (!enabled.size) {
    return { points: [], solutionPoints: [] };
  }
  if (!solutionPoints.length) {
    const points = filterBySolutionTypes(positionPoints, enabled);
    return { points, solutionPoints: [] };
  }
  const filteredSolution = filterBySolutionTypes(solutionPoints, enabled);
  if (!filteredSolution.length) {
    return { points: [], solutionPoints: [] };
  }
  const allowedTimes = new Set();
  const allowedRounded = new Set();
  filteredSolution.forEach((p) => {
    allowedTimes.add(p.t);
    allowedRounded.add(timeMatchKey(p.t));
  });
  const points = positionPoints.filter((p) =>
    allowedTimes.has(p.t) || allowedRounded.has(timeMatchKey(p.t))
  );
  return { points, solutionPoints: filteredSolution };
}

function buildSolutionTypeFilterUI(types) {
  const panel = document.getElementById("sol-type-filter-panel");
  const container = document.getElementById("sol-type-filters");
  if (!panel || !container) return;
  container.innerHTML = "";
  if (types.length <= 1) {
    panel.style.display = "none";
    return;
  }
  panel.style.display = "block";
  types.forEach((typeId) => {
    const label = document.createElement("label");
    const cb = document.createElement("input");
    cb.type = "checkbox";
    cb.value = String(typeId);
    cb.checked = true;
    cb.addEventListener("change", () => {
      if (getEnabledSolutionTypes().size === 0) {
        cb.checked = true;
        return;
      }
      rerenderPositionPlots();
    });
    label.appendChild(cb);
    label.appendChild(document.createTextNode(" " + solutionTypeName(typeId)));
    container.appendChild(label);
  });
}

let allPositionPoints = [];
let allSolutionPoints = [];
let allAtsPoints = [];
let allGnssHeightPoints = [];
let plotFilterInfo = {
  filter: "unknown",
  mean: "unknown",
  meanName: "",
  meanRequest: "",
  session: "static",
  sessionRequest: "-1",
  driveWarning: false,
  truth: false,
  truthHeightOffset: null,
  atsData: false,
  atsProvided: false,
  gnssHeight: false,
  atsHeightOffset: null,
  atsHeightMatched: null
};
let plotListenersAttached = false;

function rerenderPositionPlots() {
  const axisMode = document.getElementById("axis-mode");
  const enabled = getEnabledSolutionTypes();
  const types = solutionTypesInData(allPositionPoints, allSolutionPoints);
  const activeTypes = enabled.size ? enabled : new Set(types);
  const filtered = applySolutionFilter(allPositionPoints, allSolutionPoints, activeTypes);
  const points = filtered.points;
  const solutionPoints = filtered.solutionPoints;
  if (!points.length) {
    purgeAllPlots();
    document.getElementById("plot-status").textContent =
      "No points match the selected solution types.";
    document.getElementById("plot-status").className = "error";
    return;
  }
  renderPositionPlots(points, solutionPoints, axisMode.value, plotFilterInfo);
}

function solutionYAxis(solutionPoints) {
  const tickSet = new Set();
  solutionPoints.forEach((p) => tickSet.add(p.solution));
  const tickvals = Array.from(tickSet).sort((a, b) => a - b);
  if (!tickvals.length) {
    return { range: [-1, 1] };
  }
  const minY = tickvals[0];
  const maxY = tickvals[tickvals.length - 1];
  return {
    range: [minY - 1, maxY + 1],
    tickmode: "array",
    tickvals,
    ticktext: tickvals.map(solutionTypeName),
    automargin: true,
    ticklabelposition: "outside"
  };
}

function cumulativePercent(values) {
  const sorted = values
    .filter((v) => Number.isFinite(v))
    .slice()
    .sort((a, b) => a - b);
  const x = [];
  const y = [];
  for (let i = 0; i < sorted.length; i += 1) {
    x.push(sorted[i]);
    y.push(((i + 1) / sorted.length) * 100);
  }
  return { x, y };
}

function plainNumericAxisFormat() {
  return {
    exponentformat: "none",
    showexponent: "none",
    tickformat: ".0f",
    hoverformat: ".0f"
  };
}

function meterAxisBase() {
  return {
    exponentformat: "none",
    showexponent: "none"
  };
}

function meterFormatFromSpan(span) {
  if (!Number.isFinite(span) || span <= 0) {
    return { tickformat: ".3f", hoverformat: ".3f" };
  }
  const decimals = Math.max(0, Math.min(3, Math.ceil(3 - Math.log10(Math.max(span, 1e-9)))));
  const tickformat = decimals > 0 ? `.${decimals}f` : ".0f";
  const hoverDecimals = Math.min(decimals + 1, 3);
  const hoverformat = hoverDecimals > 0 ? `.${hoverDecimals}f` : ".1f";
  return { tickformat, hoverformat };
}

function meterAxisFromValues(values) {
  const finite = (values || []).filter(Number.isFinite);
  if (!finite.length) {
    return { ...meterAxisBase(), ...meterFormatFromSpan(1) };
  }
  const min = Math.min(...finite);
  const max = Math.max(...finite);
  const span = max - min || Math.max(Math.abs(max), Math.abs(min), 1);
  return { ...meterAxisBase(), ...meterFormatFromSpan(span) };
}

function yValuesFromTraces(traces, yaxisId) {
  const values = [];
  (traces || []).forEach((trace) => {
    const id = trace.yaxis || "y";
    if (id !== yaxisId) return;
    (trace.y || []).forEach((v) => {
      if (Number.isFinite(v)) values.push(v);
    });
  });
  return values;
}

function attachAdaptiveMeterAxis(plotId, yLayoutKey, yaxisId) {
  const el = document.getElementById(plotId);
  if (!el) return;

  const apply = () => {
    if (!el.layout || !el.data) return;
    const axis = el.layout[yLayoutKey] || {};
    let span;
    if (Array.isArray(axis.range) && axis.range.length === 2) {
      span = Math.abs(axis.range[1] - axis.range[0]);
    } else {
      const values = yValuesFromTraces(el.data, yaxisId);
      if (!values.length) return;
      span = Math.max(...values) - Math.min(...values);
    }
    const fmt = meterFormatFromSpan(span || 1);
    Plotly.relayout(plotId, {
      [yLayoutKey + ".tickformat"]: fmt.tickformat,
      [yLayoutKey + ".hoverformat"]: fmt.hoverformat
    });
  };

  el.on("plotly_relayout", (eventData) => {
    if (!eventData) return;
    const rangeKey = yLayoutKey + ".range";
    const range0Key = yLayoutKey + ".range[0]";
    if (
      eventData[rangeKey] ||
      eventData[range0Key] !== undefined ||
      eventData[yLayoutKey + ".autorange"] === true ||
      eventData["xaxis.range"] ||
      eventData["xaxis.autorange"] === true
    ) {
      window.setTimeout(apply, 0);
    }
  });
  apply();
}

function gpsAxisLayout(points, xValues) {
  const numericFormat = plainNumericAxisFormat();
  if (!points.length) {
    return { title: "GPS Week / Seconds", ...numericFormat };
  }
  const weeks = new Set(points.map((p) => p.gpsWeek));
  if (weeks.size === 1) {
    return {
      title: "GPS Seconds (Week " + points[0].gpsWeek + ")",
      ...numericFormat
    };
  }
  const tickCount = Math.min(10, points.length);
  const step = Math.max(1, Math.floor((points.length - 1) / Math.max(tickCount - 1, 1)));
  const tickvals = [];
  const ticktext = [];
  for (let i = 0; i < points.length; i += step) {
    tickvals.push(xValues[i]);
    ticktext.push(String(Math.round(xValues[i])));
  }
  const last = points.length - 1;
  if (tickvals[tickvals.length - 1] !== xValues[last]) {
    tickvals.push(xValues[last]);
    ticktext.push(String(Math.round(xValues[last])));
  }
  return {
    title: "GPS Week / Seconds",
    tickmode: "array",
    tickvals,
    ticktext,
    ...numericFormat
  };
}

function formatLocalTime(plotUnix) {
  const d = new Date(plotUnix * 1000);
  const pad = (n) => String(n).padStart(2, "0");
  return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
}

function formatUtcTime(plotUnix) {
  const d = new Date(plotUnix * 1000);
  const pad = (n) => String(n).padStart(2, "0");
  return pad(d.getUTCHours()) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds());
}

function utcPlotDate(plotUnix) {
  const d = new Date(plotUnix * 1000);
  return new Date(d.getTime() + d.getTimezoneOffset() * 60000);
}

function usesDateTimeAxis(mode) {
  return mode === "local" || mode === "utc";
}

function dateTimeAxisLayout(points, mode) {
  const firstT = points.length ? points[0].t : 0;
  if (mode === "utc") {
    return {
      x: points.map((p) => utcPlotDate(p.t)),
      layout: {
        title: "UTC Time (" + formatUtcTime(firstT) + ")",
        type: "date",
        tickformat: "%H:%M:%S",
        hoverformat: "%Y-%m-%d %H:%M:%S"
      }
    };
  }
  return {
    x: points.map((p) => new Date(p.t * 1000)),
    layout: {
      title: "Local Time (" + formatLocalTime(firstT) + ")",
      type: "date",
      tickformat: "%H:%M:%S",
      hoverformat: "%Y-%m-%d %H:%M:%S"
    }
  };
}

function timePlotLayout(xaxisLayout, mode) {
  return {
    margin: {
      l: 60,
      r: Y2_AXIS_RIGHT_MARGIN,
      t: usesDateTimeAxis(mode) ? 58 : 50,
      b: 45
    },
    xaxis: xaxisLayout,
    yaxis2: reservedRightY2Axis(),
    legend: {
      orientation: "h",
      y: 1.02,
      x: 0,
      xanchor: "left",
      yanchor: "bottom"
    }
  };
}

function readAtsHeightSigmaOptions() {
  const readLevel = (level) => {
    const toggles = document.querySelectorAll(`.ats-height-sigma-toggle[data-level="${level}"]`);
    if (!toggles.length) return level === "1";
    return Array.from(toggles).some((el) => el.checked);
  };
  return {
    show1Sigma: readLevel("1"),
    show2Sigma: readLevel("2"),
    show3Sigma: readLevel("3"),
    sigmaColorKeys: { 1: "up", 2: "d2", 3: "d3" }
  };
}

function syncAtsHeightSigmaToggles(source) {
  const level = source?.dataset?.level;
  if (!level) return;
  document.querySelectorAll(`.ats-height-sigma-toggle[data-level="${level}"]`).forEach((el) => {
    if (el !== source) el.checked = source.checked;
  });
}

function atsSigmaPlotLayout(axisLayout, mode, options = {}) {
  const base = timePlotLayout(axisLayout, mode);
  return {
    ...base,
    margin: {
      ...base.margin,
      r: Y2_AXIS_RIGHT_MARGIN,
      t: Math.max(base.margin.t, usesDateTimeAxis(mode) ? 78 : 70)
    },
    title: options.title,
    yaxis: options.yaxis,
    annotations: options.annotations || [],
    legend: {
      ...base.legend,
      itemclick: "toggle",
      itemdoubleclick: "toggleothers"
    }
  };
}

function sharedTimeOrigin(...pointSets) {
  let minT = Infinity;
  pointSets.forEach((pts) => {
    pts.forEach((p) => {
      if (Number.isFinite(p.t) && p.t < minT) minT = p.t;
    });
  });
  return Number.isFinite(minT) ? minT : 0;
}

function axisData(points, mode, timeOrigin) {
  if (mode === "seconds") {
    const t0 = timeOrigin !== undefined
      ? timeOrigin
      : (points.length ? points[0].t : 0);
    return {
      x: points.map((p) => p.t - t0),
      layout: {
        title: "Seconds from start",
        ...plainNumericAxisFormat()
      }
    };
  }
  if (mode === "gps") {
    const weeks = new Set(points.map((p) => p.gpsWeek));
    const singleWeek = weeks.size === 1;
    const x = singleWeek
      ? points.map((p) => p.gpsSec)
      : points.map((p) => p.gpsWeek * SECONDS_IN_WEEK + p.gpsSec);
    return {
      x,
      layout: gpsAxisLayout(points, x)
    };
  }
  if (mode === "utc" || mode === "local") {
    return dateTimeAxisLayout(points, mode);
  }
  return dateTimeAxisLayout(points, "local");
}

function horizontalSigma(points) {
  return points.map((p) => (
    Number.isFinite(p.hprec) ? Math.sqrt(2) * p.hprec : null
  ));
}

function verticalSigma(points) {
  return points.map((p) => (Number.isFinite(p.vprec) ? p.vprec : null));
}

function enrichGnssHeightsWithSigma(gnssHeights, positionPoints) {
  if (!gnssHeights.length || !positionPoints.length) return gnssHeights;
  const byTime = new Map();
  const byRounded = new Map();
  positionPoints.forEach((p) => {
    if (!Number.isFinite(p.vprec)) return;
    byTime.set(p.t, p.vprec);
    byRounded.set(timeMatchKey(p.t), p.vprec);
  });
  return gnssHeights.map((p) => {
    const vprec = byTime.get(p.t) ?? byRounded.get(timeMatchKey(p.t));
    return vprec != null ? { ...p, vprec } : p;
  });
}

function addSeries(a, b) {
  return a.map((v, i) => {
    const w = b[i];
    if (!Number.isFinite(v) || !Number.isFinite(w)) return null;
    return v + w;
  });
}

function negateSeries(values) {
  return values.map((v) => (Number.isFinite(v) ? -v : null));
}

function scaleSeries(values, factor) {
  return values.map((v) => (Number.isFinite(v) ? factor * v : null));
}

function heightRelativeSigmaBandTraces(x, center, sigma, options = {}) {
  const {
    show1Sigma = true,
    show2Sigma = false,
    show3Sigma = false,
    sigmaColorKeys = { 1: "up", 2: "d2", 3: "d3" }
  } = options;
  const suffix = " U";
  const lineStyle = { dash: "dot", width: 1.5 };
  const wideStyle = { dash: "dash", width: 1 };
  const colorFor = (level) => sigmaColorKeys[level] || "up";
  const traces = [];
  if (show1Sigma) {
    traces.push(
      coloredLine(x, addSeries(center, sigma), `+1σ${suffix}`, colorFor(1), { line: lineStyle })
    );
    traces.push(
      coloredLine(x, addSeries(center, negateSeries(sigma)), `-1σ${suffix}`, colorFor(1), { line: lineStyle })
    );
  }
  if (show2Sigma) {
    const sigma2 = scaleSeries(sigma, 2);
    traces.push(
      coloredLine(x, addSeries(center, sigma2), `+2σ${suffix}`, colorFor(2), { line: wideStyle })
    );
    traces.push(
      coloredLine(x, addSeries(center, negateSeries(sigma2)), `-2σ${suffix}`, colorFor(2), { line: wideStyle })
    );
  }
  if (show3Sigma) {
    const sigma3 = scaleSeries(sigma, 3);
    traces.push(
      coloredLine(x, addSeries(center, sigma3), `+3σ${suffix}`, colorFor(3), { line: wideStyle })
    );
    traces.push(
      coloredLine(x, addSeries(center, negateSeries(sigma3)), `-3σ${suffix}`, colorFor(3), { line: wideStyle })
    );
  }
  return traces;
}

function sigmaBandTraces(x, sigma, options = {}) {
  const {
    show1Sigma = true,
    show2Sigma = false,
    show3Sigma = false,
    labelSuffix = "",
    colorKey = "up",
    sigmaColorKeys = null,
    positiveOnly = false
  } = options;
  const suffix = labelSuffix ? ` ${labelSuffix}` : "";
  const lineStyle = { dash: "dot", width: 1.5 };
  const wideStyle = { dash: "dash", width: 1 };
  const colorFor = (level) => (sigmaColorKeys && sigmaColorKeys[level]) || colorKey;
  const traces = [];
  if (show1Sigma) {
    traces.push(
      coloredLine(x, sigma, `+1σ${suffix}`, colorFor(1), { line: lineStyle })
    );
    if (!positiveOnly) {
      traces.push(
        coloredLine(x, negateSeries(sigma), `-1σ${suffix}`, colorFor(1), { line: lineStyle })
      );
    }
  }
  if (show2Sigma) {
    const sigma2 = scaleSeries(sigma, 2);
    traces.push(
      coloredLine(x, sigma2, `+2σ${suffix}`, colorFor(2), { line: wideStyle })
    );
    if (!positiveOnly) {
      traces.push(
        coloredLine(x, negateSeries(sigma2), `-2σ${suffix}`, colorFor(2), { line: wideStyle })
      );
    }
  }
  if (show3Sigma) {
    const sigma3 = scaleSeries(sigma, 3);
    traces.push(
      coloredLine(x, sigma3, `+3σ${suffix}`, colorFor(3), { line: wideStyle })
    );
    if (!positiveOnly) {
      traces.push(
        coloredLine(x, negateSeries(sigma3), `-3σ${suffix}`, colorFor(3), { line: wideStyle })
      );
    }
  }
  return traces;
}

function verticalSigmaBandTraces(x, sigma, options = {}) {
  return sigmaBandTraces(x, sigma, options);
}

function horizontalSigmaBandTraces(x, sigma, options = {}) {
  return sigmaBandTraces(x, sigma, { ...options, labelSuffix: "H", colorKey: "d2" });
}

function verticalSigmaBandTracesForU(x, sigma, options = {}) {
  return sigmaBandTraces(x, sigma, { ...options, labelSuffix: "U", colorKey: "up" });
}

function velocitySeries(points) {
  const vn = [];
  const ve = [];
  const vu = [];
  const speedH = [];
  const speed3d = [];

  for (let i = 0; i < points.length; i += 1) {
    const { vLat, vLon, vHgt } = points[i];
    vn.push(Number.isFinite(vLat) ? vLat : null);
    ve.push(Number.isFinite(vLon) ? vLon : null);
    vu.push(Number.isFinite(vHgt) ? vHgt : null);
    if (Number.isFinite(vLat) && Number.isFinite(vLon)) {
      speedH.push(Math.hypot(vLat, vLon));
    } else {
      speedH.push(null);
    }
    if (Number.isFinite(vLat) && Number.isFinite(vLon) && Number.isFinite(vHgt)) {
      speed3d.push(Math.hypot(vLat, vLon, vHgt));
    } else {
      speed3d.push(null);
    }
  }
  return { vn, ve, vu, speedH, speed3d };
}

function d2(points) {
  return points.map((p) => Math.sqrt(p.n * p.n + p.e * p.e));
}

function d3(points) {
  return points.map((p) => Math.sqrt(p.n * p.n + p.e * p.e + p.u * p.u));
}

function withDopTraces(show, x, points) {
  if (!show) return [];
  return [
    { x, y: points.map((p) => p.pdop), name: "PDOP", type: "scatter", mode: "lines", yaxis: "y2", line: { color: DOP_COLORS.PDOP, width: 2 } },
    { x, y: points.map((p) => p.hdop), name: "HDOP", type: "scatter", mode: "lines", yaxis: "y2", line: { color: DOP_COLORS.HDOP, width: 2 } },
    { x, y: points.map((p) => p.vdop), name: "VDOP", type: "scatter", mode: "lines", yaxis: "y2", line: { color: DOP_COLORS.VDOP, width: 2 } }
  ];
}

function withSolutionTypeTrace(show, x, points) {
  if (!show) return [];
  return [{
    x,
    y: points.map((p) => p.solution),
    name: "Solution Type",
    mode: "lines",
    yaxis: "y3",
    line: { color: SOLUTION_TYPE_LINE_COLOR, width: 2 },
    marker: { color: SOLUTION_TYPE_LINE_COLOR }
  }];
}

function sigmaPlotOverlayAxes(showDop, showSol, points) {
  const axes = {};
  if (showDop) {
    axes.yaxis2 = { title: "DOP", overlaying: "y", side: "right", showgrid: false };
  }
  if (showSol) {
    axes.yaxis3 = {
      ...solutionYAxis(points),
      title: "Solution Type",
      overlaying: "y",
      side: "right",
      anchor: "free",
      position: showDop ? 0.92 : 1.0,
      showgrid: false,
      automargin: true
    };
  }
  return axes;
}

function sigmaPlotRightMargin(showDop, showSol) {
  if (showDop && showSol) return 120;
  if (showDop || showSol) return 80;
  return Y2_AXIS_RIGHT_MARGIN;
}

function vdopTrace(x, points, yaxis) {
  return applyTraceColor({
    type: "scatter",
    x,
    y: points.map((p) => (Number.isFinite(p.vdop) ? p.vdop : null)),
    name: "VDOP",
    mode: "lines",
    yaxis,
    line: { color: DOP_COLORS.VDOP, width: 2 },
    marker: { color: DOP_COLORS.VDOP }
  });
}

function sigmaRatios(points) {
  const horizSigma = points.map((p) => Math.sqrt((p.hprec || 0) * (p.hprec || 0) * 2));
  const vertSigma = points.map((p) => p.vprec);
  const err2d = d2(points);
  const err3d = d3(points);
  const sigma3d = points.map((p, i) => {
    const hs = horizSigma[i] || 0;
    const vs = vertSigma[i] || 0;
    return Math.sqrt(hs * hs + vs * vs);
  });
  return {
    r1d: points.map((p, i) => (vertSigma[i] > 0 ? Math.abs(p.u) / vertSigma[i] : null)),
    r2d: points.map((p, i) => (horizSigma[i] > 0 ? err2d[i] / horizSigma[i] : null)),
    r3d: points.map((p, i) => (sigma3d[i] > 0 ? err3d[i] / sigma3d[i] : null))
  };
}

const AGE_CORRECTION_PLOT_IDS = [
  "plot-age-corr-1d",
  "plot-age-corr-2d",
  "plot-age-corr-3d"
];

function plotErrorSigmaRatioChart(
  elementId, title, x, errY, sigY, ratioY,
  errName, sigName, ratioName, colorKey, layoutBase, options = {}
) {
  const { sigmaLegendOnly = true, ratioColorKey = colorKey } = options;
  const color = ERROR_COLORS[colorKey];
  const ratioColor = ERROR_COLORS[ratioColorKey] || color;
  return drawPlot(elementId, [
    coloredLine(x, errY, errName, colorKey),
    {
      type: "scatter",
      x,
      y: sigY,
      name: sigName,
      mode: "lines",
      visible: sigmaLegendOnly ? "legendonly" : true,
      line: { color, width: 2, dash: "dot" },
      marker: { color }
    },
    {
      type: "scatter",
      x,
      y: ratioY,
      name: ratioName,
      mode: "lines",
      yaxis: "y2",
      line: { color: ratioColor, width: 2 },
      marker: { color: ratioColor }
    }
  ], {
    ...layoutBase,
    margin: { ...layoutBase.margin, r: Y2_AXIS_RIGHT_MARGIN },
    title,
    yaxis: { title: "Meters", rangemode: "tozero", zeroline: true },
    yaxis2: {
      title: ratioName,
      overlaying: "y",
      side: "right",
      rangemode: "tozero",
      zeroline: true,
      showgrid: false
    },
    legend: { ...layoutBase.legend, itemclick: "toggle", itemdoubleclick: "toggleothers" }
  }).then(() => {
    attachOverlayAxisLegendSync(elementId, {
      yaxis2: { title: ratioName, traces: [ratioName] }
    });
  });
}

const LATENCY_BUCKET_LABELS = [
  "0 s",
  "<1 s",
  "<2 s",
  "<3 s",
  "<4 s",
  "<5 s",
  ">5 s"
];

function latencyBucket(latency) {
  if (!Number.isFinite(latency) || latency < 0) return null;
  if (latency === 0) return 0;
  if (latency <= 1) return 1;
  if (latency <= 2) return 2;
  if (latency <= 3) return 3;
  if (latency <= 4) return 4;
  if (latency <= 5) return 5;
  return 6;
}

function latencyDistribution(points) {
  const counts = [0, 0, 0, 0, 0, 0, 0];
  let total = 0;
  points.forEach((p) => {
    const bucket = latencyBucket(p.latency);
    if (bucket == null) return;
    counts[bucket]++;
    total++;
  });
  const pcts = counts.map((c) => (total > 0 ? (c / total) * 100 : 0));
  return { labels: LATENCY_BUCKET_LABELS, counts, pcts, total };
}

function plotLatencyDistribution(elementId, dist) {
  const hover = dist.labels.map((label, i) =>
    label + "<br>" + dist.counts[i] + " records (" + dist.pcts[i].toFixed(1) + "%)"
  );
  Plotly.newPlot(elementId, [{
    x: dist.labels,
    y: dist.counts,
    type: "bar",
    name: "Records",
    text: dist.pcts.map((p) => p.toFixed(1) + "%"),
    textposition: "outside",
    hovertemplate: "%{customdata}<extra></extra>",
    customdata: hover
  }], {
    margin: { l: 60, r: 30, t: 40, b: 60 },
    title: "Latency Distribution",
    xaxis: { title: "Latency" },
    yaxis: { title: "Records", rangemode: "tozero" },
    showlegend: false
  }, { responsive: true });
}

const SOLUTION_TIME_PLOT_IDS = [
  "plot-solution-latency",
  "plot-sv"
];

const POSITION_TIME_PLOT_IDS = [
  "plot-height-error",
  "plot-height-sigma",
  "plot-enu",
  "plot-enu-sigma",
  "plot-sigma-1d",
  "plot-sigma-2d",
  "plot-sigma-3d",
  "plot-age-corr-1d",
  "plot-age-corr-2d",
  "plot-age-corr-3d"
];

const MOVING_POSITION_TIME_PLOT_IDS = [
  "plot-height-error",
  "plot-height-sigma",
  "plot-velocity-neu",
  "plot-velocity-speed",
  "plot-sigma-1d",
  "plot-sigma-2d",
  "plot-sigma-3d"
];

const ATS_TIME_PLOT_IDS = [
  "plot-ats-ne",
  "plot-ats-height-delta",
  "plot-ats-error-sigma"
];

const TIME_LINKED_PLOT_IDS = [
  ...SOLUTION_TIME_PLOT_IDS,
  ...POSITION_TIME_PLOT_IDS,
  ...ATS_TIME_PLOT_IDS
];

function activeTimePlotIds(isMoving, hasTruth, hasAtsPlots) {
  const movingPlotsOnly = isMoving && !hasTruth;
  const ids = [
    ...SOLUTION_TIME_PLOT_IDS,
    ...(movingPlotsOnly ? MOVING_POSITION_TIME_PLOT_IDS : POSITION_TIME_PLOT_IDS)
  ];
  if (hasAtsPlots) {
    ids.push(...ATS_TIME_PLOT_IDS);
  }
  return ids.filter((id) => {
    if (!shouldDrawPlot(id)) return false;
    const el = document.getElementById(id);
    return el && el.data;
  });
}

const ALL_PLOT_IDS = [
  ...TIME_LINKED_PLOT_IDS,
  ...AGE_CORRECTION_PLOT_IDS,
  "plot-latency-dist",
  "plot-cumulative",
  "plot-ne-scatter"
];

const DEFAULT_PLOT_CARD_ORDER = [
  "plot-solution-latency",
  "plot-sv",
  "plot-ats-ne",
  "plot-height-error",
  "plot-height-sigma",
  "plot-ats-height-delta",
  "plot-ats-error-sigma",
  "plot-velocity-neu",
  "plot-velocity-speed",
  "plot-enu",
  "plot-enu-sigma",
  "plot-ne-scatter",
  "plot-cumulative",
  "plot-sigma-1d",
  "plot-sigma-2d",
  "plot-sigma-3d",
  "plot-age-corr"
];

let plotCardChromeInitialized = false;
let draggedPlotCard = null;

function plotCardLayoutStorageKey() {
  return "gnssPlotCardLayout:" + window.location.pathname;
}

function getPlotCardLayout() {
  try {
    const raw = sessionStorage.getItem(plotCardLayoutStorageKey());
    if (!raw) return { order: null, hidden: [] };
    const parsed = JSON.parse(raw);
    return {
      order: Array.isArray(parsed.order) ? parsed.order : null,
      hidden: Array.isArray(parsed.hidden) ? parsed.hidden : []
    };
  } catch (err) {
    return { order: null, hidden: [] };
  }
}

function savePlotCardLayout(layout) {
  try {
    sessionStorage.setItem(plotCardLayoutStorageKey(), JSON.stringify(layout));
  } catch (err) {
    // ignore quota / private browsing
  }
}

function plotCardElement(cardId) {
  return document.querySelector(`.plot-card[data-card-id="${cardId}"]`);
}

function plotCardForPlotElement(plotId) {
  const el = document.getElementById(plotId);
  return el ? el.closest(".plot-card") : null;
}

function isPlotCardClosed(cardId) {
  return getPlotCardLayout().hidden.includes(cardId);
}

function shouldDrawPlot(plotId) {
  const card = plotCardForPlotElement(plotId);
  if (!card || !card.dataset.cardId) return true;
  return !isPlotCardClosed(card.dataset.cardId);
}

function plotIdsInCard(card) {
  if (!card) return [];
  return Array.from(card.querySelectorAll("[id^='plot-']"))
    .map((el) => el.id)
    .filter((id) => id.startsWith("plot-"));
}

function purgePlotElementsInCard(card) {
  plotIdsInCard(card).forEach((id) => {
    const el = document.getElementById(id);
    if (el && el.data) Plotly.purge(id);
  });
}

function setPlotCardTitle(cardId, title) {
  const card = plotCardElement(cardId);
  const heading = card?.querySelector(".plot-card-header h3, :scope > h3");
  if (heading) heading.textContent = title;
}

function plotCardTitle(cardId) {
  const card = plotCardElement(cardId);
  const heading = card?.querySelector(".plot-card-header h3, h3");
  return heading ? heading.textContent.trim() : cardId;
}

function applyPlotCardClosedState() {
  document.querySelectorAll(".plot-card[data-card-id]").forEach((card) => {
    card.classList.toggle("plot-card-closed", isPlotCardClosed(card.dataset.cardId));
  });
  updatePlotRestoreBar();
}

function applyPlotCardOrder() {
  const container = document.getElementById("interactive-plot-cards");
  if (!container) return;
  const layout = getPlotCardLayout();
  const order = layout.order || DEFAULT_PLOT_CARD_ORDER;
  const cards = new Map();
  container.querySelectorAll(".plot-card[data-card-id]").forEach((card) => {
    cards.set(card.dataset.cardId, card);
  });
  order.forEach((cardId) => {
    const card = cards.get(cardId);
    if (card) {
      container.appendChild(card);
      cards.delete(cardId);
    }
  });
  cards.forEach((card) => container.appendChild(card));
}

function savePlotCardOrderFromDom() {
  const container = document.getElementById("interactive-plot-cards");
  if (!container) return;
  const order = Array.from(container.querySelectorAll(".plot-card[data-card-id]"))
    .map((card) => card.dataset.cardId);
  const layout = getPlotCardLayout();
  layout.order = order;
  savePlotCardLayout(layout);
}

function updatePlotRestoreBar() {
  const bar = document.getElementById("plot-restore-bar");
  if (!bar) return;
  bar.innerHTML = "";
  const hidden = getPlotCardLayout().hidden;
  if (!hidden.length) {
    bar.style.display = "none";
    return;
  }
  bar.style.display = "";
  const label = document.createElement("strong");
  label.textContent = "Hidden graphs: ";
  bar.appendChild(label);
  hidden.forEach((cardId) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "plot-restore-btn";
    btn.textContent = plotCardTitle(cardId);
    btn.addEventListener("click", () => restorePlotCard(cardId));
    bar.appendChild(btn);
  });
}

function closePlotCard(cardId) {
  const layout = getPlotCardLayout();
  if (!layout.hidden.includes(cardId)) layout.hidden.push(cardId);
  savePlotCardLayout(layout);
  const card = plotCardElement(cardId);
  if (card) {
    card.classList.add("plot-card-closed");
    purgePlotElementsInCard(card);
  }
  updatePlotRestoreBar();
  linkTimePlotZoom(activeTimePlotIds(
    plotFilterInfo.session === "moving" && !plotFilterInfo.truth,
    plotFilterInfo.truth,
    plotFilterInfo.atsProvided || (plotFilterInfo.atsData && allAtsPoints.length > 0)
  ));
}

function restorePlotCard(cardId) {
  const layout = getPlotCardLayout();
  layout.hidden = layout.hidden.filter((id) => id !== cardId);
  savePlotCardLayout(layout);
  const card = plotCardElement(cardId);
  if (card) card.classList.remove("plot-card-closed");
  updatePlotRestoreBar();
  rerenderPositionPlots();
}

function getDragAfterElement(container, y) {
  const cards = Array.from(container.querySelectorAll(".plot-card:not(.plot-card-dragging)"));
  let closest = { offset: Number.NEGATIVE_INFINITY, element: null };
  cards.forEach((child) => {
    const box = child.getBoundingClientRect();
    const offset = y - box.top - box.height / 2;
    if (offset < 0 && offset > closest.offset) {
      closest = { offset, element: child };
    }
  });
  return closest.element;
}

function enhancePlotCard(card) {
  if (card.dataset.chromeInit === "1") return;
  card.dataset.chromeInit = "1";
  const cardId = card.dataset.cardId;
  if (!cardId) return;

  const h3 = card.querySelector(":scope > h3");
  if (!h3) return;

  const header = document.createElement("div");
  header.className = "plot-card-header";

  const handle = document.createElement("span");
  handle.className = "plot-card-drag-handle";
  handle.title = "Drag to reorder";
  handle.textContent = "⋮⋮";
  handle.draggable = true;
  handle.addEventListener("dragstart", (event) => {
    draggedPlotCard = card;
    card.classList.add("plot-card-dragging");
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", cardId);
  });
  handle.addEventListener("dragend", () => {
    card.classList.remove("plot-card-dragging");
    draggedPlotCard = null;
  });

  const closeBtn = document.createElement("button");
  closeBtn.type = "button";
  closeBtn.className = "plot-card-close";
  closeBtn.title = "Close graph";
  closeBtn.setAttribute("aria-label", "Close graph");
  closeBtn.textContent = "×";
  closeBtn.addEventListener("click", () => closePlotCard(cardId));

  header.appendChild(handle);
  header.appendChild(h3);
  header.appendChild(closeBtn);
  card.insertBefore(header, card.firstChild);
}

function initPlotCardChrome() {
  const container = document.getElementById("interactive-plot-cards");
  if (!container) return;

  document.querySelectorAll(".plot-card[data-card-id]").forEach(enhancePlotCard);

  if (!plotCardChromeInitialized) {
    plotCardChromeInitialized = true;
    container.addEventListener("dragover", (event) => {
      event.preventDefault();
      if (!draggedPlotCard) return;
      const after = getDragAfterElement(container, event.clientY);
      if (after == null) {
        container.appendChild(draggedPlotCard);
      } else if (after !== draggedPlotCard) {
        container.insertBefore(draggedPlotCard, after);
      }
    });
    container.addEventListener("drop", (event) => {
      event.preventDefault();
      if (draggedPlotCard) {
        draggedPlotCard.classList.remove("plot-card-dragging");
        draggedPlotCard = null;
      }
      savePlotCardOrderFromDom();
    });
  }

  applyPlotCardOrder();
  applyPlotCardClosedState();
}

let plotDrawBatch = null;

function beginPlotDrawBatch() {
  plotDrawBatch = [];
}

function endPlotDrawBatch(done) {
  const batch = plotDrawBatch || [];
  plotDrawBatch = null;
  Promise.all(batch).finally(() => {
    if (typeof done === "function") done();
  });
}

function drawPlotIfOpen(plotId, traces, layout, config) {
  if (!shouldDrawPlot(plotId)) return Promise.resolve();
  const promise = drawPlot(plotId, traces, layout, config);
  if (plotDrawBatch) plotDrawBatch.push(promise);
  return promise;
}

function plotLatencyDistributionIfOpen(elementId, dist) {
  if (!shouldDrawPlot(elementId)) return;
  plotLatencyDistribution(elementId, dist);
}

function plotErrorSigmaRatioChartIfOpen(
  elementId, title, x, errY, sigY, ratioY,
  errName, sigName, ratioName, colorKey, layoutBase, options
) {
  if (!shouldDrawPlot(elementId)) return;
  plotErrorSigmaRatioChart(
    elementId, title, x, errY, sigY, ratioY,
    errName, sigName, ratioName, colorKey, layoutBase, options
  );
}

function removeLegacy2d3dPlot() {
  document.querySelectorAll(".plot-card h3").forEach((heading) => {
    if (heading.textContent.trim() === "2D/3D Error and Sigma") {
      heading.closest(".plot-card")?.remove();
    }
  });
  const legacy2d3d = document.getElementById("plot-2d3d");
  if (!legacy2d3d) return;
  const card = legacy2d3d.closest(".plot-card");
  if (card) card.remove();
  else legacy2d3d.remove();
}

function purgeAllPlots() {
  if (zoomSyncTimer) {
    window.clearTimeout(zoomSyncTimer);
    zoomSyncTimer = null;
  }
  zoomSyncInProgress = false;
  zoomSyncSourceId = null;
  lastSyncedRangeKey = null;

  ALL_PLOT_IDS.forEach((id) => {
    const el = document.getElementById(id);
    if (el && el.data) Plotly.purge(id);
  });
  const legacy2d3d = document.getElementById("plot-2d3d");
  if (legacy2d3d && legacy2d3d.data) Plotly.purge("plot-2d3d");
}

let zoomSyncInProgress = false;
let zoomSyncSourceId = null;
let lastSyncedRangeKey = null;
let zoomSyncTimer = null;

function rangeKey(range) {
  if (!range || range.length !== 2) return null;
  return String(range[0]) + "|" + String(range[1]);
}

function extractXRangeFromRelayout(eventData) {
  if (!eventData || eventData["xaxis.autorange"] === true) return null;
  const range = eventData["xaxis.range"];
  if (Array.isArray(range) && range.length === 2) return range;
  const x0 = eventData["xaxis.range[0]"];
  const x1 = eventData["xaxis.range[1]"];
  if (x0 !== undefined && x1 !== undefined) return [x0, x1];
  return null;
}

function xComparable(value) {
  if (value == null) return NaN;
  if (value instanceof Date) return value.getTime();
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return Number(value);
}

function yAxisLayoutKey(trace) {
  const id = trace.yaxis || "y";
  return id === "y" ? "yaxis" : "yaxis" + id.slice(1);
}

function isCategoricalYAxis(plotId, axisKey) {
  const el = document.getElementById(plotId);
  if (!el || !el.layout) return false;
  const axis = el.layout[axisKey] || {};
  return axis.tickmode === "array" && Array.isArray(axis.tickvals) && axis.tickvals.length <= 25;
}

function shouldRescaleYForPlot(plotId) {
  if (plotId === "plot-solution-latency") return false;
  const el = document.getElementById(plotId);
  if (!el || !el.layout) return true;
  if (isCategoricalYAxis(plotId, "yaxis")) return false;
  if (
    plotId === "plot-height-error"
    || plotId === "plot-height-sigma"
    || plotId === "plot-ats-height-delta"
  ) {
    const names = new Set((el.data || []).map((trace) => trace.name));
    if (
      names.has("GNSS Height")
      || names.has("GNSS error")
      || [...names].some((name) => name.startsWith("ATS Height"))
    ) {
      return false;
    }
  }
  return true;
}

function yRangeUsesToZero(plotId, axisKey) {
  const el = document.getElementById(plotId);
  if (!el || !el.layout) return axisKey === "yaxis";
  const axis = el.layout[axisKey] || {};
  return axis.rangemode === "tozero";
}

function buildYRangeUpdates(plotId, xRange) {
  const el = document.getElementById(plotId);
  if (!el || !el.data || !xRange) return {};

  const xLo = Math.min(xComparable(xRange[0]), xComparable(xRange[1]));
  const xHi = Math.max(xComparable(xRange[0]), xComparable(xRange[1]));
  if (!Number.isFinite(xLo) || !Number.isFinite(xHi)) return {};

  const byAxis = {};
  el.data.forEach((trace) => {
    const axisKey = yAxisLayoutKey(trace);
    const xs = trace.x || [];
    const ys = trace.y || [];
    for (let i = 0; i < xs.length; i += 1) {
      const xc = xComparable(xs[i]);
      if (!Number.isFinite(xc) || xc < xLo || xc > xHi) continue;
      const yv = ys[i];
      if (!Number.isFinite(yv)) continue;
      if (!byAxis[axisKey]) {
        byAxis[axisKey] = { min: Infinity, max: -Infinity };
      }
      byAxis[axisKey].min = Math.min(byAxis[axisKey].min, yv);
      byAxis[axisKey].max = Math.max(byAxis[axisKey].max, yv);
    }
  });

  const updates = {};
  Object.keys(byAxis).forEach((axisKey) => {
    if (isCategoricalYAxis(plotId, axisKey)) return;
    let min = byAxis[axisKey].min;
    let max = byAxis[axisKey].max;
    if (!Number.isFinite(min) || !Number.isFinite(max)) return;

    const span = max - min;
    const pad = span > 0 ? span * 0.08 : Math.max(Math.abs(max) * 0.08, 0.01);
    if (yRangeUsesToZero(plotId, axisKey)) {
      min = max <= 0 ? 0 : Math.max(0, min - pad);
    } else {
      min = min - pad;
    }
    max = max + pad;
    if (min >= max) {
      min -= 0.5;
      max += 0.5;
    }
    updates[axisKey + ".autorange"] = false;
    updates[axisKey + ".range"] = [min, max];
  });
  return updates;
}

function buildViewRelayout(plotId, xRange) {
  const update = {
    "xaxis.autorange": false,
    "xaxis.range": xRange
  };
  if (shouldRescaleYForPlot(plotId)) {
    Object.assign(update, buildYRangeUpdates(plotId, xRange));
  }
  return update;
}

function buildAutorangeRelayout() {
  return {
    "xaxis.autorange": true,
    "yaxis.autorange": true,
    "yaxis2.autorange": true,
    "yaxis3.autorange": true
  };
}

function relayoutWhenReady(elementId, update) {
  const result = Plotly.relayout(elementId, update);
  if (result && typeof result.then === "function") {
    return result;
  }
  return Promise.resolve();
}

function plotHasData(plotId) {
  const el = document.getElementById(plotId);
  return !!(el && el.data);
}

function syncViewToPeers(sourceId, plotIds, xRange) {
  const key = rangeKey(xRange);
  if (!key) return;

  zoomSyncInProgress = true;
  zoomSyncSourceId = sourceId;
  lastSyncedRangeKey = key;

  const updates = plotIds
    .filter((targetId) => plotHasData(targetId))
    .map((targetId) => relayoutWhenReady(targetId, buildViewRelayout(targetId, xRange)));

  Promise.all(updates).finally(() => {
    window.setTimeout(() => {
      zoomSyncInProgress = false;
      zoomSyncSourceId = null;
    }, 150);
  });
}

function syncAutorangeToPeers(sourceId, plotIds) {
  zoomSyncInProgress = true;
  zoomSyncSourceId = sourceId;
  lastSyncedRangeKey = null;

  const update = buildAutorangeRelayout();
  const updates = plotIds
    .filter((targetId) => plotHasData(targetId))
    .map((targetId) => relayoutWhenReady(targetId, update));

  Promise.all(updates).finally(() => {
    window.setTimeout(() => {
      zoomSyncInProgress = false;
      zoomSyncSourceId = null;
    }, 150);
  });
}

function linkTimePlotZoom(plotIds) {
  if (!plotIds.length) return;

  plotIds.forEach((sourceId) => {
    const sourceEl = document.getElementById(sourceId);
    if (!sourceEl) return;
    sourceEl.removeAllListeners("plotly_relayout");
    sourceEl.on("plotly_relayout", (eventData) => {
      if (!eventData || zoomSyncInProgress) return;

      if (eventData["xaxis.autorange"] === true) {
        if (zoomSyncTimer) {
          window.clearTimeout(zoomSyncTimer);
        }
        zoomSyncTimer = window.setTimeout(() => {
          zoomSyncTimer = null;
          syncAutorangeToPeers(sourceId, plotIds);
        }, 75);
        return;
      }

      const range = extractXRangeFromRelayout(eventData);
      if (!range) return;

      const key = rangeKey(range);

      // Ignore relayout echoes from plots we just updated programmatically.
      if (zoomSyncSourceId && zoomSyncSourceId !== sourceId && key === lastSyncedRangeKey) {
        return;
      }

      if (zoomSyncTimer) {
        window.clearTimeout(zoomSyncTimer);
      }
      zoomSyncTimer = window.setTimeout(() => {
        zoomSyncTimer = null;
        syncViewToPeers(sourceId, plotIds, range);
      }, 75);
    });
  });
}

function parsePlotFilter(text) {
  const lines = text.trim().split(/\r?\n/);
  let filter = "unknown";
  let mean = "unknown";
  let meanName = "";
  let meanRequest = "";
  let session = "static";
  let sessionRequest = "-1";
  let driveWarning = false;
  let truth = false;
  let truthHeightOffset = null;
  let atsData = false;
  let atsProvided = false;
  let gnssHeight = false;
  let atsHeightOffset = null;
  let atsHeightMatched = null;
  for (const line of lines) {
    if (!line) continue;
    if (line.startsWith("mean_name:")) {
      meanName = line.slice(10);
    } else if (line.startsWith("mean_request:")) {
      meanRequest = line.slice(13);
    } else if (line.startsWith("mean:")) {
      mean = line.slice(5);
    } else if (line.startsWith("session_request:")) {
      sessionRequest = line.slice(16);
    } else if (line.startsWith("session:")) {
      session = line.slice(8);
    } else if (line.startsWith("drive_warning:")) {
      driveWarning = line.slice(14).trim() === "yes";
    } else if (line.startsWith("truth:")) {
      truth = line.slice(6).trim() === "yes";
    } else if (line.startsWith("truth_height_offset:")) {
      const value = Number(line.slice(20).trim());
      truthHeightOffset = Number.isFinite(value) ? value : null;
    } else if (line.startsWith("ats_data:")) {
      atsData = line.slice(9).trim() === "yes";
    } else if (line.startsWith("ats_provided:")) {
      atsProvided = line.slice(13).trim() === "yes";
    } else if (line.startsWith("gnss_height:")) {
      gnssHeight = line.slice(12).trim() === "yes";
    } else if (line.startsWith("ats_height_offset:")) {
      const value = Number(line.slice(18).trim());
      atsHeightOffset = Number.isFinite(value) ? value : null;
    } else if (line.startsWith("ats_height_matched:")) {
      const value = Number(line.slice(19).trim());
      atsHeightMatched = Number.isFinite(value) ? value : null;
    } else {
      filter = line;
    }
  }
  return {
    filter,
    mean,
    meanName,
    meanRequest,
    session,
    sessionRequest,
    driveWarning,
    truth,
    truthHeightOffset,
    atsData,
    atsProvided,
    gnssHeight,
    atsHeightOffset,
    atsHeightMatched
  };
}

function applySessionPlotVisibility(isMoving, hasTruth, showAtsPlots) {
  const hideStatic = isMoving && !hasTruth;
  document.querySelectorAll(".plot-static-only").forEach((el) => {
    el.style.display = hideStatic ? "none" : "";
  });
  document.querySelectorAll(".plot-moving-only").forEach((el) => {
    el.style.display = hideStatic ? "" : "none";
  });
  document.querySelectorAll(".plot-ats-only").forEach((el) => {
    el.style.display = showAtsPlots ? "" : "none";
  });

  const hasAtsHeightData = showAtsPlots && allAtsPoints.length > 0;
  if (hasAtsHeightData) {
    setPlotCardTitle("plot-height-error", "GNSS / ATS Height");
    setPlotCardTitle("plot-height-sigma", "GNSS / ATS Height and Sigma");
    setPlotCardTitle("plot-ats-height-delta", "GNSS / ATS Delta and Sigma");
    setPlotCardTitle("plot-ats-error-sigma", "GNSS / ATS Error/Sigma");
  } else if (isMoving) {
    setPlotCardTitle("plot-height-error", "Height");
    setPlotCardTitle("plot-height-sigma", "Height and Sigma");
  } else {
    setPlotCardTitle("plot-height-error", "Height Error");
    setPlotCardTitle("plot-height-sigma", "Height Error and Sigma");
  }
}

function sigma3dSeries(points) {
  const hs = horizontalSigma(points);
  const vs = verticalSigma(points);
  return hs.map((h, i) => {
    const v = vs[i];
    if (!Number.isFinite(h) || !Number.isFinite(v)) return null;
    return Math.sqrt(h * h + v * v);
  });
}

function pdopMarkerStyle(points, usedSv, maxUsedSv) {
  const pdopVals = points.map((p) => p.pdop).filter(Number.isFinite);
  const pdopMax = Math.max(3, ...(pdopVals.length ? pdopVals : [8]));
  return {
    size: usedSv.map((u) => (Number.isFinite(u) ? 4 + (u / maxUsedSv) * 12 : 4)),
    color: points.map((p) => (Number.isFinite(p.pdop) ? p.pdop : pdopMax)),
    colorscale: "Viridis",
    cmin: 1,
    cmax: pdopMax,
    colorbar: { title: "PDOP" },
    showscale: true,
    opacity: 0.85
  };
}

function gnssHeightPointsForPlot(isMoving, points, atsMode) {
  if (allGnssHeightPoints.length) return allGnssHeightPoints;
  if (isMoving || atsMode) {
    return points
      .filter((p) => Number.isFinite(p.absHeight))
      .map((p) => ({
        t: p.t,
        height: p.absHeight,
        vprec: Number.isFinite(p.vprec) ? p.vprec : null,
        gpsWeek: p.gpsWeek,
        gpsSec: p.gpsSec
      }));
  }
  return [];
}

function gnssHeightsInAtsWindow(gnssHeights, atsPoints, allowFullGnssFallback) {
  if (!gnssHeights.length || !atsPoints.length) return [];
  const tMin = Math.min(...atsPoints.map((p) => p.t));
  const tMax = Math.max(...atsPoints.map((p) => p.t));
  const inWindow = gnssHeights.filter((p) => p.t >= tMin && p.t <= tMax);
  if (inWindow.length || !allowFullGnssFallback) return inWindow;
  return gnssHeights;
}

function adjustedAtsHeight(ele, heightOffset) {
  if (!Number.isFinite(ele)) return null;
  if (!Number.isFinite(heightOffset)) return ele;
  return ele + heightOffset;
}

function interpolateAtsAtTime(atsPoints, tQuery) {
  if (!atsPoints.length || tQuery < atsPoints[0].t || tQuery > atsPoints[atsPoints.length - 1].t) {
    return null;
  }
  if (tQuery === atsPoints[atsPoints.length - 1].t) {
    const last = atsPoints[atsPoints.length - 1];
    return { n: last.n, e: last.e, ele: last.ele };
  }

  let lo = 0;
  let hi = atsPoints.length - 1;
  while (lo + 1 < hi) {
    const mid = Math.floor((lo + hi) / 2);
    if (atsPoints[mid].t <= tQuery) lo = mid;
    else hi = mid;
  }

  const p0 = atsPoints[lo];
  const p1 = atsPoints[hi];
  const frac = p1.t === p0.t ? 0 : (tQuery - p0.t) / (p1.t - p0.t);
  return {
    n: p0.n + frac * (p1.n - p0.n),
    e: p0.e + frac * (p1.e - p0.e),
    ele: p0.ele + frac * (p1.ele - p0.ele)
  };
}

function gnssAtsHeightDeltaPoints(gnssHeights, atsPoints, allowFullGnssFallback, heightOffset) {
  const gnssForPlot = gnssHeightsInAtsWindow(gnssHeights, atsPoints, allowFullGnssFallback);
  const raw = [];
  gnssForPlot.forEach((p) => {
    const sample = interpolateAtsAtTime(atsPoints, p.t);
    if (!sample || !Number.isFinite(p.height) || !Number.isFinite(sample.ele)) return;
    raw.push({
      t: p.t,
      rawDelta: p.height - sample.ele,
      vprec: p.vprec,
      gpsWeek: p.gpsWeek,
      gpsSec: p.gpsSec
    });
  });
  if (!raw.length) return [];

  const meanOffset = Number.isFinite(heightOffset)
    ? heightOffset
    : raw.reduce((sum, p) => sum + p.rawDelta, 0) / raw.length;

  return raw.map((p) => ({
    t: p.t,
    delta: p.rawDelta - meanOffset,
    vprec: p.vprec,
    gpsWeek: p.gpsWeek,
    gpsSec: p.gpsSec
  }));
}

function buildAtsHeightDeltaSigmaTraces(
  mode,
  gnssHeights,
  atsPoints,
  timeOrigin,
  allowFullGnssFallback,
  heightOffset,
  sigmaOptions
) {
  const deltaPoints = gnssAtsHeightDeltaPoints(
    gnssHeights,
    atsPoints,
    allowFullGnssFallback,
    heightOffset
  );
  if (!deltaPoints.length) return [];

  const axis = axisData(deltaPoints, mode, timeOrigin);
  const x = axis.x;
  const deltas = deltaPoints.map((p) => p.delta);
  const sigmas = deltaPoints.map((p) => p.vprec);
  const traces = [];
  if (sigmas.some(Number.isFinite)) {
    traces.push(...verticalSigmaBandTraces(x, sigmas, sigmaOptions));
  }
  traces.push(coloredLine(
    x,
    deltas,
    "GNSS error",
    "up",
    { line: { width: 2.5 } }
  ));
  return traces;
}

function renderAtsHeightErrorSigmaRatio(mode, deltaPoints, timeOrigin, annotations) {
  if (!deltaPoints.length || !shouldDrawPlot("plot-ats-error-sigma")) return;

  const axis = axisData(deltaPoints, mode, timeOrigin);
  const x = axis.x;
  const errY = deltaPoints.map((p) => (
    Number.isFinite(p.delta) ? Math.abs(p.delta) : null
  ));
  const sigY = deltaPoints.map((p) => p.vprec);
  const ratioY = deltaPoints.map((p, i) => {
    const sigma = sigY[i];
    const err = errY[i];
    return Number.isFinite(err) && Number.isFinite(sigma) && sigma > 0 ? err / sigma : null;
  });

  const layoutBase = timePlotLayout(axis.layout, mode);
  plotErrorSigmaRatioChart(
    "plot-ats-error-sigma",
    "GNSS / ATS Error/Sigma",
    x,
    errY,
    sigY,
    ratioY,
    "GNSS error |Δ|",
    "1σ (V)",
    "Error/Sigma",
    "up",
    {
      ...layoutBase,
      margin: {
        ...layoutBase.margin,
        t: Math.max(layoutBase.margin.t, usesDateTimeAxis(mode) ? 78 : 70)
      },
      annotations: annotations || []
    },
    { sigmaLegendOnly: true, ratioColorKey: "d2" }
  );
}

function buildAtsHeightSigmaTraces(
  mode,
  gnssHeights,
  atsPoints,
  timeOrigin,
  allowFullGnssFallback,
  heightOffset,
  sigmaOptions
) {
  if (!atsPoints.length) return [];

  const gnssForPlot = gnssHeightsInAtsWindow(gnssHeights, atsPoints, allowFullGnssFallback);
  const traces = [];
  const hasOffset = Number.isFinite(heightOffset);

  if (gnssForPlot.length) {
    const gnssAxis = axisData(gnssForPlot, mode, timeOrigin);
    const x = gnssAxis.x;
    const heights = gnssForPlot.map((p) => p.height);
    const sigmas = gnssForPlot.map((p) => p.vprec);
    if (sigmas.some(Number.isFinite)) {
      traces.push(...heightRelativeSigmaBandTraces(x, heights, sigmas, sigmaOptions));
    }
    traces.push(coloredLine(
      x,
      heights,
      "GNSS Height",
      "d2",
      { line: { width: 2.5 } }
    ));
  }

  const atsAxis = axisData(atsPoints, mode, timeOrigin);
  traces.push(coloredLine(
    atsAxis.x,
    atsPoints.map((p) => adjustedAtsHeight(p.ele, heightOffset)),
    hasOffset ? "ATS Height (Ele + offset)" : "ATS Height (Ele)",
    "north",
    { line: { width: 2.5, dash: "dash" } }
  ));
  return traces;
}

function buildAtsHeightTraces(mode, gnssHeights, atsPoints, timeOrigin, allowFullGnssFallback, heightOffset) {
  if (!atsPoints.length) return [];

  const gnssForPlot = gnssHeightsInAtsWindow(gnssHeights, atsPoints, allowFullGnssFallback);
  const traces = [];
  const hasOffset = Number.isFinite(heightOffset);

  if (gnssForPlot.length) {
    const gnssAxis = axisData(gnssForPlot, mode, timeOrigin);
    traces.push(coloredLine(
      gnssAxis.x,
      gnssForPlot.map((p) => p.height),
      "GNSS Height",
      "d2",
      { line: { width: 2.5 } }
    ));
  }

  const atsAxis = axisData(atsPoints, mode, timeOrigin);
  traces.push(coloredLine(
    atsAxis.x,
    atsPoints.map((p) => adjustedAtsHeight(p.ele, heightOffset)),
    hasOffset ? "ATS Height (Ele + offset)" : "ATS Height (Ele)",
    "north",
    { line: { width: 2.5, dash: "dash" } }
  ));
  return traces;
}

function renderAtsHeightPlots(
  mode,
  gnssHeights,
  atsPoints,
  timeOrigin,
  filterInfo,
  allowFullGnssFallback,
  positionPoints
) {
  if (!atsPoints.length) return false;

  const gnssHeightsWithSigma = enrichGnssHeightsWithSigma(gnssHeights, positionPoints);
  const traces = buildAtsHeightTraces(
    mode,
    gnssHeightsWithSigma,
    atsPoints,
    timeOrigin,
    allowFullGnssFallback,
    filterInfo.atsHeightOffset
  );
  if (!traces.length) return false;

  const sigmaOptions = readAtsHeightSigmaOptions();
  const sigmaTraces = buildAtsHeightSigmaTraces(
    mode,
    gnssHeightsWithSigma,
    atsPoints,
    timeOrigin,
    allowFullGnssFallback,
    filterInfo.atsHeightOffset,
    sigmaOptions
  );

  const gnssForPlot = gnssHeightsInAtsWindow(gnssHeightsWithSigma, atsPoints, allowFullGnssFallback);
  const axisPoints = gnssForPlot.length ? [...gnssForPlot, ...atsPoints] : atsPoints;
  const axis = axisData(axisPoints, mode, timeOrigin);
  const heightValues = yValuesFromTraces(sigmaTraces.length ? sigmaTraces : traces, "y");
  const heightOffsetNotes = heightOffsetAnnotation(filterInfo.atsHeightOffset);
  const heightSigmaLayout = atsSigmaPlotLayout(axis.layout, mode, {
    title: "GNSS / ATS Height and Sigma",
    yaxis: {
      title: "Height (m)",
      autorange: true,
      ...meterAxisFromValues(heightValues)
    },
    annotations: heightOffsetNotes
  });

  drawPlotIfOpen("plot-height-error", traces, {
    ...heightSigmaLayout,
    title: "GNSS / ATS Height"
  }).then(() => {
    attachAdaptiveMeterAxis("plot-height-error", "yaxis", "y");
  });

  drawPlotIfOpen("plot-height-sigma", sigmaTraces, {
    ...heightSigmaLayout,
    title: "GNSS / ATS Height and Sigma"
  }).then(() => {
    attachAdaptiveMeterAxis("plot-height-sigma", "yaxis", "y");
  });

  const deltaTraces = buildAtsHeightDeltaSigmaTraces(
    mode,
    gnssHeightsWithSigma,
    atsPoints,
    timeOrigin,
    allowFullGnssFallback,
    filterInfo.atsHeightOffset,
    sigmaOptions
  );
  const deltaPoints = gnssAtsHeightDeltaPoints(
    gnssHeightsWithSigma,
    atsPoints,
    allowFullGnssFallback,
    filterInfo.atsHeightOffset
  );
  if (deltaTraces.length) {
    const deltaAxis = axisData(deltaPoints, mode, timeOrigin);
    const deltaValues = yValuesFromTraces(deltaTraces, "y");
    drawPlotIfOpen("plot-ats-height-delta", deltaTraces, atsSigmaPlotLayout(deltaAxis.layout, mode, {
      title: "GNSS / ATS Delta and Sigma",
      yaxis: {
        title: "GNSS error (m)",
        zeroline: true,
        autorange: true,
        ...meterAxisFromValues(deltaValues)
      },
      annotations: heightOffsetNotes
    })).then(() => {
      attachAdaptiveMeterAxis("plot-ats-height-delta", "yaxis", "y");
    });
  }
  if (deltaPoints.length) {
    renderAtsHeightErrorSigmaRatio(mode, deltaPoints, timeOrigin, heightOffsetNotes);
  }

  return true;
}

function heightOffsetAnnotation(offset) {
  if (!Number.isFinite(offset)) return [];
  return [{
    text: "Mean GNSS − ATS height: " + offset.toFixed(4) + " m (applied to ATS Ele)",
    showarrow: false,
    xref: "paper",
    yref: "paper",
    x: 0,
    y: 1.12,
    xanchor: "left",
    yanchor: "bottom",
    font: { size: 12, color: "#333" }
  }];
}

function renderAtsNePlot(atsPoints, mode, showWhenEmpty, timeOrigin) {
  const emptyLayout = {
    margin: { l: 60, r: 30, t: 50, b: 45 },
    title: "ATS data unavailable",
    xaxis: { visible: false },
    yaxis: { visible: false },
    annotations: [{
      text: "An ATS file was provided but no ATS plot points were exported.",
      showarrow: false,
      xref: "paper",
      yref: "paper",
      x: 0.5,
      y: 0.5,
      font: { size: 14, color: "#666" }
    }]
  };

  if (!atsPoints.length) {
    if (!showWhenEmpty) return;
    drawPlotIfOpen("plot-ats-ne", [], emptyLayout);
    return;
  }

  const atsAxis = axisData(atsPoints, mode, timeOrigin ?? sharedTimeOrigin(atsPoints));
  const atsX = atsAxis.x;
  const neTraces = [
    coloredLine(atsX, atsPoints.map((p) => p.n), "Northing", "north"),
    coloredLine(atsX, atsPoints.map((p) => p.e), "Easting", "east")
  ];
  const neValues = yValuesFromTraces(neTraces, "y");
  drawPlotIfOpen("plot-ats-ne", neTraces, {
    ...timePlotLayout(atsAxis.layout, mode),
    title: "ATS Northing and Easting",
    yaxis: { title: "Meters", ...meterAxisFromValues(neValues) }
  }).then(() => {
    attachAdaptiveMeterAxis("plot-ats-ne", "yaxis", "y");
  });
}

function renderPositionPlots(points, solutionPoints, mode, filterInfo) {
  if (!points.length) {
    document.getElementById("plot-status").textContent = "No position points found in position_data.csv.";
    document.getElementById("plot-status").className = "error";
    return;
  }

  const isMovingSession = filterInfo.session === "moving";
  const hasTruth = !!filterInfo.truth;
  const hasAtsProvided = !!filterInfo.atsProvided;
  const hasAtsData = allAtsPoints.length > 0;
  const showAtsPlots = hasAtsProvided || hasAtsData;
  const isMoving = isMovingSession && !hasTruth;
  initPlotCardChrome();
  applySessionPlotVisibility(isMovingSession, hasTruth, showAtsPlots);

  purgeAllPlots();
  beginPlotDrawBatch();

  const solPoints = solutionPoints.length ? solutionPoints : points;
  const timeOrigin = sharedTimeOrigin(points, solPoints);
  const axis = axisData(points, mode, timeOrigin);
  const solAxis = axisData(solPoints, mode, timeOrigin);
  const x = axis.x;
  const solX = solAxis.x;
  const north = points.map((p) => Math.abs(p.n));
  const east = points.map((p) => Math.abs(p.e));
  const up = points.map((p) => Math.abs(p.u));
  const signedHeight = isMoving
    ? points.map((p) => (Number.isFinite(p.absHeight) ? p.absHeight : null))
    : points.map((p) => (Number.isFinite(p.u) ? p.u : null));
  const err2d = d2(points);
  const latency = points.map((p) => (
    Number.isFinite(p.latency) && p.latency >= 0 ? p.latency : null
  ));
  const hSigma = horizontalSigma(points);
  const vSigma = verticalSigma(points);
  const s3d = sigma3dSeries(points);

  const commonLayout = timePlotLayout(axis.layout, mode);

  drawPlotIfOpen("plot-solution-latency", [
    {
      x: solX,
      y: solPoints.map((p) => p.latency),
      name: "Latency (s)",
      mode: "lines",
      line: { color: LATENCY_COMBINED_COLOR, width: 2, dash: "dot" },
      marker: { color: LATENCY_COMBINED_COLOR }
    },
    {
      x: solX,
      y: solPoints.map((p) => p.solution),
      name: "Solution Type",
      mode: "lines",
      yaxis: "y2",
      line: { color: SOLUTION_TYPE_LINE_COLOR, width: 2.5 },
      marker: { color: SOLUTION_TYPE_LINE_COLOR }
    }
  ], {
    ...timePlotLayout(solAxis.layout, mode),
    margin: { l: 100, r: 60, t: usesDateTimeAxis(mode) ? 58 : 50, b: 45 },
    title: "Solution and Latency Combined",
    yaxis: latencyPrimaryYAxis({ automargin: true }),
    yaxis2: overlayLeftYAxis({
      ...solutionYAxis(solPoints),
      automargin: true
    })
  });

  plotLatencyDistributionIfOpen("plot-latency-dist", latencyDistribution(solPoints));

  drawPlotIfOpen("plot-sv", [
    { x: solX, y: solPoints.map((p) => p.tracked), name: "Tracked", mode: "lines" },
    { x: solX, y: solPoints.map((p) => p.used), name: "Used", mode: "lines" },
    {
      x: solX,
      y: solPoints.map((p) => p.solution),
      name: "Solution Type",
      mode: "lines",
      yaxis: "y2",
      line: { color: SOLUTION_TYPE_LINE_COLOR, width: 2.5 },
      marker: { color: SOLUTION_TYPE_LINE_COLOR }
    }
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: 100 },
    xaxis: solAxis.layout,
    title: "SVs Used and Tracked",
    yaxis: { title: "SV Count" },
    yaxis2: {
      ...solutionYAxis(solPoints),
      overlaying: "y",
      side: "right",
      automargin: true
    }
  });

  if (showAtsPlots) {
    renderAtsNePlot(allAtsPoints, mode, hasAtsProvided && !allAtsPoints.length, timeOrigin);
  }

  const gnssHeights = gnssHeightPointsForPlot(isMoving, points, showAtsPlots);
  const hasAtsHeightMatch = Number.isFinite(filterInfo.atsHeightMatched) && filterInfo.atsHeightMatched > 0;
  const showAtsHeightMode = showAtsPlots && allAtsPoints.length > 0;
  const allowFullGnssFallback = hasAtsHeightMatch && gnssHeights.length > 0;
  const renderedAtsHeights = showAtsHeightMode && renderAtsHeightPlots(
    mode,
    gnssHeights,
    allAtsPoints,
    timeOrigin,
    filterInfo,
    allowFullGnssFallback,
    points
  );
  const heightPlotTitle = showAtsHeightMode
    ? "GNSS / ATS Height"
    : (isMoving ? "Height" : "Height Error");
  const heightY2Title = isMoving ? "Height (m)" : "Height Error (m)";

  if (!renderedAtsHeights) {
    const heightTraces = [
      latencyTrace(x, latency),
      { ...vdopTrace(x, points, "y3"), visible: "legendonly" },
      coloredLine(x, signedHeight, isMoving ? "Height" : "Height Error", "up", {
        yaxis: "y2",
        line: { width: 2.5 }
      })
    ];
    const heightLayout = {
      ...commonLayout,
      margin: { ...commonLayout.margin, r: Y2_AXIS_RIGHT_MARGIN },
      title: heightPlotTitle,
      yaxis: latencyPrimaryYAxis(),
      yaxis2: overlayLeftYAxis({
        title: heightY2Title,
        zeroline: !isMoving,
        ...meterAxisFromValues(signedHeight.filter(Number.isFinite))
      }),
      yaxis3: {
        title: "VDOP",
        overlaying: "y",
        side: "right",
        anchor: "free",
        position: 1.0,
        showgrid: false
      },
      legend: { ...commonLayout.legend, itemclick: "toggle", itemdoubleclick: "toggleothers" }
    };
    drawPlotIfOpen("plot-height-error", heightTraces, heightLayout).then(() => {
      attachOverlayAxisLegendSync("plot-height-error", {
        yaxis: { title: "Latency (s)", traces: ["Latency (s)"] },
        yaxis2: {
          title: heightY2Title,
          traces: ["Height", "Height Error"]
        },
        yaxis3: { title: "VDOP", traces: ["VDOP"] }
      });
      attachAdaptiveMeterAxis("plot-height-error", "yaxis2", "y2");
    });
  }

  if (!renderedAtsHeights) {
    const showHeightSigma1 = document.getElementById("show-height-sigma-1")?.checked;
    const showHeightSigma2 = document.getElementById("show-height-sigma-2")?.checked;
    const showHeightSigma3 = document.getElementById("show-height-sigma-3")?.checked;
    const heightSigmaTraces = verticalSigmaBandTraces(x, vSigma, {
      show1Sigma: showHeightSigma1,
      show2Sigma: showHeightSigma2,
      show3Sigma: showHeightSigma3,
      sigmaColorKeys: { 1: "up", 2: "d2", 3: "d3" }
    });
    const heightSigmaLayout = {
      ...commonLayout,
      margin: { ...commonLayout.margin, r: Y2_AXIS_RIGHT_MARGIN },
      title: isMoving ? "Height and Sigma" : "Height Error and Sigma",
      yaxis: {
        title: heightY2Title,
        zeroline: true,
        ...meterAxisFromValues(signedHeight.filter(Number.isFinite))
      },
      legend: { ...commonLayout.legend, itemclick: "toggle", itemdoubleclick: "toggleothers" }
    };
    if (isMoving) {
      heightSigmaLayout.yaxis2 = {
        title: "V Sigma (m)",
        overlaying: "y",
        side: "right",
        zeroline: true,
        showgrid: false
      };
    }
    drawPlotIfOpen("plot-height-sigma", [
      ...heightSigmaTraces.map((trace) => (isMoving ? { ...trace, yaxis: "y2" } : trace)),
      coloredLine(x, signedHeight, isMoving ? "Height" : "Height Error", "up")
    ], heightSigmaLayout).then(() => {
      attachAdaptiveMeterAxis("plot-height-sigma", "yaxis", "y");
    });
  }

  if (isMoving) {
    const vel = velocitySeries(points);
    const showSolVelNeu = document.getElementById("show-sol-velocity-neu")?.checked;
    const showSolSpeed = document.getElementById("show-sol-velocity-speed")?.checked;

    drawPlotIfOpen("plot-velocity-neu", [
      coloredLine(x, vel.vn, "vLat", "north"),
      coloredLine(x, vel.ve, "vLon", "east"),
      coloredLine(x, vel.vu, "vHgt", "up"),
      ...withSolutionTypeTrace(showSolVelNeu, x, points)
    ], {
      ...commonLayout,
      margin: { ...commonLayout.margin, r: sigmaPlotRightMargin(false, showSolVelNeu) },
      title: "Velocity (NEU)",
      yaxis: { title: "Velocity (m/s)" },
      ...sigmaPlotOverlayAxes(false, showSolVelNeu, points)
    });
    drawPlotIfOpen("plot-velocity-speed", [
      coloredLine(x, vel.speedH, "Horizontal speed", "d2"),
      coloredLine(x, vel.speed3d, "3D speed", "d3", { line: { dash: "dot" } }),
      ...withSolutionTypeTrace(showSolSpeed, x, points)
    ], {
      ...commonLayout,
      margin: { ...commonLayout.margin, r: sigmaPlotRightMargin(false, showSolSpeed) },
      title: "Speed",
      yaxis: { title: "Speed (m/s)", rangemode: "tozero" },
      ...sigmaPlotOverlayAxes(false, showSolSpeed, points)
    });
  }

  if (!isMoving) {
  drawPlotIfOpen("plot-enu", [
    latencyTrace(x, latency),
    coloredLine(x, north, "North Error", "north", { yaxis: "y2" }),
    coloredLine(x, east, "East Error", "east", { yaxis: "y2" }),
    coloredLine(x, up, "Height Error", "up", { yaxis: "y2" })
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: Y2_AXIS_RIGHT_MARGIN },
    title: "NEU Error",
    yaxis: latencyPrimaryYAxis(),
    yaxis2: overlayLeftYAxis({ title: "Error (m)" })
  });

  drawPlotIfOpen("plot-enu-sigma", [
    latencyTrace(x, latency),
    ...assignTraceYAxis([
      ...horizontalSigmaBandTraces(x, hSigma, {
        show2Sigma: document.getElementById("show-enu-sigma-2")?.checked,
        show3Sigma: document.getElementById("show-enu-sigma-3")?.checked,
        positiveOnly: true
      }),
      ...verticalSigmaBandTracesForU(x, vSigma, {
        show2Sigma: document.getElementById("show-enu-sigma-2")?.checked,
        show3Sigma: document.getElementById("show-enu-sigma-3")?.checked,
        positiveOnly: true
      }),
      coloredLine(x, err2d, "H Error", "d2"),
      coloredLine(x, up, "U Error", "up")
    ], "y2")
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: Y2_AXIS_RIGHT_MARGIN },
    title: "H/U Error and Sigma",
    yaxis: latencyPrimaryYAxis(),
    yaxis2: overlayLeftYAxis({ title: "Meters", rangemode: "tozero", zeroline: true }),
    legend: { ...commonLayout.legend, itemclick: "toggle", itemdoubleclick: "toggleothers" }
  });

  const usedSv = points.map((p) => (Number.isFinite(p.used) ? p.used : null));
  const maxUsedSv = Math.max(1, ...usedSv.filter(Number.isFinite));
  drawPlotIfOpen("plot-ne-scatter", [{
    x: points.map((p) => p.e),
    y: points.map((p) => p.n),
    mode: "markers",
    name: "NE Error",
    marker: pdopMarkerStyle(points, usedSv, maxUsedSv),
    customdata: points.map((p) => [p.pdop, p.tracked, p.used]),
    hovertemplate:
      "East: %{x:.4f} m<br>North: %{y:.4f} m<br>PDOP: %{customdata[0]:.2f}" +
      "<br>SVs tracked: %{customdata[1]}<br>SVs used: %{customdata[2]}<extra></extra>"
  }], {
    margin: { l: 60, r: 80, t: 40, b: 50 },
    title: "NE Error Scatter (marker color = PDOP, size = SVs used)",
    xaxis: { title: "East Error (m)", scaleanchor: "y", scaleratio: 1, zeroline: true },
    yaxis: { title: "North Error (m)", zeroline: true },
    showlegend: false
  });

  const cN = cumulativePercent(north);
  const cE = cumulativePercent(east);
  const c2d = cumulativePercent(err2d);
  const cU = cumulativePercent(up);
  drawPlotIfOpen("plot-cumulative", [
    coloredLine(cN.x, cN.y, "North Cumulative", "north", { visible: "legendonly" }),
    coloredLine(cE.x, cE.y, "East Cumulative", "east", { visible: "legendonly" }),
    coloredLine(c2d.x, c2d.y, "2D Cumulative", "d2"),
    coloredLine(cU.x, cU.y, "Height Cumulative", "up")
  ], {
    margin: { l: 60, r: 30, t: 40, b: 40 },
    title: "Cumulative Error Curves",
    xaxis: { title: "Error (m)" },
    yaxis: { title: "Percent (%)", range: [0, 100] },
    legend: { orientation: "h" }
  });
  }

  const showDop1 = document.getElementById("show-dop-1d").checked;
  const showDop2 = document.getElementById("show-dop-2d").checked;
  const showDop3 = document.getElementById("show-dop-3d").checked;
  const showSol1 = document.getElementById("show-sol-1d").checked;
  const showSol2 = document.getElementById("show-sol-2d").checked;
  const showSol3 = document.getElementById("show-sol-3d").checked;

  drawPlotIfOpen("plot-sigma-1d", [
    coloredLine(x, vSigma, "V Sigma", "up"),
    ...withDopTraces(showDop1, x, points),
    ...withSolutionTypeTrace(showSol1, x, points)
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: sigmaPlotRightMargin(showDop1, showSol1) },
    title: "1D Sigma (Vertical)",
    yaxis: { title: "Sigma (m)", rangemode: "tozero" },
    ...sigmaPlotOverlayAxes(showDop1, showSol1, points)
  });

  drawPlotIfOpen("plot-sigma-2d", [
    coloredLine(x, hSigma, "H Sigma", "d2"),
    ...withDopTraces(showDop2, x, points),
    ...withSolutionTypeTrace(showSol2, x, points)
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: sigmaPlotRightMargin(showDop2, showSol2) },
    title: "2D Sigma (Horizontal)",
    yaxis: { title: "Sigma (m)", rangemode: "tozero" },
    ...sigmaPlotOverlayAxes(showDop2, showSol2, points)
  });

  drawPlotIfOpen("plot-sigma-3d", [
    coloredLine(x, s3d, "3D Sigma", "d3"),
    ...withDopTraces(showDop3, x, points),
    ...withSolutionTypeTrace(showSol3, x, points)
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: sigmaPlotRightMargin(showDop3, showSol3) },
    title: "3D Sigma",
    yaxis: { title: "Sigma (m)", rangemode: "tozero" },
    ...sigmaPlotOverlayAxes(showDop3, showSol3, points)
  });

  if (!isMoving) {
  const ratios = sigmaRatios(points);
  const err3d = d3(points);
  plotErrorSigmaRatioChartIfOpen(
    "plot-age-corr-1d",
    "1D Error and Sigma",
    x, up, vSigma, ratios.r1d,
    "1D Error |U|", "1D Sigma (V)", "1D Sigma Ratio",
    "up", commonLayout,
    { sigmaLegendOnly: false }
  );
  plotErrorSigmaRatioChartIfOpen(
    "plot-age-corr-2d",
    "2D Error and Sigma",
    x, err2d, hSigma, ratios.r2d,
    "2D Error (H)", "2D Sigma (H)", "2D Sigma Ratio",
    "d2", commonLayout
  );
  plotErrorSigmaRatioChartIfOpen(
    "plot-age-corr-3d",
    "3D Error and Sigma",
    x, err3d, s3d, ratios.r3d,
    "3D Error", "3D Sigma", "3D Sigma Ratio",
    "d3", commonLayout
  );
  }

  endPlotDrawBatch(() => {
    linkTimePlotZoom(activeTimePlotIds(isMovingSession, hasTruth, showAtsPlots));
    applyPlotCardClosedState();
  });

  const statusEl = document.getElementById("plot-status");
  if (filterInfo.driveWarning) {
    statusEl.textContent = "Warning: static mode on data that looks like a drive test.";
    statusEl.className = "error";
  } else if (showAtsPlots && !allAtsPoints.length && hasAtsHeightMatch) {
    statusEl.textContent =
      "ATS height offset was computed on the server, but ATS plot data failed to load in the browser.";
    statusEl.className = "error";
  } else {
    statusEl.textContent = "";
    statusEl.className = "";
  }
}

function attachPlotControlListeners() {
  if (plotListenersAttached) return;
  plotListenersAttached = true;

  document.getElementById("axis-mode").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-1d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-2d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-3d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-sol-1d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-sol-2d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-sol-3d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-sol-velocity-neu").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-sol-velocity-speed").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-height-sigma-1").addEventListener("change", (event) => {
    syncAtsHeightSigmaToggles(event.target);
    rerenderPositionPlots();
  });
  document.getElementById("show-height-sigma-2").addEventListener("change", (event) => {
    syncAtsHeightSigmaToggles(event.target);
    rerenderPositionPlots();
  });
  document.getElementById("show-height-sigma-3").addEventListener("change", (event) => {
    syncAtsHeightSigmaToggles(event.target);
    rerenderPositionPlots();
  });
  document.querySelectorAll(".ats-height-sigma-toggle:not([id])").forEach((el) => {
    el.addEventListener("change", (event) => {
      syncAtsHeightSigmaToggles(event.target);
      rerenderPositionPlots();
    });
  });
  document.getElementById("show-enu-sigma-2").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-enu-sigma-3").addEventListener("change", rerenderPositionPlots);
}

function setPlotStatus(message, state) {
  const el = document.getElementById("plot-status");
  if (!el) return;
  el.textContent = message;
  el.className = state || "";
}

function gunzipToText(buffer) {
  if (typeof DecompressionStream === "undefined") {
    return Promise.reject(new Error("gzip decompression not supported"));
  }
  const stream = new Response(buffer).body.pipeThrough(new DecompressionStream("gzip"));
  return new Response(stream).text();
}

function decodeFetchedText(resp, buffer) {
  const encoding = (resp.headers.get("Content-Encoding") || "").toLowerCase();
  if (encoding.includes("gzip")) {
    return resp.text();
  }
  if (!buffer) return resp.text();
  return gunzipToText(buffer).catch(() => {
    const text = new TextDecoder().decode(buffer);
    if (/unix_time|,/.test(text)) return text;
    return Promise.reject(new Error("gzip decode failed"));
  });
}

function fetchTextFile(baseUrl, optional) {
  const loadPlain = () =>
    fetch(baseUrl, { cache: "no-store" }).then((resp) => {
      if (!resp.ok) {
        if (optional) return "";
        throw new Error("Failed to load " + baseUrl);
      }
      return resp.text();
    });

  return fetch(baseUrl + ".gz", { cache: "no-store" })
    .then((resp) => {
      if (!resp.ok) return loadPlain();
      const encoding = (resp.headers.get("Content-Encoding") || "").toLowerCase();
      if (encoding.includes("gzip")) {
        return resp.text();
      }
      return resp.arrayBuffer().then((buf) =>
        decodeFetchedText(resp, buf).catch(() => loadPlain())
      );
    });
}

function loadInteractivePosition() {
  if (typeof Plotly === "undefined") {
    setPlotStatus(
      "Plotly failed to load. Check internet access or host Plotly locally.",
      "error"
    );
    return;
  }
  removeLegacy2d3dPlot();
  initPlotCardChrome();
  setPlotStatus("Loading interactive plot data...", "loading");

  const fetchStep = (label, url, optional) => {
    setPlotStatus(label, "loading");
    return fetchTextFile(url, optional);
  };

  fetchStep("Loading plot filter metadata...", "plot_filter.txt", true)
    .then((filterText) => {
      plotFilterInfo = parsePlotFilter(filterText);
      const isMoving = plotFilterInfo.session === "moving" && !plotFilterInfo.truth;
      const shouldLoadAts = plotFilterInfo.atsProvided || plotFilterInfo.atsData;
      const shouldLoadGnssHeight = plotFilterInfo.atsProvided || plotFilterInfo.gnssHeight;
      const atsPromise = shouldLoadAts
        ? fetchStep("Loading ATS data...", "ats_data.csv", true)
        : Promise.resolve("");
      const gnssHeightPromise = shouldLoadGnssHeight
        ? fetchStep("Loading GNSS height data...", "gnss_height.csv", true)
        : Promise.resolve("");
      return Promise.all([atsPromise, gnssHeightPromise])
        .then(([atsText, gnssHeightText]) => fetchStep("Loading position data...", "position_data.csv")
          .then((posText) => fetchStep("Loading solution data...", "position_solution.csv", true)
            .then((solText) => ({
              posText,
              solText,
              atsText,
              gnssHeightText,
              isMoving
            }))));
    })
    .then(({ posText, solText, atsText, gnssHeightText, isMoving }) => {
      setPlotStatus("Parsing plot data...", "loading");
      const solutionPoints = solText ? parseX29Csv(solText) : [];
      allPositionPoints = attachSolutionTypes(parsePositionCsv(posText, isMoving), solutionPoints);
      allSolutionPoints = solutionPoints;
      allAtsPoints = atsText ? parseAtsCsv(atsText) : [];
      allGnssHeightPoints = gnssHeightText ? parseGnssHeightCsv(gnssHeightText) : [];
      const types = solutionTypesInData(allPositionPoints, allSolutionPoints);
      buildSolutionTypeFilterUI(types);
      attachPlotControlListeners();
      setPlotStatus("Rendering interactive plots...", "loading");
      rerenderPositionPlots();
    })
    .catch((err) => {
      setPlotStatus("Interactive plot unavailable: " + err.message, "error");
    });
}
