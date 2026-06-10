function parseTrackingSNR(text) {
  const rows = text.trim().split(/\r?\n/);
  const out = [];
  for (const row of rows) {
    if (!row) continue;
    const f = row.split(",");
    if (f.length < 6) continue;
    const t = Number(f[0]);
    const sv = Number(f[1]);
    const elev = Number(f[2]);
    const snr = Number(f[4]);
    const slip = Number(f[5]);
    if (!Number.isFinite(t) || !Number.isFinite(sv)) continue;
    out.push({ t, sv, elev, snr, slip });
  }
  return out;
}

function loadText(path) {
  return fetch(path, { cache: "no-store" }).then((r) => {
    if (!r.ok) throw new Error("Failed to load " + path);
    return r.text();
  });
}

function renderTracking(points, fileName) {
  const status = document.getElementById("tracking-status");
  if (!points.length) {
    status.textContent = "No tracking points found.";
    return;
  }

  const x = points.map((p) => new Date(p.t));
  const ySv = points.map((p) => p.sv);
  const snr = points.map((p) => p.snr);
  const elev = points.map((p) => p.elev);
  const slip = points.map((p) => p.slip);

  Plotly.newPlot(
    "tracking-plot-main",
    [{
      x,
      y: ySv,
      mode: "markers",
      marker: {
        color: snr,
        colorscale: "Viridis",
        colorbar: { title: "SNR" },
        size: 5
      },
      text: elev.map((e, i) => "Elev: " + e + "<br>Slip: " + slip[i]),
      hovertemplate: "Time: %{x}<br>SV: %{y}<br>%{text}<extra></extra>",
      name: fileName
    }],
    {
      title: "Tracking Scatter (" + fileName + ")",
      xaxis: { title: "Time" },
      yaxis: { title: "SV" },
      margin: { l: 60, r: 30, t: 45, b: 40 }
    },
    { responsive: true }
  );

  Plotly.newPlot(
    "tracking-plot-snr",
    [{
      x,
      y: snr,
      mode: "markers",
      marker: { size: 4 },
      name: "SNR"
    }],
    {
      title: "SNR vs Time (" + fileName + ")",
      xaxis: { title: "Time" },
      yaxis: { title: "SNR" },
      margin: { l: 60, r: 30, t: 45, b: 40 }
    },
    { responsive: true }
  );

  status.textContent = "Loaded " + points.length + " points from " + fileName + ".";
}

function loadInteractiveTracking() {
  if (typeof Plotly === "undefined") {
    document.getElementById("tracking-status").textContent = "Plotly failed to load.";
    return;
  }

  loadText("snr_files.txt")
    .then((text) => {
      const first = text.split(/\r?\n/).map((s) => s.trim()).filter(Boolean)[0];
      if (!first) throw new Error("snr_files.txt is empty");
      return loadText(first).then((snrText) => ({ first, snrText }));
    })
    .then(({ first, snrText }) => renderTracking(parseTrackingSNR(snrText), first))
    .catch((err) => {
      document.getElementById("tracking-status").textContent = "Interactive tracking unavailable: " + err.message;
    });
}
