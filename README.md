# GNSS_Plotting

TrimbleTools GNSS plotting suite: position, tracking, and voltage analysis from T0x files.

## Components

| Path | Purpose |
|---|---|
| `cgi-bin/PositionPlot/` | Position/error plots, interactive Plotly reports, KML |
| `cgi-bin/TrackingPlot/` | SNR, cycle slips, satellite tracking plots |
| `cgi-bin/VoltagePlot/` | Power/voltage plots |
| `HTML/` | Upload forms (`T02_2_PNG.html`, `T02_2_TRACKING.html`) |
| `GNSS/` | Batch scripts for 24-hour processing pipelines |

## Requirements

- ViewDat (Trimble internal)
- Python 3.6+
- Perl with CGI
- gnuplot 5+ (tracking PNG plots)
- Plotly (browser CDN for interactive position plots)
- Highcharts (browser, for interactive tracking plots)

## Deployment

Scripts under each `cgi-bin/*Plot/` directory are deployed to the web server CGI path (e.g. `cgi-bin/PositionPlot/`). See README files in `PositionPlot/` and `TrackingPlot/` for component-specific install notes.

Previously hosted on Bitbucket as `geoffrey-kirk---gnss-plotting`.
