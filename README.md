# GNSS_Plotting

TrimbleTools GNSS plotting suite: position, tracking, and voltage analysis from T0x files.

## Components

| Path | Purpose |
|---|---|
| `cgi-bin/PositionPlot/` | Position/error plots, interactive Plotly reports, KML |
| `cgi-bin/TrackingPlot/` | SNR, cycle slips, satellite tracking plots |
| `cgi-bin/VoltagePlot/` | Power/voltage plots |
| `cgi-bin/T02_App/` | Configuration (cfg) extraction from T0x files |
| `cgi-bin/T02_Error/` | Error log extraction from T0x files |
| `cgi-bin/T02_Info/` | General information from T0x files |
| `HTML/` | Upload forms (`T02_2_PNG.html`, `T02_2_TRACKING.html`, `T02_App.html`, `T02_Error.html`, `T02_Info.html`) |
| `GNSS/` | Batch scripts for 24-hour processing pipelines |

## Requirements

- ViewDat (Trimble internal)
- Python 3.6+
- Perl with CGI
- gnuplot 5+ (tracking PNG plots)
- Plotly (browser CDN for interactive position plots)
- Highcharts (browser, for interactive tracking plots)

## Deployment

From the repository root on the web server:

```bash
sudo ./deploy.sh          # install CGI + HTML
sudo ./deploy.sh -n       # dry run
```

This syncs:

| Source | Destination |
|---|---|
| `cgi-bin/` | `/usr/lib/cgi-bin/` (`PositionPlot/`, `TrackingPlot/`, `VoltagePlot/`, `T02_App/`, `T02_Error/`, `T02_Info/`) |
| `HTML/T02_2_PNG.html` | `/var/www/html/T02_2_PNG.html` |
| `HTML/T02_2_TRACKING.html` | `/var/www/html/Tracking/T02_2_TRACKING.html` |
| `HTML/T02_App.html` | `/var/www/html/T02_App.html` |
| `HTML/T02_Error.html` | `/var/www/html/T02_Error.html` |
| `HTML/T02_Info.html` | `/var/www/html/T02_Info.html` |

Override paths with `CGI_DEST`, `HTML_DEST`, or `TRACKING_HTML_DEST` if needed. After deploy, **reprocess** sessions so result directories pick up symlinked `index.shtml` and updated JS.

See README files in `PositionPlot/` and `TrackingPlot/` for component-specific notes.

Previously hosted on Bitbucket as `geoffrey-kirk---gnss-plotting`.
