FROM alpine:latest
RUN echo "sam was here" > touched.txt
CMD ["sh", "-c", "[ -f touched.txt ]"]
