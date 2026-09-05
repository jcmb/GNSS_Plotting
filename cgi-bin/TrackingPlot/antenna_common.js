var trackedAntennas = ["0"];
var selectedAntenna = "0";
var RX_PARAM = "RX";
var MODE_PARAM = "MODE";
var COMPARE_ANTENNAS = ["0", "1", "2"];

var ANTENNA_COLORS = {
    "0": "#007bff",
    "1": "#ff7f0e",
    "2": "#2ca02c"
};

var textFileCache = {};

function getURLParameter(name) {
    var match = RegExp(name + '=' + '(.+?)(&|$)').exec(location.search);
    if (!match || match[1] == null) {
        return "null";
    }
    return decodeURIComponent(match[1]);
}

function urlParameterPresent(value) {
    return value && value !== "null";
}

function isCompareMode() {
    return getURLParameter(MODE_PARAM) === "compare";
}

function isTripleAntennaLayout(antennas) {
    if (!antennas || antennas.length !== 3) {
        return false;
    }
    var sorted = sortAntennaIds(antennas);
    return sorted[0] === "0" && sorted[1] === "1" && sorted[2] === "2";
}

function antennaLabel(id) {
    id = String(id);
    if (id === "2") {
        return "Combination (2)";
    }
    return "Antenna " + id;
}

function antennaColor(id) {
    return ANTENNA_COLORS[String(id)] || "#666666";
}

function parseAntennaList(data) {
    return data.split('\n').map(function(line) {
        return line.replace(/\r/g, '').trim();
    }).filter(function(line) {
        return line.length > 0;
    });
}

function sortAntennaIds(antennas) {
    return antennas.slice().sort(function(a, b) {
        return parseInt(a, 10) - parseInt(b, 10);
    });
}

function hasMultipleAntennas(antennas) {
    return antennas && antennas.length > 1;
}

function normalizeAntennaList(antennas) {
    if (!antennas || antennas.length === 0) {
        return ["0"];
    }
    if (!hasMultipleAntennas(antennas)) {
        return ["0"];
    }
    return sortAntennaIds(antennas);
}

function loadAntennasFromBands(callback, fallback) {
    $.ajax({
        url: "Tracked.Bands",
        cache: false,
        dataType: "text"
    }).done(function(data) {
        var seen = {};
        var antennas = [];
        parseAntennaList(data).forEach(function(line) {
            var match = line.match(/^Ant([0-9]+)-/);
            if (match && !seen[match[1]]) {
                seen[match[1]] = true;
                antennas.push(match[1]);
            }
        });
        if (!hasMultipleAntennas(antennas)) {
            callback(fallback);
            return;
        }
        callback(sortAntennaIds(antennas));
    }).fail(function() {
        callback(fallback);
    });
}

function setAntennaContext(antennas, antenna) {
    trackedAntennas = antennas;
    selectedAntenna = antenna;
}

function loadTrackedAntennas(callback) {
    $.ajax({
        url: "Tracked.Rx",
        cache: false,
        dataType: "text"
    }).done(function(data) {
        var antennas = normalizeAntennaList(parseAntennaList(data));
        callback(antennas);
    }).fail(function() {
        loadAntennasFromBands(function(antennas) {
            callback(normalizeAntennaList(antennas));
        }, ["0"]);
    });
}

function antennaUsesPrefix(antennas, antenna) {
    if (antennas.length <= 1 && antenna === "0") {
        return false;
    }
    return true;
}

function antennaFilePrefix(antennas, antenna) {
    if (!antennaUsesPrefix(antennas, antenna)) {
        return "";
    }
    return "Ant" + antenna + "-";
}

function bandBaseName(trackedLine, antennaPrefix) {
    if (antennaPrefix && trackedLine.indexOf(antennaPrefix) === 0) {
        return trackedLine.substring(antennaPrefix.length);
    }
    if (!antennaPrefix && trackedLine.match(/^Ant[0-9]+-/)) {
        return trackedLine.replace(/^Ant[0-9]+-/, "");
    }
    return trackedLine;
}

function currentQueryParts() {
    return location.search.replace(/^\?/, "").split("&").filter(function(part) {
        return part.length > 0;
    });
}

function stripQueryParams(parts, names) {
    return parts.filter(function(part) {
        for (var i = 0; i < names.length; i++) {
            if (part.indexOf(names[i] + "=") === 0) {
                return false;
            }
        }
        return true;
    });
}

function appendAntennaQuery(url, antenna, antennas) {
    if (!antennas || antennas.length <= 1) {
        return url;
    }
    if (url.indexOf("?") >= 0) {
        return url + "&" + RX_PARAM + "=" + encodeURIComponent(antenna);
    }
    return url + "?" + RX_PARAM + "=" + encodeURIComponent(antenna);
}

function buildPlotSearch(antennas, antenna, compare) {
    var params = stripQueryParams(currentQueryParts(), [RX_PARAM, MODE_PARAM]);
    if (hasMultipleAntennas(antennas)) {
        if (compare) {
            params.push(MODE_PARAM + "=compare");
        } else {
            params.push(RX_PARAM + "=" + encodeURIComponent(antenna));
        }
    }
    return params.length ? "?" + params.join("&") : "";
}

function navigatePlot(url) {
    if (isCompareMode() && isTripleAntennaLayout(trackedAntennas)) {
        var base = url.split("?")[0];
        var extra = url.indexOf("?") >= 0 ? url.split("?")[1] : "";
        var params = stripQueryParams(extra ? extra.split("&") : [], [RX_PARAM, MODE_PARAM]);
        params.push(MODE_PARAM + "=compare");
        location.href = base + "?" + params.join("&");
        return;
    }
    location.href = appendAntennaQuery(url, selectedAntenna, trackedAntennas);
}

function navigateView(antennas, antenna, compare) {
    location.search = buildPlotSearch(antennas, antenna, compare);
}

function renderAntennaSelector(containerId, antennas, antenna, onChange) {
    var container = $("#" + containerId);
    if (!hasMultipleAntennas(antennas)) {
        container.empty().hide();
        return;
    }

    container.show();
    var html = "<p><strong>View:</strong> ";
    var compareMode = isCompareMode();
    var ids = isTripleAntennaLayout(antennas) ? COMPARE_ANTENNAS : antennas;

    for (var i = 0; i < ids.length; i++) {
        var id = String(ids[i]);
        var label = antennaLabel(id);
        if (!compareMode && id === String(antenna)) {
            html += "<strong>" + label + "</strong> ";
        } else {
            html += "<a href=\"#\" data-antenna=\"" + id + "\">" + label + "</a> ";
        }
    }

    if (isTripleAntennaLayout(antennas)) {
        if (compareMode) {
            html += "<strong>Compare</strong>";
        } else {
            html += "<a href=\"#\" data-compare=\"1\">Compare</a>";
        }
    }

    html += "</p>";
    container.html(html);
    container.find("a[data-antenna]").click(function(event) {
        event.preventDefault();
        onChange($(this).attr("data-antenna"), false);
    });
    container.find("a[data-compare]").click(function(event) {
        event.preventDefault();
        onChange(antenna, true);
    });
}

function initAntennaPage(containerId, onReady) {
    loadTrackedAntennas(function(antennas) {
        antennas = normalizeAntennaList(antennas);
        var compareMode = isCompareMode() && isTripleAntennaLayout(antennas);
        var antennaParam = getURLParameter(RX_PARAM);
        var antenna = antennas[0];
        if (!compareMode && hasMultipleAntennas(antennas) && urlParameterPresent(antennaParam)) {
            antenna = antennaParam;
        }
        setAntennaContext(antennas, antenna);
        renderAntennaSelector(containerId, antennas, antenna, function(newAntenna, compare) {
            if (!hasMultipleAntennas(antennas)) {
                return;
            }
            navigateView(antennas, newAntenna, compare);
        });
        onReady(antennas, antenna, compareMode);
    });
}

function trackedLineMatchesAntenna(line, antennas, antenna) {
    var prefix = antennaFilePrefix(antennas, antenna);
    if (prefix) {
        return line.indexOf(prefix) === 0;
    }
    return !line.match(/^Ant[0-9]+-/);
}

function svButtonId(line, antennas, antenna) {
    var prefix = antennaFilePrefix(antennas, antenna);
    return bandBaseName(line, prefix);
}

function highchartsMajorVersion() {
    if (typeof Highcharts === "undefined" || !Highcharts.version) {
        return 7;
    }
    return parseInt(String(Highcharts.version).split(".")[0], 10) || 7;
}

function interactiveChartOptions(overrides) {
    var major = highchartsMajorVersion();
    var chart = {
        resetZoomButton: {
            theme: {
                display: "block"
            }
        }
    };

    if (major >= 8) {
        chart.zooming = { type: "xy" };
        chart.panning = { enabled: true, type: "xy" };
        chart.panKey = "shift";
    } else {
        chart.zoomType = "xy";
        chart.panning = true;
        chart.panKey = "shift";
    }

    return $.extend(true, {
        chart: chart,
        exporting: {
            enabled: true
        }
    }, overrides || {});
}

function loadTextFile(url) {
    if (textFileCache[url]) {
        return textFileCache[url];
    }
    textFileCache[url] = $.ajax({
        url: url,
        cache: false,
        dataType: "text"
    });
    return textFileCache[url];
}

function bandFileName(antennas, antenna, system, freq, signal, ext) {
    return antennaFilePrefix(antennas, antenna) + system + "-" + freq + "-" + signal + ext;
}

function svFileName(antennas, antenna, system, sv, ext) {
    return antennaFilePrefix(antennas, antenna) + system + "-" + sv + ext;
}

function parseMeanRows(data) {
    var rows = [];
    parseAntennaList(data).forEach(function(line) {
        var items = line.split(',');
        if (!items[0]) {
            return;
        }
        rows.push({
            elevation: parseFloat(items[0]),
            count: parseFloat(items[1]),
            mean: parseFloat(items[2]),
            sigma: parseFloat(items[3]),
            min: parseFloat(items[4]),
            max: parseFloat(items[5])
        });
    });
    return rows;
}

function parseSnrRows(data) {
    var rows = [];
    data.split('\n').forEach(function(line) {
        line = line.replace(/\r/g, '');
        if (!line) {
            return;
        }
        var items = line.split(',');
        if (!items[0]) {
            return;
        }
        rows.push({
            epoch: items[0],
            sv: parseInt(items[1], 10),
            elev: parseInt(items[2], 10),
            az: parseInt(items[3], 10),
            snr: parseFloat(items[4]),
            slip: parseInt(items[5], 10)
        });
    });
    return rows;
}

function parseSvSnrRows(data, maxBands) {
    var rows = [];
    data.split('\n').forEach(function(line) {
        line = line.replace(/\r/g, '');
        if (!line) {
            return;
        }
        var items = line.split(',');
        if (!items[0]) {
            return;
        }
        var row = {
            epoch: items[0],
            elev: parseFloat(items[1]),
            az: items[2],
            bands: []
        };
        for (var i = 1; i <= maxBands; i++) {
            var snr = items[1 + (i * 2)];
            var slip = items[2 + (i * 2)];
            row.bands.push({
                snr: snr ? parseFloat(snr) : null,
                slip: slip ? parseInt(slip, 10) : null
            });
        }
        rows.push(row);
    });
    return rows;
}

function loadBandMean(antennas, antenna, system, freq, signal) {
    var url = bandFileName(antennas, antenna, system, freq, signal, ".MEAN");
    return loadTextFile(url).then(parseMeanRows);
}

function bandButtonClasses(bandClass) {
    var classes = [bandClass];
    if (bandClass.indexOf("GAL-E1-") === 0) {
        classes.push(bandClass.replace("GAL-E1-", "GAL-L1-"));
    }
    return classes;
}

function enableBandClass(container, bandClass) {
    $(container).find('[class~="' + bandClass + '"]').prop("disabled", false);
}

function loadBandSnr(antennas, antenna, system, freq, signal) {
    var url = bandFileName(antennas, antenna, system, freq, signal, ".SNR");
    return loadTextFile(url).then(parseSnrRows).fail(function() {
        if (system === "GAL" && freq === "L1") {
            return loadTextFile(
                bandFileName(antennas, antenna, system, "E1", signal, ".SNR")
            ).then(parseSnrRows);
        }
        return $.Deferred().reject().promise();
    });
}

function loadSvSnr(antennas, antenna, system, sv, maxBands) {
    var url = svFileName(antennas, antenna, system, sv, ".SNR-SV");
    return loadTextFile(url).then(function(data) {
        return parseSvSnrRows(data, maxBands);
    });
}

function alignRowsByKey(rowsA, rowsB, keyFn) {
    var mapB = {};
    rowsB.forEach(function(row) {
        mapB[keyFn(row)] = row;
    });
    var aligned = [];
    rowsA.forEach(function(rowA) {
        var key = keyFn(rowA);
        if (mapB[key]) {
            aligned.push({ a: rowA, b: mapB[key], key: key });
        }
    });
    return aligned;
}

function diffNumeric(a, b) {
    if (a === null || a === undefined || b === null || b === undefined) {
        return null;
    }
    if (isNaN(a) || isNaN(b)) {
        return null;
    }
    return a - b;
}

function whenAll(requests) {
    var deferred = $.Deferred();
    if (!requests.length) {
        deferred.resolve([]);
        return deferred.promise();
    }
    $.when.apply($, requests).done(function() {
        var results = [];
        for (var i = 0; i < requests.length; i++) {
            results.push(arguments[i]);
        }
        deferred.resolve(results);
    }).fail(function() {
        deferred.reject.apply(deferred, arguments);
    });
    return deferred.promise();
}

function compareAntennaIds(antennas) {
    if (isTripleAntennaLayout(antennas)) {
        return COMPARE_ANTENNAS.slice();
    }
    return [selectedAntenna];
}

function meanSeriesFromRows(rows) {
    var points = [];
    rows.forEach(function(row) {
        if (row.count > 0 && !isNaN(row.mean)) {
            points.push([row.elevation, row.mean]);
        }
    });
    return points;
}

function diffMeanSeries(rowsA, rowsB) {
    var aligned = alignRowsByKey(rowsA, rowsB, function(row) {
        return String(row.elevation);
    });
    var points = [];
    aligned.forEach(function(pair) {
        var delta = diffNumeric(pair.a.mean, pair.b.mean);
        if (delta !== null) {
            points.push([pair.a.elevation, delta]);
        }
    });
    return points;
}

function bandNamesForSystem(System, maxBands) {
    if (System === "GPS") {
        return ["L1 C/A", "L2 E", "L2 CS", "L5 IQ"].slice(0, maxBands);
    }
    if (System === "GLONASS") {
        return ["L1 C/A", "L1 P", "L2 C/A", "L2 P"].slice(0, maxBands);
    }
    if (System === "GAL") {
        return ["E1 C/A", "E5 AltBoc"].slice(0, maxBands);
    }
    if (System === "BDS") {
        return ["B1", "B2a", "B2b", "B2I", "B3"].slice(0, maxBands);
    }
    if (System === "SBAS") {
        return ["L1 C/A", "L5 IQ"].slice(0, maxBands);
    }
    var names = [];
    for (var i = 1; i <= maxBands; i++) {
        names.push("Band " + i);
    }
    return names;
}

function maxBandsForSystem(System) {
    if (System === "GPS") {
        return 4;
    }
    if (System === "GLONASS") {
        return 4;
    }
    if (System === "BDS") {
        return 5;
    }
    if (System === "GAL" || System === "SBAS") {
        return 2;
    }
    return 2;
}

function trackingLimits(System) {
    var Min_SVs = 1;
    var Max_SVs = 1;
    if (System === "GPS") {
        Max_SVs = 32;
    } else if (System === "GAL") {
        Max_SVs = 36;
    } else if (System === "GLONASS") {
        Max_SVs = 24;
    } else if (System === "SBAS") {
        Min_SVs = 120;
        Max_SVs = 158;
    } else if (System === "BDS") {
        Max_SVs = 63;
    }
    return { min: Min_SVs, max: Max_SVs };
}

var ALL_SV_TRACKING_LAYOUT = [
    { system: "GPS", yOffset: 0, svMax: 32, color: "#1f77b4" },
    { system: "GLONASS", yOffset: 40, svMax: 24, color: "#ff7f0e" },
    { system: "GAL", yOffset: 70, svMax: 36, color: "#9467bd" },
    { system: "BDS", yOffset: 110, svMax: 63, color: "#d62728" },
    { system: "SBAS", yOffset: 200, svMax: 158, svDisplayOffset: 120, color: "#e377c2" },
    { system: "QZSS", yOffset: 250, svMax: 10, color: "#8c564b" }
];

function allSvTrackingBlock(system) {
    for (var i = 0; i < ALL_SV_TRACKING_LAYOUT.length; i++) {
        if (ALL_SV_TRACKING_LAYOUT[i].system === system) {
            return ALL_SV_TRACKING_LAYOUT[i];
        }
    }
    return null;
}

function allSvTrackingY(system, sv) {
    var block = allSvTrackingBlock(system);
    if (!block) {
        return sv;
    }
    if (block.svDisplayOffset) {
        return block.yOffset + (sv - block.svDisplayOffset);
    }
    return block.yOffset + sv;
}

function allSvTrackingYRange() {
    return { min: 0, max: 270 };
}

function parseTrackedBandLine(line, antennas, antenna) {
    if (!trackedLineMatchesAntenna(line, antennas, antenna)) {
        return null;
    }
    var base = bandBaseName(line, antennaFilePrefix(antennas, antenna));
    var match = base.match(/^([^-]+)-([^-]+)-(.+)$/);
    if (!match) {
        return null;
    }
    return {
        system: match[1],
        freq: match[1] === "GAL" && match[2] === "E1" ? "L1" : match[2],
        signal: match[3],
        label: match[1] + " " + match[2] + "-" + match[3]
    };
}

function loadTrackedBands(antennas, antenna) {
    return loadTextFile("Tracked.Bands").then(function(data) {
        var bands = [];
        parseAntennaList(data).forEach(function(line) {
            var band = parseTrackedBandLine(line, antennas, antenna);
            if (band) {
                bands.push(band);
            }
        });
        return bands;
    });
}

function allSvTrackingSeriesIndex(system) {
    for (var i = 0; i < ALL_SV_TRACKING_LAYOUT.length; i++) {
        if (ALL_SV_TRACKING_LAYOUT[i].system === system) {
            return i;
        }
    }
    return -1;
}

function appendAllSvTrackingPoint(seriesBySystem, row, bandLabel, lastSlipState) {
    var index = allSvTrackingSeriesIndex(row.system);
    if (index < 0) {
        return;
    }
    var slipKey = row.system + "-" + row.sv;
    var currentSlip = row.slip;
    var point = {
        x: row.epoch,
        y: allSvTrackingY(row.system, row.sv),
        system: row.system,
        sv: row.sv,
        elev: row.elev,
        az: row.az,
        snr: row.snr,
        band: bandLabel
    };
    if (lastSlipState[slipKey] !== undefined && lastSlipState[slipKey] !== -1 &&
        lastSlipState[slipKey] !== currentSlip &&
        Math.abs(lastSlipState[slipKey] - currentSlip) <= 5) {
        point.marker = {
            symbol: "url(http://trimbletools.com/Sign-Alert-icon.png)"
        };
    }
    seriesBySystem[index].data.push(point);
    lastSlipState[slipKey] = currentSlip;
}
