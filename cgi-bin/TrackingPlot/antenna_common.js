var trackedAntennas = ["0"];
var selectedAntenna = "0";
var RX_PARAM = "RX";

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

function appendAntennaQuery(url, antenna, antennas) {
    if (!antennas || antennas.length <= 1) {
        return url;
    }
    if (url.indexOf("?") >= 0) {
        return url + "&" + RX_PARAM + "=" + encodeURIComponent(antenna);
    }
    return url + "?" + RX_PARAM + "=" + encodeURIComponent(antenna);
}

function navigatePlot(url) {
    location.href = appendAntennaQuery(url, selectedAntenna, trackedAntennas);
}

function renderAntennaSelector(containerId, antennas, antenna, onChange) {
    var container = $("#" + containerId);
    if (!hasMultipleAntennas(antennas)) {
        container.empty().hide();
        return;
    }

    container.show();
    var html = "<p><strong>Antenna:</strong> ";
    for (var i = 0; i < antennas.length; i++) {
        var id = String(antennas[i]);
        var label = "Antenna " + id;
        if (id === String(antenna)) {
            html += "<strong>" + label + "</strong> ";
        } else {
            html += "<a href=\"#\" data-antenna=\"" + id + "\">" + label + "</a> ";
        }
    }
    html += "</p>";
    container.html(html);
    container.find("a[data-antenna]").click(function(event) {
        event.preventDefault();
        onChange($(this).attr("data-antenna"));
    });
}

function initAntennaPage(containerId, onReady) {
    loadTrackedAntennas(function(antennas) {
        antennas = normalizeAntennaList(antennas);
        var antennaParam = getURLParameter(RX_PARAM);
        var antenna = antennas[0];
        if (hasMultipleAntennas(antennas) && urlParameterPresent(antennaParam)) {
            antenna = antennaParam;
        }
        setAntennaContext(antennas, antenna);
        renderAntennaSelector(containerId, antennas, antenna, function(newAntenna) {
            if (!hasMultipleAntennas(antennas)) {
                return;
            }
            var params = location.search.replace(/^\?/, "").split("&").filter(function(part) {
                return part && part.indexOf(RX_PARAM + "=") !== 0;
            });
            params.push(RX_PARAM + "=" + encodeURIComponent(newAntenna));
            location.search = "?" + params.join("&");
        });
        onReady(antennas, antenna);
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
    var rest = bandBaseName(line, prefix);
    return rest;
}
