/* SysLog.bin error/warning table view */
(function (global) {
  "use strict";

  var GPS_EPOCH_SEC = 315964800;
  var SECONDS_IN_WEEK = 604800;
  var GNSS_LEAP_SECONDS = 18;
  var INVALID_WEEK = 65535;
  var INVALID_MSECS = -1;

  function pad2(n) {
    return (n < 10 ? "0" : "") + n;
  }

  function pad3(n) {
    if (n < 10) return "00" + n;
    if (n < 100) return "0" + n;
    return String(n);
  }

  function gpsWeekMsecsToUnix(week, msecs) {
    return GPS_EPOCH_SEC + week * SECONDS_IN_WEEK + msecs / 1000 - GNSS_LEAP_SECONDS;
  }

  function formatUtcFull(unixSec) {
    var d = new Date(unixSec * 1000);
    return (
      d.getUTCFullYear() +
      "-" +
      pad2(d.getUTCMonth() + 1) +
      "-" +
      pad2(d.getUTCDate()) +
      " " +
      pad2(d.getUTCHours()) +
      ":" +
      pad2(d.getUTCMinutes()) +
      ":" +
      pad2(d.getUTCSeconds()) +
      "." +
      pad3(d.getUTCMilliseconds())
    );
  }

  function formatLocalFull(unixSec) {
    var d = new Date(unixSec * 1000);
    return (
      d.getFullYear() +
      "-" +
      pad2(d.getMonth() + 1) +
      "-" +
      pad2(d.getDate()) +
      " " +
      pad2(d.getHours()) +
      ":" +
      pad2(d.getMinutes()) +
      ":" +
      pad2(d.getSeconds()) +
      "." +
      pad3(d.getMilliseconds())
    );
  }

  function stripEchoNoise(line) {
    var s = line.replace(/\\n/g, "").replace(/\r/g, "");
    s = s.replace(/^\s*echo\s+/i, "");
    s = s.replace(/^["']|["']$/g, "");
    return s.trim();
  }

  function parseKeyValue(line) {
    var cleaned = stripEchoNoise(line);
    var m = cleaned.match(/^([^=]+?)\s*=\s*(.*)$/);
    if (!m) return null;
    return { key: m[1].trim(), value: m[2].trim() };
  }

  function extractListAddress(line) {
    var cleaned = stripEchoNoise(line);
    var m = cleaned.match(/^list\s+\*(0x[0-9a-fA-F]+)\s*$/i);
    return m ? m[1].toLowerCase() : null;
  }

  function isWarning(type) {
    return /warning/i.test(type || "");
  }

  function isError(type) {
    return /error/i.test(type || "");
  }

  function typeLabel(type) {
    if (isError(type)) return "Error";
    if (isWarning(type)) return "Warning";
    return type || "";
  }

  function parseErrLogText(text) {
    var lines = String(text || "").split(/\r?\n/);
    var meta = { rxSn: "", filename: "" };
    var entries = [];
    var current = null;
    var mode = "header"; /* header | fields | after-pc-flag | backtrace | userdata */

    function finishCurrent() {
      if (!current) return;
      var week = Number(current.week);
      var msecs = Number(current.msecs);
      current.weekNum = isFinite(week) ? week : NaN;
      current.msecsNum = isFinite(msecs) ? msecs : NaN;
      current.timeValid =
        isFinite(current.weekNum) &&
        isFinite(current.msecsNum) &&
        current.weekNum !== INVALID_WEEK &&
        current.msecsNum !== INVALID_MSECS;
      if (current.timeValid) {
        current.unix = gpsWeekMsecsToUnix(current.weekNum, current.msecsNum);
        current.utc = formatUtcFull(current.unix);
        current.local = formatLocalFull(current.unix);
      } else {
        current.unix = NaN;
        current.utc = "";
        current.local = "";
      }
      current.uptimeNum = Number(current.uptime);
      current.taskIdNum = Number(current.taskId);
      current.isWarning = isWarning(current.type);
      current.typeShort = typeLabel(current.type);
      current.pcDisplay = current.validPc && current.pc ? current.pc : "";
      current.backtraceText = current.backtrace.join("\n");
      if (current.userdata.length) {
        if (current.backtraceText) current.backtraceText += "\n";
        current.backtraceText += current.userdata.join("\n");
      }
      entries.push(current);
      current = null;
      mode = "header";
    }

    function startEntry() {
      finishCurrent();
      current = {
        errorCode: "",
        type: "",
        taskId: "",
        week: "",
        msecs: "",
        uptime: "",
        rxId: "",
        build: "",
        os: "",
        fwVersion: "",
        fwDate: "",
        validPc: false,
        pc: "",
        backtrace: [],
        userdata: []
      };
      mode = "fields";
    }

    for (var i = 0; i < lines.length; i++) {
      var raw = lines[i];
      var cleaned = stripEchoNoise(raw);
      if (!cleaned) continue;

      var snMatch = cleaned.match(/^RX\s+S\/N\s*=\s*(.+)$/i);
      if (snMatch) {
        meta.rxSn = snMatch[1].trim();
        continue;
      }

      var infoMatch = cleaned.match(/^Info for\s+(.+):\s*$/i);
      if (infoMatch) {
        meta.filename = infoMatch[1].trim();
        continue;
      }

      var kv = parseKeyValue(raw);
      if (kv && /^Error Code$/i.test(kv.key)) {
        startEntry();
        current.errorCode = kv.value;
        continue;
      }

      if (!current) continue;

      if (mode === "userdata") {
        var udKv = parseKeyValue(raw);
        if (udKv && /^Error Code$/i.test(udKv.key)) {
          startEntry();
          current.errorCode = udKv.value;
          continue;
        }
        current.userdata.push(cleaned);
        continue;
      }

      if (/^Backtrace$/i.test(cleaned)) {
        mode = "backtrace";
        continue;
      }

      if (/^Userdata$/i.test(cleaned)) {
        mode = "userdata";
        continue;
      }

      if (mode === "backtrace") {
        var btAddr = extractListAddress(raw);
        if (btAddr) {
          if (current.backtrace[current.backtrace.length - 1] !== btAddr) {
            current.backtrace.push(btAddr);
          }
          continue;
        }
        if (kv && /^Error Code$/i.test(kv.key)) {
          startEntry();
          current.errorCode = kv.value;
          continue;
        }
        continue;
      }

      if (mode === "after-pc-flag") {
        var pcAddr = extractListAddress(raw);
        if (pcAddr) {
          current.pc = pcAddr;
          mode = "fields";
          continue;
        }
        if (/^Backtrace$/i.test(cleaned)) {
          mode = "backtrace";
          continue;
        }
        mode = "fields";
      }

      if (kv) {
        var key = kv.key;
        var val = kv.value;
        if (/^Type$/i.test(key)) current.type = val;
        else if (/^Task ID$/i.test(key)) current.taskId = val;
        else if (/^crash week$/i.test(key)) current.week = val;
        else if (/^crash msecs$/i.test(key)) current.msecs = val;
        else if (/^Uptime$/i.test(key)) current.uptime = val;
        else if (/^RX ID$/i.test(key)) current.rxId = val;
        else if (/^Build$/i.test(key)) current.build = val;
        else if (/^OS$/i.test(key)) current.os = val;
        else if (/^F\/W Version$/i.test(key)) current.fwVersion = val;
        else if (/^F\/W Date$/i.test(key)) current.fwDate = val;
        else if (/^Valid PC$/i.test(key)) {
          current.validPc = val === "1" || /^true$/i.test(val);
          mode = current.validPc ? "after-pc-flag" : "fields";
        }
        continue;
      }

      var loneList = extractListAddress(raw);
      if (loneList && current.validPc && !current.pc) {
        current.pc = loneList;
      }
    }

    finishCurrent();
    return { meta: meta, entries: entries };
  }

  var COLUMNS = [
    { id: "type", label: "Type", sortable: true },
    { id: "errorCode", label: "Error Code", sortable: true },
    { id: "taskId", label: "Task ID", sortable: true },
    { id: "week", label: "Week", sortable: true },
    { id: "msecs", label: "Msecs", sortable: true },
    { id: "utc", label: "UTC", sortable: true },
    { id: "local", label: "Local", sortable: true },
    { id: "uptime", label: "Uptime", sortable: true },
    { id: "fwVersion", label: "F/W Version", sortable: true },
    { id: "fwDate", label: "F/W Date", sortable: true },
    { id: "pc", label: "PC", sortable: true },
    { id: "backtrace", label: "Backtrace", sortable: false }
  ];

  function compareEntries(a, b, colId, dir) {
    var mul = dir === "desc" ? -1 : 1;
    function cmpNum(x, y) {
      var nx = Number(x);
      var ny = Number(y);
      var fx = isFinite(nx);
      var fy = isFinite(ny);
      if (!fx && !fy) return 0;
      if (!fx) return 1;
      if (!fy) return -1;
      if (nx < ny) return -1;
      if (nx > ny) return 1;
      return 0;
    }
    function cmpStr(x, y) {
      var sx = String(x || "").toLowerCase();
      var sy = String(y || "").toLowerCase();
      if (sx < sy) return -1;
      if (sx > sy) return 1;
      return 0;
    }

    var result = 0;
    switch (colId) {
      case "type":
        result = cmpStr(a.typeShort, b.typeShort);
        break;
      case "errorCode":
        result = cmpStr(a.errorCode, b.errorCode);
        break;
      case "taskId":
        result = cmpNum(a.taskIdNum, b.taskIdNum);
        break;
      case "week":
        result = cmpNum(a.weekNum, b.weekNum);
        break;
      case "msecs":
        result = cmpNum(a.msecsNum, b.msecsNum);
        break;
      case "utc":
      case "local":
        result = cmpNum(a.unix, b.unix);
        break;
      case "uptime":
        result = cmpNum(a.uptimeNum, b.uptimeNum);
        break;
      case "fwVersion":
        result = cmpStr(a.fwVersion, b.fwVersion);
        break;
      case "fwDate":
        result = cmpStr(a.fwDate, b.fwDate);
        break;
      case "pc":
        result = cmpStr(a.pcDisplay, b.pcDisplay);
        break;
      default:
        result = 0;
    }
    return result * mul;
  }

  function cellText(entry, colId) {
    switch (colId) {
      case "type":
        return entry.typeShort;
      case "errorCode":
        return entry.errorCode;
      case "taskId":
        return entry.taskId;
      case "week":
        return entry.week;
      case "msecs":
        return entry.msecs;
      case "utc":
        return entry.utc || "—";
      case "local":
        return entry.local || "—";
      case "uptime":
        return entry.uptime;
      case "fwVersion":
        return entry.fwVersion;
      case "fwDate":
        return entry.fwDate;
      case "pc":
        return entry.pcDisplay || "—";
      case "backtrace":
        return entry.backtraceText;
      default:
        return "";
    }
  }

  function createController(options) {
    var rawText = options.rawText || "";
    var parsed = parseErrLogText(rawText);
    var hideWarnings = !!options.hideWarnings;
    var fwVersionFilter = options.fwVersionFilter || "";
    var sortCol = options.sortCol || "type";
    var sortDir = options.sortDir || "asc";
    var tableBody = options.tableBody;
    var tableHead = options.tableHead;
    var metaEl = options.metaEl;
    var countEl = options.countEl;
    var onStateChange = options.onStateChange || function () {};

    function uniqueFwVersions() {
      var seen = {};
      var list = [];
      parsed.entries.forEach(function (e) {
        var v = e.fwVersion || "";
        if (!v || seen[v]) return;
        seen[v] = true;
        list.push(v);
      });
      list.sort(function (a, b) {
        if (a < b) return 1;
        if (a > b) return -1;
        return 0;
      });
      return list;
    }

    function visibleEntries() {
      var list = parsed.entries.slice();
      if (hideWarnings) {
        list = list.filter(function (e) {
          return !e.isWarning;
        });
      }
      if (fwVersionFilter) {
        list = list.filter(function (e) {
          return e.fwVersion === fwVersionFilter;
        });
      }
      if (sortCol) {
        list.sort(function (a, b) {
          return compareEntries(a, b, sortCol, sortDir);
        });
      }
      return list;
    }

    function renderMeta() {
      if (!metaEl) return;
      var parts = [];
      if (parsed.meta.filename) parts.push(parsed.meta.filename);
      if (parsed.meta.rxSn) parts.push("RX S/N " + parsed.meta.rxSn);
      metaEl.textContent = parts.join(" · ");
    }

    function renderHead() {
      if (!tableHead) return;
      tableHead.innerHTML = "";
      var tr = document.createElement("tr");
      COLUMNS.forEach(function (col) {
        var th = document.createElement("th");
        th.textContent = col.label;
        th.setAttribute("scope", "col");
        if (col.sortable) {
          th.className = "sortable";
          th.setAttribute("role", "button");
          th.tabIndex = 0;
          if (sortCol === col.id) {
            th.className += sortDir === "desc" ? " sorted-desc" : " sorted-asc";
            th.textContent =
              col.label + (sortDir === "desc" ? " ▼" : " ▲");
          }
          th.addEventListener("click", function () {
            if (sortCol === col.id) {
              sortDir = sortDir === "asc" ? "desc" : "asc";
            } else {
              sortCol = col.id;
              sortDir = "asc";
            }
            render();
          });
          th.addEventListener("keydown", function (ev) {
            if (ev.key === "Enter" || ev.key === " ") {
              ev.preventDefault();
              th.click();
            }
          });
        } else {
          th.className = "not-sortable";
        }
        tr.appendChild(th);
      });
      tableHead.appendChild(tr);
    }

    function renderBody() {
      if (!tableBody) return;
      tableBody.innerHTML = "";
      var rows = visibleEntries();
      if (countEl) {
        countEl.textContent =
          rows.length +
          " of " +
          parsed.entries.length +
          " entr" +
          (parsed.entries.length === 1 ? "y" : "ies");
      }
      rows.forEach(function (entry) {
        var tr = document.createElement("tr");
        tr.className = entry.isWarning ? "row-warning" : "row-error";
        COLUMNS.forEach(function (col) {
          var td = document.createElement("td");
          var text = cellText(entry, col.id);
          if (col.id === "backtrace") {
            td.className = "backtrace-cell";
            var pre = document.createElement("pre");
            pre.textContent = text;
            td.appendChild(pre);
          } else if (col.id === "type") {
            td.className = entry.isWarning ? "type-warning" : "type-error";
            td.textContent = text;
          } else {
            td.textContent = text;
          }
          tr.appendChild(td);
        });
        tableBody.appendChild(tr);
      });
    }

    function render() {
      renderMeta();
      renderHead();
      renderBody();
      onStateChange({
        hideWarnings: hideWarnings,
        fwVersionFilter: fwVersionFilter,
        sortCol: sortCol,
        sortDir: sortDir,
        entryCount: parsed.entries.length
      });
    }

    return {
      render: render,
      setHideWarnings: function (value) {
        hideWarnings = !!value;
        render();
      },
      setFwVersionFilter: function (value) {
        fwVersionFilter = value || "";
        render();
      },
      getFwVersions: function () {
        return uniqueFwVersions();
      },
      getRawText: function () {
        return rawText;
      },
      getParsed: function () {
        return parsed;
      },
      toCsv: function () {
        var rows = visibleEntries();
        function esc(v) {
          var s = String(v == null ? "" : v);
          if (/[",\n\r]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
          return s;
        }
        var lines = [COLUMNS.map(function (c) { return esc(c.label); }).join(",")];
        rows.forEach(function (entry) {
          lines.push(
            COLUMNS.map(function (c) {
              return esc(cellText(entry, c.id));
            }).join(",")
          );
        });
        return lines.join("\n");
      }
    };
  }

  function downloadText(filename, text, mime) {
    var blob = new Blob([text], { type: mime || "text/plain;charset=utf-8" });
    var url = URL.createObjectURL(blob);
    var link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  function mount(root, rawText, downloadBaseName) {
    var hideCb = root.querySelector("[data-errlog-hide-warnings]");
    var fwSelect = root.querySelector("[data-errlog-fw-version]");
    var metaEl = root.querySelector("[data-errlog-meta]");
    var countEl = root.querySelector("[data-errlog-count]");
    var tableHead = root.querySelector("[data-errlog-thead]");
    var tableBody = root.querySelector("[data-errlog-tbody]");
    var downloadRawBtn = root.querySelector("[data-errlog-download-raw]");
    var downloadCsvBtn = root.querySelector("[data-errlog-download-csv]");
    var statusEl = root.querySelector("[data-errlog-status]");

    var controller = createController({
      rawText: rawText,
      hideWarnings: hideCb ? hideCb.checked : true,
      fwVersionFilter: fwSelect ? fwSelect.value : "",
      tableHead: tableHead,
      tableBody: tableBody,
      metaEl: metaEl,
      countEl: countEl
    });

    function baseName() {
      return downloadBaseName || "SysLog";
    }

    function showStatus(msg) {
      if (!statusEl) return;
      statusEl.textContent = msg || "";
      if (msg) {
        window.setTimeout(function () {
          statusEl.textContent = "";
        }, 2000);
      }
    }

    function populateFwVersions() {
      if (!fwSelect) return;
      var versions = controller.getFwVersions();
      var previous = fwSelect.value || "";
      fwSelect.innerHTML = "";
      var allOpt = document.createElement("option");
      allOpt.value = "";
      allOpt.textContent = "All F/W versions";
      fwSelect.appendChild(allOpt);
      versions.forEach(function (v) {
        var opt = document.createElement("option");
        opt.value = v;
        opt.textContent = v;
        fwSelect.appendChild(opt);
      });
      if (previous && versions.indexOf(previous) !== -1) {
        fwSelect.value = previous;
      } else {
        fwSelect.value = "";
      }
      fwSelect.disabled = versions.length === 0;
    }

    if (hideCb) {
      hideCb.onchange = function () {
        controller.setHideWarnings(hideCb.checked);
      };
      hideCb.checked = true;
      controller.setHideWarnings(true);
    }
    if (fwSelect) {
      populateFwVersions();
      fwSelect.onchange = function () {
        controller.setFwVersionFilter(fwSelect.value);
      };
    }
    if (downloadRawBtn) {
      downloadRawBtn.onclick = function () {
        downloadText(baseName() + "_errLog.txt", controller.getRawText());
        showStatus("Download started.");
      };
    }
    if (downloadCsvBtn) {
      downloadCsvBtn.onclick = function () {
        downloadText(baseName() + "_errLog.csv", controller.toCsv(), "text/csv;charset=utf-8");
        showStatus("CSV download started.");
      };
    }

    controller.render();
    return controller;
  }

  global.ErrLogView = {
    parse: parseErrLogText,
    mount: mount,
    downloadText: downloadText,
    COLUMNS: COLUMNS
  };
})(typeof window !== "undefined" ? window : this);
