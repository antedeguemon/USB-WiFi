# Benchmarking an adapter's RX range

## Bash prototype

Attention: make sure `wpa_supplicant` and any network managers are disabled.
You will also need [tcpdump](https://www.tcpdump.org/) and 
[timeout](https://manpages.debian.org/stretch/coreutils/timeout.1.en.html)
packages installed.

```zsh
INTERFACE="wlan1"

# Interval between each channel switch
INTERVAL_SECONDS="30"

sudo ifconfig $INTERFACE down
sudo iw dev $INTERFACE set power_save off
sudo iw dev $INTERFACE set monitor control otherbss
sudo ifconfig $INTERFACE up

function switch_channel {
	sudo ifconfig 
	sudo iw dev $INTERFACE set channel $1
}


```


## Draft with C code from hcxdumptool

```c
struct iw_param
{
 int value;
 unsigned char fixed;
 unsigned char disabled;
 unsigned short flags;
};

struct iw_point
 {
 void *pointer;
 unsigned short length;
 unsigned short flags;
};

struct iw_freq
{
 int m;
 short e;
 unsigned char i;
 unsigned char flags;
};

union iwreq_data
{
 char name[IFNAMSIZ];
 struct iw_point	essid;
 struct iw_param	nwid;
 struct iw_freq		freq;
 struct iw_param	sens;
 struct iw_param	bitrate;
 struct iw_param	txpower;
 struct iw_param	rts;
 struct iw_param	frag;
 unsigned		mode;
 struct iw_param	retry;
 struct iw_point	encoding;
 struct iw_param	power;
 struct iw_quality	qual;
 struct sockaddr	ap_addr;
 struct sockaddr	addr;
 struct iw_param	param;
 struct iw_point	data;
};

struct iwreq
{
 union
 {
  char ifrn_name[IFNAMSIZ];
 } ifr_ifrn;
 union iwreq_data u;
};

```

https://github.com/ZerBea/hcxdumptool/blob/d7b974f8701b06142ceb3686b584963fbc4c5f00/include/wireless-lite.h#L62


```c

#define SIOCSIWFREQ     0x8b04
#define IW_FREQ_FIXED	  0x01



static inline bool set_channel_test(int freq)
{
static int freqreported;
static struct iwreq pwrq;

ifr_name: 

memset(&pwrq, 0, sizeof(pwrq));
memcpy(&pwrq.ifr_name, interfacename, IFNAMSIZ);
pwrq.u.freq.flags = IW_FREQ_FIXED;
pwrq.u.freq.m = freq *100000;
pwrq.u.freq.e = 1;
if(ioctl(fd_socket, SIOCSIWFREQ, &pwrq) < 0)
	{
	fprintf(stderr, "driver doesn't support ioctl() SIOCSIWFREQ\n");
	return false;
	}
memset(&pwrq, 0, sizeof(pwrq));
memcpy(&pwrq.ifr_name, interfacename, IFNAMSIZ);
if(ioctl(fd_socket, SIOCGIWFREQ, &pwrq) < 0)
	{
	fprintf(stderr, "driver doesn't support ioctl() SIOCGIWFREQ\n");
	return false;
	}
if(pwrq.u.freq.m > 1000)
	{
	if(pwrq.u.freq.e == 6) freqreported = pwrq.u.freq.m;
	else if(pwrq.u.freq.e == 5) freqreported = pwrq.u.freq.m /10;
	else if(pwrq.u.freq.e == 4) freqreported = pwrq.u.freq.m /100;
	else if(pwrq.u.freq.e == 3) freqreported = pwrq.u.freq.m /1000;
	else if(pwrq.u.freq.e == 2) freqreported = pwrq.u.freq.m /10000;
	else if(pwrq.u.freq.e == 1) freqreported = pwrq.u.freq.m /100000;
	else if(pwrq.u.freq.e == 0) freqreported = pwrq.u.freq.m /1000000;
	else
		{
		fprintf(stderr, "unhandled expontent %d reported by driver\n", pwrq.u.freq.e);
		return false;
		}
	if(freqreported == freq) return true;
	}
fprintf(stderr, "driver doesn't report frequency\n");
return false;
}
```