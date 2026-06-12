function parsePositionCsv(text) {
  const rows = text.trim().split(/\r?\n/);
  const data = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 30) continue;
    const t = Number(f[1]);
    const solution = Number(f[2]);
    const tracked = Number(f[3]);
    const used = Number(f[4]);
    const n = Number(f[10]);
    const e = Number(f[11]);
    const u = Number(f[12]);
    const pdop = Number(f[18]);
    const hdop = Number(f[19]);
    const vdop = Number(f[20]);
    const hprec = Number(f[23]);
    const vprec = Number(f[24]);
    const latency = Number(f[28]);
    if (!Number.isFinite(t)) continue;
    data.push({
      t, solution, tracked, used, n, e, u, pdop, hdop, vdop, hprec, vprec, latency
    });
  }
  return data;
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

function axisData(points, mode) {
  if (mode === "seconds") {
    const t0 = points[0].t;
    return {
      x: points.map((p) => p.t - t0),
      layout: { title: "Seconds" }
    };
  }
  return {
    x: points.map((p) => new Date(p.t * 1000)),
    layout: { title: "Local Time" }
  };
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
    { x, y: points.map((p) => p.pdop), name: "PDOP", mode: "lines", yaxis: "y2" },
    { x, y: points.map((p) => p.hdop), name: "HDOP", mode: "lines", yaxis: "y2" },
    { x, y: points.map((p) => p.vdop), name: "VDOP", mode: "lines", yaxis: "y2" }
  ];
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

function renderPositionPlots(points, mode) {
  if (!points.length) {
    document.getElementById("plot-status").textContent = "No position points found in position_data.csv.";
    return;
  }

  const axis = axisData(points, mode);
  const x = axis.x;
  const north = points.map((p) => p.n);
  const east = points.map((p) => p.e);
  const up = points.map((p) => p.u);
  const err2d = d2(points);
  const err3d = d3(points);
  const ratios = sigmaRatios(points);

  const commonLayout = {
    margin: { l: 60, r: 30, t: 40, b: 40 },
    xaxis: axis.layout,
    legend: { orientation: "h" }
  };

  Plotly.newPlot("plot-solution-latency", [
    { x, y: points.map((p) => p.solution), name: "Solution Type", mode: "lines" },
    { x, y: points.map((p) => p.latency), name: "Latency (s)", mode: "lines", yaxis: "y2" }
  ], {
    ...commonLayout,
    title: "Solution and Latency Combined",
    yaxis: { title: "Solution Type" },
    yaxis2: { title: "Latency (s)", overlaying: "y", side: "right" }
  }, { responsive: true });

  Plotly.newPlot("plot-sv", [
    { x, y: points.map((p) => p.tracked), name: "Tracked", mode: "lines" },
    { x, y: points.map((p) => p.used), name: "Used", mode: "lines" }
  ], {
    ...commonLayout,
    title: "SVs Used and Tracked",
    yaxis: { title: "SV Count" }
  }, { responsive: true });

  Plotly.newPlot("plot-enu", [
    { x, y: north, name: "North Error", mode: "lines" },
    { x, y: east, name: "East Error", mode: "lines" },
    { x, y: up, name: "Height Error", mode: "lines" }
  ], { ...commonLayout, title: "NEU Error vs Time", yaxis: { title: "Error (m)" } }, { responsive: true });

  Plotly.newPlot("plot-2d3d", [
    { x, y: err2d, name: "2D Error", mode: "lines" },
    { x, y: err3d, name: "3D Error", mode: "lines" }
  ], { ...commonLayout, title: "2D/3D Error vs Time", yaxis: { title: "Error (m)" } }, { responsive: true });

  const cN = cumulativePercent(north.map(Math.abs));
  const cE = cumulativePercent(east.map(Math.abs));
  const cU = cumulativePercent(up.map(Math.abs));
  const c2 = cumulativePercent(err2d);
  const c3 = cumulativePercent(err3d);
  Plotly.newPlot("plot-cumulative", [
    { x: cN.x, y: cN.y, name: "North Cumulative", mode: "lines" },
    { x: cE.x, y: cE.y, name: "East Cumulative", mode: "lines" },
    { x: cU.x, y: cU.y, name: "Height Cumulative", mode: "lines" },
    { x: c2.x, y: c2.y, name: "2D Cumulative", mode: "lines" },
    { x: c3.x, y: c3.y, name: "3D Cumulative", mode: "lines" }
  ], {
    margin: { l: 60, r: 30, t: 40, b: 40 },
    title: "Cumulative Error Curves",
    xaxis: { title: "Error (m)" },
    yaxis: { title: "Percent (%)", range: [0, 100] },
    legend: { orientation: "h" }
  }, { responsive: true });

  const showDop1 = document.getElementById("show-dop-1d").checked;
  const showDop2 = document.getElementById("show-dop-2d").checked;
  const showDop3 = document.getElementById("show-dop-3d").checked;

  Plotly.newPlot("plot-sigma-1d", [
    { x, y: ratios.r1d, name: "1D Error/Sigma", mode: "lines" },
    ...withDopTraces(showDop1, x, points)
  ], {
    ...commonLayout,
    title: "1D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  }, { responsive: true });

  Plotly.newPlot("plot-sigma-2d", [
    { x, y: ratios.r2d, name: "2D Error/Sigma", mode: "lines" },
    ...withDopTraces(showDop2, x, points)
  ], {
    ...commonLayout,
    title: "2D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  }, { responsive: true });

  Plotly.newPlot("plot-sigma-3d", [
    { x, y: ratios.r3d, name: "3D Error/Sigma", mode: "lines" },
    ...withDopTraces(showDop3, x, points)
  ], {
    ...commonLayout,
    title: "3D Sigma Ratio",
    yaxis: { title: "Ratio" },
    yaxis2: { title: "DOP", overlaying: "y", side: "right", showgrid: false }
  }, { responsive: true });

  document.getElementById("plot-status").textContent = "Loaded " + points.length + " points.";
}

function loadInteractivePosition() {
  if (typeof Plotly === "undefined") {
    document.getElementById("plot-status").textContent = "Plotly failed to load. Check internet access or host Plotly locally.";
    return;
  }
  fetch("position_data.csv", { cache: "no-store" })
    .then((r) => {
      if (!r.ok) throw new Error("Failed to load position_data.csv");
      return r.text();
    })
    .then((text) => {
      const points = parsePositionCsv(text);
      const axisMode = document.getElementById("axis-mode");
      const rerender = () => renderPositionPlots(points, axisMode.value);
      axisMode.addEventListener("change", rerender);
      document.getElementById("show-dop-1d").addEventListener("change", rerender);
      document.getElementById("show-dop-2d").addEventListener("change", rerender);
      document.getElementById("show-dop-3d").addEventListener("change", rerender);
      rerender();
    })
    .catch((err) => {
      document.getElementById("plot-status").textContent = "Interactive plot unavailable: " + err.message;
    });
}
