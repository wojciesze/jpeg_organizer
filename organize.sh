#!/bin/bash


dst="/home/marcin/lair/zdjecia/"
[ -d "${dst}" ] || {
	echo "Destination dir: ${dst} NOT FOUND"
	exit 2
}

cnt=1;
total=`ls *.[jJ][pP][gG] 2>/dev/null | wc -l`
[ $total -gt 0 ] || {
	echo "No JPG files found"
	exit 0
}

log_file=`printf "organize_jpg_%s.log" $(date "+%Y%m%d_%H%M%S")`
error_file=/tmp/organize_error_$$

for f in *.[jJ][pP][gG]; do
    exif_output=`exiftool -d "_%Y-%m-%d_%H%M%S" -CreateDate $f`
    da=`echo ${exif_output} | cut -d_ -f2`
    timestamp=`echo ${exif_output} | cut -d_ -f3`
    camera=`exiftool -Model "${f}" | cut -d: -f2 | xargs echo | tr " " "_"`
    
    if [[ "${da}" =~ "Create Date" ]]; then
		echo "${f} - No Create Date in the EXIF" >> $error_file
		cnt=$((cnt+1))
		continue
    fi
    
    y=`echo $da | cut -d- -f1`
    m=`echo $da | cut -d- -f2`
    d=`echo $da | cut -d- -f3` 
    dir=`printf "%s/%s/%s\n" ${dst%%/} $y $da`
    dst_file=`printf "%s_%03d_%s.jpg" "${dir}/${timestamp}" "${cnt}" "${camera}"`
	tput sc
	printf "Processing %d of %d - current date: %s" $cnt $total $da
	tput rc
		
    if [ -f "${dst_file}" ]; then
		echo "File ${dst_file} already exists!" >> $error_file
		cnt=$((cnt+1))
		continue
	fi
	
	printf "%-12s %-30s %s\n" "${da}" "${f}" "${dst_file}" >> $log_file
	mkdir -p $dir
	mv "${f}" "${dst_file}"
	cnt=$((cnt+1))
done

printf "\ndone\n"

[ -f $error_file ] && {
	errors=`cat $error_file | wc -l`
	echo "${errors} ERROR(S) have been found:"
	if [ $errors -lt 40 ]; then
		cat $error_file
		rm $error_file
	else
		echo "Please see: ${error_file}"
	fi
}

if [ -f $log_file ]; then
	files_processed=`cat $log_file | wc -l`
	echo "Files moved: ${files_processed}"
	echo "Below dates were processed:"
	cat $log_file | awk '{print $1}' | sort -u
	echo "Log file: ${log_file}"
else
	echo "0 files processed"
fi
