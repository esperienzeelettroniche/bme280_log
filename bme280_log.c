/**\
 * Copyright (c) 2020 Bosch Sensortec GmbH. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 **/

/*!
 * @brief bme280 data display and log
 * compile like this: gcc bme280_log.c BME280_driver/bme280.c -I BME280_driver/ -lm -lwiringPi -o bme280_log
 * tested: Raspberry Pi.
 * Use like: ./bme280_log
 */

/* Default polling interval */
#define INTERVAL 5

/******************************************************************************/
/*!                         System header files                               */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <time.h>
#include <locale.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <math.h>
#include <wiringPi.h>
#include <wiringPiI2C.h>

/******************************************************************************/
/*!                         bme280 API header files                           */
#include "bme280.h"

/******************************************************************************/
/*!                               Structures                                  */

/* Structure that contains identifier details used in example */
struct identifier
{
    /* Variable to hold device address */
    uint8_t dev_addr;

    /* Variable that contains file descriptor */
    int8_t fd;
};

/* Structure containing computed sensor values
 * (including relative sea level pressure) */
struct sensor_data
{
	float temp;
	float press;
	float press_sl;
	float hum;
};

/****************************************************************************/
/*!                         Functions                                       */

/*!
 *  @brief Function that creates a mandatory delay required in some of the APIs.
 *
 * @param[in] period              : Delay in microseconds.
 * @param[in, out] intf_ptr       : Void pointer that can enable the linking of descriptors
 *                                  for interface related call backs
 *  @return void.
 *
 */
void user_delay_us(uint32_t period, void *intf_ptr);

/*!
 * @brief Function for calculate the temperature, humidity and pressure data.
 *
 * @param[in] comp_data		:   Structure instance of bme280_data
 * @param[out] sensdata_ptr	:   Pointer toi structure instance of sensor_data\
 *
 * @note Sensor data whose can be read
 *
 * sens_list
 * --------------
 * Temperature
 * Pressure
 * Relative sea level pressure
 * Humidity
 *
 */
void calc_sensor_data(struct bme280_data comp_data, struct sensor_data *result);

/*!
 *  @brief Function for reading the sensor's registers through I2C bus.
 *
 *  @param[in] reg_addr       : Register address.
 *  @param[out] data          : Pointer to the data buffer to store the read data.
 *  @param[in] len            : No of bytes to read.
 *  @param[in, out] intf_ptr  : Void pointer that can enable the linking of descriptors
 *                                  for interface related call backs.
 *  @return Status of execution
 *
 *  @retval 0 -> Success
 *  @retval > 0 -> Failure Info
 *
 */
int8_t user_i2c_read(uint8_t reg_addr, uint8_t *data, uint32_t len, void *intf_ptr);

/*!
 *  @brief Function for writing the sensor's registers through I2C bus.
 *
 *  @param[in] reg_addr       : Register address.
 *  @param[in] data           : Pointer to the data buffer whose value is to be written.
 *  @param[in] len            : No of bytes to write.
 *  @param[in, out] intf_ptr  : Void pointer that can enable the linking of descriptors
 *                                  for interface related call backs
 *
 *  @return Status of execution
 *
 *  @retval BME280_OK -> Success
 *  @retval BME280_E_COMM_FAIL -> Communication failure.
 *
 */
int8_t user_i2c_write(uint8_t reg_addr, const uint8_t *data, uint32_t len, void *intf_ptr);

/* Display usage information */
void print_help(char *progname);

/* Print the date in tm structure pointed by date in readeable form */
void print_date(struct tm *date);

/* Calculate relative pressure at sea level */
float sl_press_calc(float press, float temp, float alt);

/*!
 * @brief This function starts execution of the program.
 */
int main(int argc, char* argv[])
{
    time_t now;

    struct tm *date;

    float a = 0;

    int interval = 1;

    struct sensor_data result;

    struct bme280_dev dev;

    struct identifier id;

    /* Structure to get the pressure, temperature and humidity values */
    struct bme280_data comp_data;

    /* Variable to define the result */
    int8_t rslt = BME280_OK;

    /* Variable to define the selecting sensors */
    uint8_t settings_sel;

    /* Variable to store minimum wait time between consecutive measurement in force mode */
    uint32_t req_delay;

    int8_t logfile;

    enum{
	    YES,
	    NO
    }print_headers=YES;

    dev.settings.osr_t = BME280_OVERSAMPLING_1X;

    /* Make sure to select BME280_I2C_ADDR_PRIM or BME280_I2C_ADDR_SEC as needed */
    id.dev_addr = BME280_I2C_ADDR_PRIM;

    dev.settings.filter = BME280_FILTER_COEFF_OFF;

    int opt;

    pid_t pid = getpid();

    while((opt = getopt(argc, argv, ":a:f:l:i:o:sh")) != -1)
    {
	    switch(opt)
	    {
		    case 'a':
			    a = strtof(optarg, NULL);
			    break;
		    case 'h':
			    print_help(argv[0]);
			    return 0;
		    case 'f':
			    switch(atoi(optarg))
			    {
				    case 2:
					    dev.settings.filter = BME280_FILTER_COEFF_2;
					    break;
				    case 4:
					    dev.settings.filter = BME280_FILTER_COEFF_4;
					    break;
				    case 8:
					    dev.settings.filter = BME280_FILTER_COEFF_8;
					    break;
				    case 16:
					    dev.settings.filter = BME280_FILTER_COEFF_16;
					    break;
				    case 0:
				    default:
					    dev.settings.filter = BME280_FILTER_COEFF_OFF;
					    break;
			    }
			    break;
		    case 'l':
			    if((logfile = open(optarg, O_RDONLY)) > 0)
			    {
				    print_headers = NO;
				    close(logfile);
			    }
			    if((logfile = open(optarg, O_WRONLY | O_APPEND | O_CREAT, 0644)) < 0)
			    {
			    	    fprintf(stderr, "Failed to open %s\n", optarg);
			    	    exit(1);
			    }
			    pid = fork();
			    if(pid > 0)
				    exit(0);
			    break;
		    case 'i':
			    interval = atoi(optarg);
			    break;
		    case 'o':
			    switch(atoi(optarg))
			    {
				    case 1:
					    dev.settings.osr_t = BME280_OVERSAMPLING_1X;
					    break;
				    case 2:
					    dev.settings.osr_t = BME280_OVERSAMPLING_2X;
					    break;
				    case 4:
					    dev.settings.osr_t = BME280_OVERSAMPLING_4X;
					    break;
				    case 8:
					    dev.settings.osr_t = BME280_OVERSAMPLING_8X;
					    break;
				    case 16:
					    dev.settings.osr_t = BME280_OVERSAMPLING_16X;
					    break;
				    case 0:
				    default:
					    dev.settings.osr_t = BME280_NO_OVERSAMPLING;
					    break;
			    }
			    break;
		    case 's':
			    id.dev_addr = BME280_I2C_ADDR_SEC;

	    }
    }

    if ((id.fd = wiringPiI2CSetup(id.dev_addr)) < 0)
    {
        fprintf(stderr, "Failed to open the i2c bus %s\n", argv[1]);
        exit(1);
    }

    dev.intf = BME280_I2C_INTF;
    dev.read = user_i2c_read;
    dev.write = user_i2c_write;
    dev.delay_us = user_delay_us;
    dev.intf_ptr = &id;

    /* Recommended mode of operation: Weather monitoring */
    dev.settings.osr_h = dev.settings.osr_t;
    dev.settings.osr_p = dev.settings.osr_t;

    /* Initialize the bme280 */
    rslt = bme280_init(&dev);
    if (rslt != BME280_OK)
    {
        fprintf(stderr, "Failed to initialize the device (code %+d).\n", rslt);
        exit(1);
    }

    /* Set the sensor settings */
    settings_sel = BME280_OSR_PRESS_SEL | BME280_OSR_TEMP_SEL |	BME280_OSR_HUM_SEL | BME280_FILTER_SEL;
    rslt = bme280_set_sensor_settings(settings_sel, &dev);
    if (rslt != BME280_OK)
    {
        fprintf(stderr, "Failed to set sensor settings (code %+d).", rslt);

        return rslt;
    }

    /*Calculate the minimum delay required between consecutive measurement
     * based upon the sensor enabled and the oversampling configuration. */
    req_delay = bme280_cal_meas_delay(&dev.settings);
    
    /* Set the sensor to forced mode */
    rslt = bme280_set_sensor_mode(BME280_FORCED_MODE, &dev);
    if (rslt != BME280_OK)
    {
	    fprintf(stderr, "Failed to set sensor mode (code %+d).", rslt);
    }
    dev.delay_us(10000, dev.intf_ptr);
    
    if(pid != 0)
	    printf("Data\t\t\tTemperatura\tUmidita\t\tPressione\tPressione slm\n");
    else
    {
	    if(print_headers == YES)
	    dprintf(logfile, "Secondi Temperatura Umidita Pressione Pressione-SLM Data\n");
    }

    /* Continuously stream sensor data */
    while (1)
    {
        /* Set the sensor to forced mode */
        rslt = bme280_set_sensor_mode(BME280_FORCED_MODE, &dev);
        if (rslt != BME280_OK)
        {
            fprintf(stderr, "Failed to set sensor mode (code %+d).", rslt);
            break;
        }

        /* Wait for the measurement to complete and print data */
        dev.delay_us(req_delay, dev.intf_ptr);

        rslt = bme280_get_sensor_data(BME280_ALL, &comp_data, &dev);
        if (rslt != BME280_OK)
        {
            fprintf(stderr, "Failed to get sensor data (code %+d).", rslt);
            break;
        }

	time(&now);
	date = localtime(&now);
	now = now;
        calc_sensor_data(comp_data, &result);
    
	if(a != 0)
		result.press_sl = sl_press_calc(result.press, result.temp, a);
	else
		result.press_sl = result.press;	

	if(pid == 0)
	{
		dprintf(logfile, "%d %0.2f %0.2f %0.2f %0.2f ", now, result.temp, result.hum, result.press, result.press_sl);
		dprintf(logfile, "%02d/%02d/%d-%02d:%02d:%02d\n", date->tm_mday, date->tm_mon, date->tm_year+1900, date->tm_hour, date->tm_min, date->tm_sec);
	}
	else
	{
		print_date(date);
		printf("\t%0.2f° C\t%0.2f%%\t\t%0.2f hPa\t%0.2f hPa\n", result.temp, result.hum, result.press, result.press_sl);
		fflush(stdout);
	}

	sleep(interval);
    }

    return 0;
}

/*!
 * @brief This function reading the sensor's registers through I2C bus.
 */
int8_t user_i2c_read(uint8_t reg_addr, uint8_t *data, uint32_t len, void *intf_ptr)
{
    struct identifier id;

    id = *((struct identifier *)intf_ptr);

    write(id.fd, &reg_addr, 1);
    read(id.fd, data, len);

    return 0;
}

/*!
 * @brief This function provides the delay for required time (Microseconds) as per the input provided in some of the
 * APIs
 */
void user_delay_us(uint32_t period, void *intf_ptr)
{
    usleep(period);
}

/*!
 * @brief This function for writing the sensor's registers through I2C bus.
 */
int8_t user_i2c_write(uint8_t reg_addr, const uint8_t *data, uint32_t len, void *intf_ptr)
{
    uint8_t *buf;
    struct identifier id;

    id = *((struct identifier *)intf_ptr);

    buf = malloc(len + 1);
    buf[0] = reg_addr;
    memcpy(buf + 1, data, len);
    if (write(id.fd, buf, len + 1) < (uint16_t)len)
    {
        return BME280_E_COMM_FAIL;
    }

    free(buf);

    return BME280_OK;
}

/*!
 * @brief This API used to print the sensor temperature, pressure and humidity data.
 */
void calc_sensor_data(struct bme280_data comp_data, struct sensor_data *result)
{
#ifdef BME280_FLOAT_ENABLE
    result->temp = comp_data.temperature;
    result->press = 0.01 * comp_data.pressure;
    result->hum = comp_data.humidity;
#else
#ifdef BME280_64BIT_ENABLE
    result->temp = 0.01f * comp_data.temperature;
    result->press = 0.0001f * comp_data.pressure;
    result->hum = 1.0f / 1024.0f * comp_data.humidity;
#else
    result->temp = 0.01f * comp_data.temperature;
    result->press = 0.01f * comp_data.pressure;
    result->hum = 1.0f / 1024.0f * comp_data.humidity;
#endif
#endif
}

void print_help(char *progname)
{
	printf("Usage: %s [OPTIONS]\n", progname);
	printf("-h Show usage\n");
	printf("-a <meters> Set local altitude\n");
	printf("-f <coeff> Set IIR filter coefficent\n");
	printf("-i <seconds> Set read interval\n");
	printf("-l <filename> Write to <filename> instead of STDOUT\n");
	printf("-o <oversample> Set ADC oversampling\n");
	printf("-s Use bme280 secondary address (0x77)\n");
}

void print_date(struct tm *date)
{
	printf("%02d/%02d/%d-%02d:%02d:%02d", date->tm_mday, date->tm_mon, date->tm_year+1900, date->tm_hour, date->tm_min, date->tm_sec);
}

float sl_press_calc(float press, float temp, float alt)
{
	/* Use the expression from
	 * https://keisan.casio.com/exec/system/1224575267 */
	return (press * pow(( 1.0 - ( 0.0065 * alt ) / ( temp + 273.15 + 0.0065 + 0.0065 * alt )), (-5.257)));
}
