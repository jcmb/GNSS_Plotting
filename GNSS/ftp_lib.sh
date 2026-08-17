#!/bin/bash

ftp_load_config() {
   local dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
   if [ ! -f "$dir/ftp_servers.cfg" ]
   then
      echo "ftp_servers.cfg not found in $dir"
      return 1
   fi
   . "$dir/ftp_servers.cfg"
}

ftp_resolve_server() {
   local name="$1"
   local entry sname user host

   if [ -z "$name" ]
   then
      echo "FTP server name is required"
      return 1
   fi

   for entry in "${FTP_SERVERS[@]}"
   do
      IFS='|' read -r sname user host <<< "$entry"
      if [ "$sname" = "$name" ]
      then
         FTP_USER="$user"
         FTP_SERVER="$host"
         return 0
      fi
   done

   echo "Unknown FTP server: $name"
   return 1
}

ftp_mirror_download() {
   local local_dir="$1"
   local server="$2"
   local remote_path="$3"
   local older_than="$4"
   local log_file="$5"

   ftp_resolve_server "$server" || return 1

   if [ ! -d "$local_dir" ]
   then
      echo "Local directory not found: $local_dir"
      return 1
   fi

   cd "$local_dir" || return 1

   echo "FTP download: $server:$remote_path -> $local_dir (older than $older_than)"
   logger "ftp_mirror_download: $server:$remote_path -> $local_dir"

   if [ -n "$log_file" ]
   then
      lftp <<EOF
set xfer:clobber on
set xfer:log true
set xfer:log-file "$log_file"
open -u $FTP_USER $FTP_SERVER
cd $remote_path
mirror --older-than=$older_than --Remove-source-files --continue .
EOF
   else
      lftp <<EOF
set xfer:clobber on
set xfer:log true
open -u $FTP_USER $FTP_SERVER
cd $remote_path
mirror --older-than=$older_than --Remove-source-files --continue .
EOF
   fi
}

ftp_mirror_upload() {
   local local_dir="$1"
   local server="$2"
   local remote_path="$3"
   local log_file="$4"

   ftp_resolve_server "$server" || return 1

   if [ ! -d "$local_dir" ]
   then
      echo "Local directory not found: $local_dir"
      return 1
   fi

   cd "$local_dir" || return 1

   echo "FTP upload: $local_dir -> $server:$remote_path"
   logger "ftp_mirror_upload: $local_dir -> $server:$remote_path"

   if [ -n "$log_file" ]
   then
      lftp <<EOF
set xfer:clobber on
set xfer:log
open -u $FTP_USER $FTP_SERVER
cd $remote_path
mirror --reverse --ignore-time --parallel --log=$log_file
EOF
   else
      lftp <<EOF
set xfer:clobber on
set xfer:log
open -u $FTP_USER $FTP_SERVER
cd $remote_path
mirror --reverse --ignore-time --parallel
EOF
   fi
}
