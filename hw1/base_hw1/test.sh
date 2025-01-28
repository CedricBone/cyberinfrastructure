correct_cnt=0
timeout 60s bash compile.sh

for i in {1..2}
do
	printf "\nworking on case ${i}:\n"
	test_data=sample${i}.in
	correct_file=sample${i}.out
	time timeout 600s taskset -c 0-23 bash run.sh ${test_data} output_file
	diff -qEwB output_file ${correct_file} > /dev/null
	res=$?
	if [ "${res}" -eq "0" ]; then
		correct_cnt=$((correct_cnt+1))
	else
		echo "incorrect on case ${i}"
	fi
done
printf "correct: ${correct_cnt}\n"
