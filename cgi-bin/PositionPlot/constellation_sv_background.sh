#!/bin/bash
# Build constellation_sv.csv.gz from tracking viewdat in the background.
# Args: RESULT_DIR UPLOAD_COPY SOL_COPY FILE NORMAL_DIR EXT SAVE_FILE KEEP_X29

RESULT_DIR="$1"
UPLOAD_COPY="$2"
SOL_COPY="$3"
FILE="$4"
NORMAL_DIR="$5"
EXT="$6"
SAVE_FILE="$7"
KEEP_X29="$8"

CONSTELLATION_CANDIDATES_DIR="/run/shm/constellation_${FILE}_$$"
PROCESSING_MARKER="constellation_processing.txt"
LOG_FILE="constellation_background.log"

log_msg() {
   {
      echo "$(date -Is 2>/dev/null || date) $*"
   } >> "$RESULT_DIR/$LOG_FILE" 2>/dev/null || true
}

update_status() {
   printf '%s\n' "$1" > "$RESULT_DIR/$PROCESSING_MARKER" 2>/dev/null || true
}

cleanup() {
   rm -rf "$CONSTELLATION_CANDIDATES_DIR"
   rm -f "$UPLOAD_COPY" "$SOL_COPY"
   rm -f "$RESULT_DIR/$PROCESSING_MARKER"
}

trap cleanup EXIT

cd "$RESULT_DIR" || exit 1
mkdir -p "$CONSTELLATION_CANDIDATES_DIR"

log_msg "start file=$FILE ext=$EXT upload=$UPLOAD_COPY sol=$SOL_COPY"

if [ ! -f "$UPLOAD_COPY" ]
then
   log_msg "error missing upload copy"
   exit 1
fi

if [ ! -f "$SOL_COPY" ]
then
   log_msg "error missing sol copy"
   exit 1
fi

update_status "Reading GPS week from upload"
WEEK="-1"
WEEK_SCRIPT="$NORMAL_DIR/../TrackingPlot/Week_From_T19.pl"
if [ -x "$WEEK_SCRIPT" ]
then
   WEEK="$(viewdat -d19 "$UPLOAD_COPY" 2>>"$RESULT_DIR/$LOG_FILE" | "$WEEK_SCRIPT" 2>>"$RESULT_DIR/$LOG_FILE" || echo "-1")"
fi
log_msg "gps_week=$WEEK"

_ext_lower="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"
if [ "$_ext_lower" = "t02" ]
then
   update_status "Trying native rec29 export (T02 only)"
   if viewdat -d29 -x -o"${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" "$UPLOAD_COPY" 2>>"$RESULT_DIR/$LOG_FILE"
   then
      if tail -n +5 "${CONSTELLATION_CANDIDATES_DIR}/native_full.x29" \
         > "${CONSTELLATION_CANDIDATES_DIR}/native.x29" 2>/dev/null \
         && "$NORMAL_DIR/export_constellation_sv_csv.py" "${CONSTELLATION_CANDIDATES_DIR}/native.x29" \
            > "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv" 2>>"$RESULT_DIR/$LOG_FILE"
      then
         log_msg "native rec29 export produced constellation rows"
      else
         rm -f "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv"
         log_msg "native rec29 export had no usable constellation rows"
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
   if viewdat -d27 --translate_rec35_sub19_to_rec27 -x "$UPLOAD_COPY" 2>>"$RESULT_DIR/$LOG_FILE" \
      | "$NORMAL_DIR/export_constellation_sv_from_x27.py" "$WEEK" \
         > "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv" 2>>"$RESULT_DIR/$LOG_FILE"
   then
      log_msg "rec27 export complete"
   else
      rm -f "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv"
      log_msg "rec27 export failed"
   fi
   if [ "$KEEP_X29" = "1" ]
   then
      viewdat -d27 --translate_rec35_sub19_to_rec27 -x -o"${FILE}.x27" "$UPLOAD_COPY" 2>>"$RESULT_DIR/$LOG_FILE" || true
   fi
else
   log_msg "warning skipping rec27 export (GPS week unavailable)"
fi

update_status "Writing per-constellation SV CSV"
FROM_SOL="${CONSTELLATION_CANDIDATES_DIR}/from_sol.csv"
if "$NORMAL_DIR/export_constellation_sv_csv.py" "$SOL_COPY" > "$FROM_SOL" 2>>"$RESULT_DIR/$LOG_FILE"
then
   log_msg "sol export produced constellation rows"
else
   rm -f "$FROM_SOL"
fi

if "$NORMAL_DIR/export_constellation_sv_best.py" --sol "$SOL_COPY" \
   "$FROM_SOL" \
   "${CONSTELLATION_CANDIDATES_DIR}/from_native.csv" \
   "${CONSTELLATION_CANDIDATES_DIR}/from_x27.csv" \
   > constellation_sv.csv 2>>"$RESULT_DIR/$LOG_FILE"
then
   gzip -9 -f constellation_sv.csv
   log_msg "wrote constellation_sv.csv.gz"
else
   rm -f constellation_sv.csv constellation_sv.csv.gz
   log_msg "error no constellation_sv.csv produced"
   exit 1
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

log_msg "finished"
exit 0
