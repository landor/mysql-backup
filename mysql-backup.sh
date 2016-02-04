#!/bin/bash
# MYSQL Backup Script

savepath=`readlink -f "$0"`
savepath=`dirname $savepath`/mysql-backups
date=`date "+%y%m%d"`

function rotate {
  tag=$1
  keep=$2
  for i in $(seq $keep -1 1); do
    dir="$savepath/$tag.$i"
    prev_dir=$savepath/$tag.$(($i-1))
    if [ -d "$dir" ]; then
      rm -rf $dir
    fi
    if [ -d "$prev_dir" ]; then
      mv "$prev_dir" "$dir"
    fi
  done
}
function listcontains {
  for word in $1; do
    [[ $word = $2 ]] && return 0
  done
  return 1
}

# create storage directory
if [ ! -d "$savepath" ]; then
  mkdir $savepath
  chmod go-rwX $savepath
fi

# create today
dir_today="$savepath/daily.0"
if [ ! -d "$dir_today" ]; then
  mkdir "$dir_today"
fi

# do backup
skip_dbs="information_schema"
for a in `echo "show databases" | mysql -s`; do
  if listcontains "$skip_dbs" "$a"; then continue; fi
  # echo "db: $a"
  sql_file="$dir_today/$date-$a.sql"
  mysqldump --skip-lock-tables --add-drop-table --allow-keywords -q -a -c $a > "$sql_file"
  bzip2 "$sql_file"
done

# weekly rotation
# if [ `date +%u` == "7" ]; then
if [ `date +%u` == "4" ]; then
  cp -r "$dir_today" "$savepath/weekly.0"
  rotate weekly 4
fi

# monthly rotation
# if [ `date +%d` == "01" ]; then
if [ `date +%d` == "04" ]; then
  cp -r "$dir_today" "$savepath/monthly.0"
  rotate monthly 4
fi

# daily rotation
rotate daily 7
