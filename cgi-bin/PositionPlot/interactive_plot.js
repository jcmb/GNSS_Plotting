function parsePositionCsv(text) {
  const rows = text.trim().split(/\r?\n/);
  const data = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 25) continue;
    const t = Number(f[1]);
    const n = Number(f[10]);
    const e = Number(f[11]);
    const u = Number(f[12]);
    const pdop = Number(f[18]);
    const vdop = Number(f[20]);
    const hprec = Number(f[23]);
    const vprec = Number(f[24]);
    if (!Number.isFinite(t)) continue;
    data.push({ t, n, e, u, pdop, vdop, hprec, vprec });
  }
  return data;
}

function toDates(points) {
  return points.map((p) => new Date(p.t * 1000));
}

function compute2d(points) {
  return points.map((p) => Math.sqrt(p.n * p.n + p.e * p.e));
}

function compute3d(points) {
  return points.map((p) => Math.sqrt(p.n * p.n + p.e * p.e + p.u * p.u));
}

function renderPositionPlots(points) {
  if (!points.length) {
    document.getElementById("plot-status").textContent = "No position points found in position_data.csv.";
    return;
  }

  const x = toDates(points);
  const north = points.map((p) => p.n);
  const east = points.map((p) => p.e);
  const up = points.map((p) => p.u);
  const d2 = compute2d(points);
  const d3 = compute3d(points);
  const pdop = points.map((p) => p.pdop);
  const vdop = points.map((p) => p.vdop);

  const commonLayout = {
    margin: { l: 60, r: 30, t: 40, b: 40 },
    xaxis: { title: "Time" },
    legend: { orientation: "h" }
  };

  Plotly.newPlot("plot-enu", [
    { x, y: north, name: "North Error", mode: "lines" },
    { x, y: east, name: "East Error", mode: "lines" },
    { x, y: up, name: "Height Error", mode: "lines" }
  ], { ...commonLayout, title: "NEU Error vs Time", yaxis: { title: "Error (m)" } }, { responsive: true });

  Plotly.newPlot("plot-2d3d", [
    { x, y: d2, name: "2D Error", mode: "lines" },
    { x, y: d3, name: "3D Error", mode: "lines" }
  ], { ...commonLayout, title: "2D/3D Error vs Time", yaxis: { title: "Error (m)" } }, { responsive: true });

  Plotly.newPlot("plot-dop", [
    { x, y: pdop, name: "PDOP", mode: "lines" },
    { x, y: vdop, name: "VDOP", mode: "lines" }
  ], { ...commonLayout, title: "DOP vs Time", yaxis: { title: "DOP" } }, { responsive: true });

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
      renderPositionPlots(points);
    })
    .catch((err) => {
      document.getElementById("plot-status").textContent = "Interactive plot unavailable: " + err.message;
    });
}
