function parseVoltageCsv(text) {
  const rows = text.trim().split(/\r?\n/);
  const points = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 7) continue;
    const t = Number(f[0]);
    if (!Number.isFinite(t)) continue;
    points.push({
      t,
      ext1: Number(f[1]),
      ext2: Number(f[2]),
      batt: Number(f[3]),
      temp: Number(f[6])
    });
  }
  return points;
}

function renderVoltage(points) {
  const status = document.getElementById("plot-status");
  if (!points.length) {
    status.textContent = "No voltage points found.";
    return;
  }

  const x = points.map((p) => new Date(p.t * 1000));
  const ext1 = points.map((p) => p.ext1);
  const ext2 = points.map((p) => p.ext2);
  const batt = points.map((p) => p.batt);
  const temp = points.map((p) => p.temp);

  Plotly.newPlot(
    "plot-voltage",
    [
      { x, y: ext1, name: "External 1", mode: "lines" },
      { x, y: ext2, name: "External 2", mode: "lines" },
      { x, y: batt, name: "Battery", mode: "lines" }
    ],
    {
      title: "Voltage vs Time",
      xaxis: { title: "Time" },
      yaxis: { title: "Voltage" },
      margin: { l: 60, r: 20, t: 45, b: 40 }
    },
    { responsive: true }
  );

  Plotly.newPlot(
    "plot-voltage-temp",
    [
      { x, y: ext1, name: "External 1", mode: "lines" },
      { x, y: ext2, name: "External 2", mode: "lines" },
      { x, y: batt, name: "Battery", mode: "lines" },
      { x, y: temp, name: "Temperature", mode: "lines", yaxis: "y2" }
    ],
    {
      title: "Voltage and Temperature vs Time",
      xaxis: { title: "Time" },
      yaxis: { title: "Voltage" },
      yaxis2: { title: "Temperature (C)", overlaying: "y", side: "right" },
      margin: { l: 60, r: 60, t: 45, b: 40 }
    },
    { responsive: true }
  );

  status.textContent = "Loaded " + points.length + " voltage points.";
}

function loadInteractiveVoltage() {
  if (typeof Plotly === "undefined") {
    document.getElementById("plot-status").textContent = "Plotly failed to load.";
    return;
  }
  fetch("voltage_data.csv", { cache: "no-store" })
    .then((r) => {
      if (!r.ok) throw new Error("Failed to load voltage_data.csv");
      return r.text();
    })
    .then((text) => renderVoltage(parseVoltageCsv(text)))
    .catch((err) => {
      document.getElementById("plot-status").textContent = "Interactive plot unavailable: " + err.message;
    });
}
