#!/bin/bash
# Build constellation_sv.csv.gz from tracking viewdat in the background.
# Args: RESULT_DIR UPLOAD_COPY FILE NORMAL_DIR EXT SAVE_FILE KEEP_X29

RESULT_DIR="$1"
UPLOAD_COPY="$2"
FILE="$3"
NORMAL_DIR="$4"
EXT="$5"
SAVE_FILE="$6"
KEEP_X29="$7"

CONSTELLATION_CANDIDATES_DIR="/run/shm/constellation_${FILE}_$$"
PROCESSING_MARKER="constellation_processing.txt"

update_status() {
   printf '%s\n' "$1" > "$RESULT_DIR/$PROCESSING_MARKER" 2>/dev/null || true
}

cleanup() {
   rm -rf "$CONSTELLATION_CANDIDATES_DIR"
   rm -f "$UPLOAD_COPY"
   rm -f "$RESULT_DIR/$PROCESSING_MARKER"
}

trap cleanup EXIT

cd "$RESULT_DIR" || exit 1
mkdir -p "$CONSTELLATION_CANDIDATES_DIR"

if [ ! -f "$UPLOAD_COPY" ] || [ ! -f "$FILE.sol" ]
then
   exit 0
fi

update_status "Reading GPS week from upload"
WEEK="-1"
WEEK_SCRIPT="$NORMAL_DIR/../TrackingPlot/Week_From_T19.pl"
if [ -x "$WEEK_SCRIPT" ]
then
   WEEK="$(viewdat -d19 "$UPLOAD_COPY" 2>/dev/null | "$WEEK_SCRIPT" 2>/dev/null || echo "-1")"
fi

_ext_lower="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"
if [ "$_ext_lower" = "t02" ]
then
   update_status "Trying native rec29 export (T02 only)"
   if viewdat -d29 -x -o"${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" "$UPLOAD_COPY" 2>/dev/null
   then
      if tail -n +5 "${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" \
         > "${CONSTELLATION_CANDIDATES_DIR}/native.x29" 2>/dev/null \
         && "$NORMAL_DIR/export_constellation_sv_csv.py" "${CONSTELLATION_CANDIDATES_DIR}/native.x29" \
            > "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv" 2>/dev/null
      then
         :
      else
         rm -f "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv"
      fi
      if [ "$KEEP_X29" = "1" ] || [ "$SAVE_FILE" = "1" ]
      then
         cp "${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" "${FILE}.x29_native" 2>/dev/null || true
      fi
      rm -f "${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" \
         "${CONSTELLATION_CANDIDATES_DIR}/native.x29"
   fi
fi

if [ "$WEEK" != "-1" ]
then
   update_status "Exporting tracking records (rec27) — large files can take several minutes"
   if viewdat -d27 --translate_rec35_sub19_to_rec27 -x "$UPLOAD_COPY" 2>/dev/null \
      | "$NORMAL_DIR/export_constellation_sv_from_x27.py" "$WEEK" \
         > "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv" 2>/dev/null
   then
      :
   else
      rm -f "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv"
   fi
   if [ "$KEEP_X29" = "1" ]
   then
      viewdat -d27 --translate_rec35_sub19_to_rec27 -x -o"${FILE}.x27" "$UPLOAD_COPY" 2>/dev/null || true
   fi
fi

update_status "Writing per-constellation SV CSV"
FROM_SOL="${CONSTELLATION_CANDIDATES_DIR}/from_sol.csv"
if "$NORMAL_DIR/export_constellation_sv_csv.py" "$FILE.sol" > "$FROM_SOL" 2>/dev/null
then
   :
else
   rm -f "$FROM_SOL"
fi

if "$NORMAL_DIR/export_constellation_sv_best.py" --sol "$FILE.sol" \
   "$FROM_SOL" \
   "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv" \
   "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv" \
   > constellation_sv.csv 2>/dev/null
then
   gzip -9 -f constellation_sv.csv
else
   rm -f constellation_sv.csv constellation_sv.csv.gz
fi

if [ "$KEEP_X29" = "1" ] || [ "$SAVE_FILE" = "1" ]
then
   {
      echo "<a href=\"${FILE}.x29\">${FILE}.x29</a> (rec29 via rec35 sub2 translate)"
      if [ -f "${FILE}.x29_native" ]
      then
         echo " <a href=\"${FILE}.x29_native\">${FILE}.x29_native</a> (native rec29, T02 only)"
      fi
      if [ -f "${FILE}.x27" ]
      then
         echo " <a href=\"${FILE}.x27\">${FILE}.x27</a> (tracking rec27)"
      fi
      if [ -f x29_header.txt ]
      then
         echo " <a href=\"x29_header.txt\">x29_header.txt</a>"
      fi
   } > SaveFile.html
fi

logger "Constellation SV background processing finished for $FILE"
exit 0
