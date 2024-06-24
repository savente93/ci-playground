from alpine:latest
run echo "sam was here" > touched.txt
CMD ["sh", "-c", "[ -f touched.txt ]"]
