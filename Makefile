bme280_log:
	gcc bme280_log.c BME280_driver/bme280.c -I BME280_driver -lm -lwiringPi -O2 -o bme280_log
	chmod 755 plotgraph.sh
clean:
	rm -v bme280_log
