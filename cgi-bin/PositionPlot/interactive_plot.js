const GPS_EPOCH_SEC = 315964800;
const SECONDS_IN_WEEK = 604800;

function gpsWeekSecondsToUnix(week, seconds) {
  return GPS_EPOCH_SEC + week * SECONDS_IN_WEEK + seconds;
}

function unixToGpsWeekSeconds(unixSec) {
  const gpsTotal = unixSec - GPS_EPOCH_SEC;
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

const DOP_COLORS = {
  PDOP: "#636efa",
  HDOP: "#ef553b",
  VDOP: "#17becf"
};

const TRACE_NAME_TO_COLOR = {
  "North Error": "north",
  "East Error": "east",
  "Height Error": "up",
  "U Error": "up",
  "H Error": "d2",
  "H Sigma": "d2",
  "V Sigma": "up",
  "North Cumulative": "north",
  "East Cumulative": "east",
  "Height Cumulative": "up",
  "1D Error/Sigma": "up",
  "2D Error/Sigma": "d2",
  "3D Error/Sigma": "d3",
  "1D Error |U|": "up",
  "2D Error (H)": "d2",
  "3D Error": "d3",
  "1D Sigma (V)": "up",
  "2D Sigma (H)": "d2",
  "3D Sigma": "d3"
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
  Plotly.newPlot(
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

function latencyTrace(x, latency) {
  return applyTraceColor({
    type: "scatter",
    x,
    y: latency,
    name: "Latency (s)",
    mode: "lines",
    yaxis: "y2",
    line: { color: LATENCY_COLOR, width: 2 },
    marker: { color: LATENCY_COLOR }
  });
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

function parsePositionCsv(text) {
  const rows = text.trim().split(/\r?\n/);
  const data = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 29) continue;
    const t = parseTimestamp(f);
    const n = Number(f[10]);
    const e = Number(f[11]);
    const u = Number(f[12]);
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
    data.push({
      t, n, e, u, pdop, hdop, vdop, hprec, vprec, latency, solution, tracked, used,
      gpsWeek: gps.gpsWeek, gpsSec: gps.gpsSec
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
let plotFilterInfo = { filter: "unknown", mean: "unknown", meanName: "", meanRequest: "" };
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

function formatLocalTimestamp(unixSec) {
  const d = new Date(unixSec * 1000);
  const pad = (n) => String(n).padStart(2, "0");
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + " " +
    pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds());
}

function timePlotLayout(xaxisLayout, mode) {
  return {
    margin: {
      l: 60,
      r: 30,
      t: mode === "local" ? 58 : 50,
      b: 45
    },
    xaxis: xaxisLayout,
    legend: {
      orientation: "h",
      y: 1.02,
      x: 0,
      xanchor: "left",
      yanchor: "bottom"
    }
  };
}

function axisData(points, mode) {
  if (mode === "seconds") {
    const t0 = points[0].t;
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
  return {
    x: points.map((p) => new Date(p.t * 1000)),
    layout: {
      title: "Local Time (" + formatLocalTimestamp(points[0].t) + ")",
      type: "date",
      tickformat: "%H:%M:%S",
      hoverformat: "%Y-%m-%d %H:%M:%S"
    }
  };
}

function horizontalSigma(points) {
  return points.map((p) => (
    Number.isFinite(p.hprec) ? Math.sqrt(2) * p.hprec : null
  ));
}

function verticalSigma(points) {
  return points.map((p) => (Number.isFinite(p.vprec) ? p.vprec : null));
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

function ageCorrectionSeries(points) {
  const rows = points
    .filter((p) => Number.isFinite(p.latency) && p.latency >= 0)
    .map((p) => {
      const e1 = Math.abs(p.u);
      const e2 = Math.sqrt(p.n * p.n + p.e * p.e);
      const e3 = Math.sqrt(p.n * p.n + p.e * p.e + p.u * p.u);
      const hSigma = Number.isFinite(p.hprec)
        ? Math.sqrt(2 * Math.abs(p.hprec) * Math.abs(p.hprec))
        : null;
      const vSigma = Number.isFinite(p.vprec) ? Math.abs(p.vprec) : null;
      const d3Sigma = (hSigma != null && vSigma != null)
        ? Math.sqrt(hSigma * hSigma + vSigma * vSigma)
        : null;
      return {
        age: p.latency,
        e1,
        e2,
        e3,
        p1: vSigma,
        p2: hSigma,
        p3: d3Sigma
      };
    });

  return { rows, count: rows.length };
}

function binAgeCorrectionRows(rows, decimals) {
  const factor = Math.pow(10, decimals);
  const bins = new Map();
  const valueKeys = ["e1", "e2", "e3", "p1", "p2", "p3"];

  rows.forEach((row) => {
    const age = Math.round(row.age * factor) / factor;
    if (!bins.has(age)) {
      const entry = { age };
      valueKeys.forEach((key) => {
        entry[key + "Sum"] = 0;
        entry[key + "Count"] = 0;
      });
      bins.set(age, entry);
    }
    const bin = bins.get(age);
    valueKeys.forEach((key) => {
      const value = row[key];
      if (!Number.isFinite(value)) return;
      bin[key + "Sum"] += value;
      bin[key + "Count"] += 1;
    });
  });

  return Array.from(bins.values()).map((bin) => {
    const out = { age: bin.age };
    valueKeys.forEach((key) => {
      const count = bin[key + "Count"];
      out[key] = count > 0 ? bin[key + "Sum"] / count : null;
    });
    return out;
  }).sort((a, b) => a.age - b.age);
}

function plotAgeCorrectionChart(elementId, title, bins, errKey, sigKey, errName, sigName, colorKey) {
  const x = bins.map((b) => b.age);
  const color = ERROR_COLORS[colorKey];
  drawPlot(elementId, [
    { type: "scatter", x, y: bins.map((b) => b[errKey]), name: errName, mode: "lines", line: { color, width: 2 }, marker: { color } },
    {
      type: "scatter",
      x,
      y: bins.map((b) => b[sigKey]),
      name: sigName,
      mode: "lines",
      line: { color, width: 2, dash: "dot" },
      marker: { color }
    }
  ], {
    margin: { l: 65, r: 30, t: 40, b: 45 },
    title,
    xaxis: { title: "Age of Corrections (s)" },
    yaxis: { title: "Meters", rangemode: "tozero", zeroline: true },
    legend: { orientation: "h", itemclick: "toggle", itemdoubleclick: "toggleothers" }
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
  "plot-enu",
  "plot-enu-sigma",
  "plot-sigma-1d",
  "plot-sigma-2d",
  "plot-sigma-3d"
];

const TIME_LINKED_PLOT_IDS = [
  ...SOLUTION_TIME_PLOT_IDS,
  ...POSITION_TIME_PLOT_IDS
];

const ALL_PLOT_IDS = [
  ...TIME_LINKED_PLOT_IDS,
  ...AGE_CORRECTION_PLOT_IDS,
  "plot-latency-dist",
  "plot-cumulative",
  "plot-ne-scatter"
];

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

function relayoutWhenReady(elementId, update) {
  const result = Plotly.relayout(elementId, update);
  if (result && typeof result.then === "function") {
    return result;
  }
  return Promise.resolve();
}

function syncXRangeToPeers(sourceId, plotIds, range) {
  const key = rangeKey(range);
  if (!key) return;

  zoomSyncInProgress = true;
  zoomSyncSourceId = sourceId;
  lastSyncedRangeKey = key;

  const updates = plotIds
    .filter((targetId) => targetId !== sourceId)
    .map((targetId) => relayoutWhenReady(targetId, {
      "xaxis.autorange": false,
      "xaxis.range": range
    }));

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

      // Autorange/reset on one plot must not propagate; it causes relayout storms.
      if (eventData["xaxis.autorange"] === true) return;

      const x0 = eventData["xaxis.range[0]"];
      const x1 = eventData["xaxis.range[1]"];
      if (x0 === undefined || x1 === undefined) return;

      const range = [x0, x1];
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
        syncXRangeToPeers(sourceId, plotIds, range);
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
  for (const line of lines) {
    if (!line) continue;
    if (line.startsWith("mean_name:")) {
      meanName = line.slice(10);
    } else if (line.startsWith("mean_request:")) {
      meanRequest = line.slice(13);
    } else if (line.startsWith("mean:")) {
      mean = line.slice(5);
    } else {
      filter = line;
    }
  }
  return { filter, mean, meanName, meanRequest };
}

function meanTypeLabel(info) {
  if (info.mean === "all") return "all solution types";
  if (info.mean === "unknown") return "unknown";
  const used = info.meanName
    ? info.meanName + " (type " + info.mean + ")"
    : "type " + info.mean;
  if (info.meanRequest === "-1" || info.meanRequest === "") {
    return "automatic → " + used;
  }
  return used;
}

function renderPositionPlots(points, solutionPoints, mode, filterInfo) {
  if (!points.length) {
    document.getElementById("plot-status").textContent = "No position points found in position_data.csv.";
    document.getElementById("plot-status").className = "error";
    return;
  }

  purgeAllPlots();

  const solPoints = solutionPoints.length ? solutionPoints : points;
  const axis = axisData(points, mode);
  const solAxis = axisData(solPoints, mode);
  const x = axis.x;
  const solX = solAxis.x;
  const north = points.map((p) => Math.abs(p.n));
  const east = points.map((p) => Math.abs(p.e));
  const up = points.map((p) => Math.abs(p.u));
  const signedHeight = points.map((p) => (Number.isFinite(p.u) ? p.u : null));
  const err2d = d2(points);
  const err3d = d3(points);
  const latency = points.map((p) => (
    Number.isFinite(p.latency) && p.latency >= 0 ? p.latency : null
  ));
  const ratios = sigmaRatios(points);

  const commonLayout = timePlotLayout(axis.layout, mode);

  drawPlot("plot-solution-latency", [
    { x: solX, y: solPoints.map((p) => p.solution), name: "Solution Type", mode: "lines" },
    {
      x: solX,
      y: solPoints.map((p) => p.latency),
      name: "Latency (s)",
      mode: "lines",
      yaxis: "y2",
      line: { color: LATENCY_COLOR }
    }
  ], {
    ...timePlotLayout(solAxis.layout, mode),
    margin: { l: 100, r: 60, t: mode === "local" ? 58 : 50, b: 45 },
    title: "Solution and Latency Combined",
    yaxis: solutionYAxis(solPoints),
    yaxis2: { title: "Latency (s)", overlaying: "y", side: "right", automargin: true }
  });

  plotLatencyDistribution("plot-latency-dist", latencyDistribution(solPoints));

  drawPlot("plot-sv", [
    { x: solX, y: solPoints.map((p) => p.tracked), name: "Tracked", mode: "lines" },
    { x: solX, y: solPoints.map((p) => p.used), name: "Used", mode: "lines" }
  ], {
    ...commonLayout,
    xaxis: solAxis.layout,
    title: "SVs Used and Tracked",
    yaxis: { title: "SV Count" }
  });

  const heightTraces = [
    coloredLine(x, signedHeight, "Height Error", "up"),
    latencyTrace(x, latency),
    { ...vdopTrace(x, points, "y3"), visible: "legendonly" }
  ];
  const heightLayout = {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: 50 },
    title: "Height Error",
    yaxis: { title: "Height Error (m)", zeroline: true },
    yaxis2: { title: "Latency (s)", overlaying: "y", side: "right" },
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
  drawPlot("plot-height-error", heightTraces, heightLayout);

  drawPlot("plot-enu", [
    coloredLine(x, north, "North Error", "north"),
    coloredLine(x, east, "East Error", "east"),
    coloredLine(x, up, "Height Error", "up"),
    latencyTrace(x, latency)
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: 50 },
    title: "NEU Error",
    yaxis: { title: "Error (m)" },
    yaxis2: { title: "Latency (s)", overlaying: "y", side: "right" }
  });

  drawPlot("plot-enu-sigma", [
    coloredLine(x, err2d, "H Error", "d2"),
    coloredLine(x, up, "U Error", "up"),
    coloredLine(x, horizontalSigma(points), "H Sigma", "d2", { line: { dash: "dot" } }),
    coloredLine(x, verticalSigma(points), "V Sigma", "up", { line: { dash: "dot" } }),
    latencyTrace(x, latency)
  ], {
    ...commonLayout,
    margin: { ...commonLayout.margin, r: 50 },
    title: "H/U Error and Sigma",
    yaxis: { title: "Meters", rangemode: "tozero" },
    yaxis2: { title: "Latency (s)", overlaying: "y", side: "right" },
    legend: { ...commonLayout.legend, itemclick: "toggle", itemdoubleclick: "toggleothers" }
  });

  const usedSv = points.map((p) => (Number.isFinite(p.used) ? p.used : null));
  const maxUsedSv = Math.max(1, ...usedSv.filter(Number.isFinite));
  drawPlot("plot-ne-scatter", [{
    x: points.map((p) => p.e),
    y: points.map((p) => p.n),
    mode: "markers",
    name: "NE Error",
    marker: {
      size: usedSv.map((u) => (Number.isFinite(u) ? 4 + (u / maxUsedSv) * 12 : 4)),
      color: points.map((p) => p.pdop),
      colorscale: "Turbo",
      colorbar: { title: "PDOP" },
      showscale: true,
      opacity: 0.7
    },
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
  const cU = cumulativePercent(up);
  drawPlot("plot-cumulative", [
    coloredLine(cN.x, cN.y, "North Cumulative", "north"),
    coloredLine(cE.x, cE.y, "East Cumulative", "east"),
    coloredLine(cU.x, cU.y, "Height Cumulative", "up")
  ], {
    margin: { l: 60, r: 30, t: 40, b: 40 },
    title: "Cumulative Error Curves",
    xaxis: { title: "Error (m)" },
    yaxis: { title: "Percent (%)", range: [0, 100] },
    legend: { orientation: "h" }
  });

  const showDop1 = document.getElementById("show-dop-1d").checked;
  const showDop2 = document.getElementById("show-dop-2d").checked;
  const showDop3 = document.getElementById("show-dop-3d").checked;

  drawPlot("plot-sigma-1d", [
    coloredLine(x, ratios.r1d, "1D Error/Sigma", "up"),
    ...withDopTraces(showDop1, x, points)
  ], {
    ...commonLayout,
    title: "1D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  });

  drawPlot("plot-sigma-2d", [
    coloredLine(x, ratios.r2d, "2D Error/Sigma", "d2"),
    ...withDopTraces(showDop2, x, points)
  ], {
    ...commonLayout,
    title: "2D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  });

  drawPlot("plot-sigma-3d", [
    coloredLine(x, ratios.r3d, "3D Error/Sigma", "d3"),
    ...withDopTraces(showDop3, x, points)
  ], {
    ...commonLayout,
    title: "3D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  });

  const age = ageCorrectionSeries(points);
  const ageBins = binAgeCorrectionRows(age.rows, 1);
  plotAgeCorrectionChart(
    "plot-age-corr-1d",
    "1D Error and Sigma vs Age of Corrections",
    ageBins,
    "e1", "p1",
    "1D Error |U|", "1D Sigma (V)",
    "up"
  );
  plotAgeCorrectionChart(
    "plot-age-corr-2d",
    "2D Error and Sigma vs Age of Corrections",
    ageBins,
    "e2", "p2",
    "2D Error (H)", "2D Sigma (H)",
    "d2"
  );
  plotAgeCorrectionChart(
    "plot-age-corr-3d",
    "3D Error and Sigma vs Age of Corrections",
    ageBins,
    "e3", "p3",
    "3D Error", "3D Sigma",
    "d3"
  );

  linkTimePlotZoom(SOLUTION_TIME_PLOT_IDS);
  linkTimePlotZoom(POSITION_TIME_PLOT_IDS);

  const filterMode = filterInfo.filter;
  const typesShown = solutionTypesInData(points, solPoints);
  const filterNote = filterMode === "all"
    ? "Plot filter: all solution types."
    : filterMode.startsWith("type:")
      ? "Plot filter: solution type " + filterMode.split(":")[1] + "."
      : "Plot filter: unfiltered by solution type.";
  const viewFilterNote = typesShown.length > 1
    ? " View filter: " + typesShown.map(solutionTypeName).join(", ") + "."
    : "";
  const meanNote = "Mean computed from: " + meanTypeLabel(filterInfo) + ".";
  const solNote = solutionPoints.length
    ? "Error points: " + points.length + "; solution points: " + solutionPoints.length + "."
    : "Error points: " + points.length + ".";
  document.getElementById("plot-status").textContent =
    filterNote + viewFilterNote + " " + meanNote + " " + solNote + " Age-of-correction points: " + age.count +
    ". Zoom/pan on a time plot syncs others in the same group (solution or error plots).";
  document.getElementById("plot-status").className = "";
}

function attachPlotControlListeners() {
  if (plotListenersAttached) return;
  plotListenersAttached = true;

  document.getElementById("axis-mode").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-1d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-2d").addEventListener("change", rerenderPositionPlots);
  document.getElementById("show-dop-3d").addEventListener("change", rerenderPositionPlots);
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
      return resp.arrayBuffer().then((buf) =>
        gunzipToText(buf).catch(() => loadPlain())
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
  setPlotStatus("Loading interactive plot data...", "loading");

  const fetchStep = (label, url, optional) => {
    setPlotStatus(label, "loading");
    return fetchTextFile(url, optional);
  };

  fetchStep("Loading position data...", "position_data.csv")
    .then((posText) => fetchStep("Loading solution data...", "position_solution.csv", true)
      .then((solText) => fetchStep("Loading plot filter metadata...", "plot_filter.txt", true)
        .then((filterText) => ({ posText, solText, filterText }))))
    .then(({ posText, solText, filterText }) => {
      setPlotStatus("Parsing plot data...", "loading");
      const solutionPoints = solText ? parseX29Csv(solText) : [];
      allPositionPoints = attachSolutionTypes(parsePositionCsv(posText), solutionPoints);
      allSolutionPoints = solutionPoints;
      plotFilterInfo = parsePlotFilter(filterText);
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
