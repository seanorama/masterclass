for i in $(seq 2 6); do
	echo -e "\n==> Lab${i}\n"
	cd Lab${i}
	./prepare.sh
	cd ..
done