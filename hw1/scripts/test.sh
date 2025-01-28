correct_cnt=0
timeout 60s bash compile.sh

for i in {1..8}
do
	printf "\nworking on case ${i}:\n"
	test_data=samples/sample${i}.in
	correct_file=samples/sample${i}.out
	time timeout 600s taskset -c 0-23 bash run.sh ${test_data} outputs/output_file
	diff -qEwB outputs/output_file ${correct_file} > /dev/null
	res=$?
	if [ "${res}" -eq "0" ]; then
		correct_cnt=$((correct_cnt+1))
	else
		echo "incorrect on case ${i}"
	fi
done
printf "correct: ${correct_cnt}\n"
