# Mageia SBC

**NOTE** : This is merely a prove of concept mageia run's on aarch64 a Raspberry PI 3(+)/4

However a development image can be downloaded from the Assets at the [release tab](https://github.com/markVnl/Mageia_SBC/releases)

The image can be flashed with [ecther](https://etcher.io/) - or - on linux:  

```
xzcat <image name>.raw.xz | sudo dd of=/dev/sdX bs=4M status=progress && sudo sync
````

After the image booted up you should be able to make a ssh connection:

<br>

>Login: root   
>Password: mageia


<br>
<br>

NOTES:

* **WIFI** not there yet..
* It's not a main-line kernel: it is build from Raspberry PI Foundation sources build on Copr  
https://copr.fedorainfracloud.org/coprs/markvnl/Raspberry_PI4/build/1415836/    <br>
https://copr-be.cloud.fedoraproject.org/results/markvnl/Raspberry_PI4/mageia-cauldron-aarch64/01415836-raspberrypi/
* It's a bit hacky: the binary blobs for the early boot-stages are included in the source package :o  
* I'm not familiar with the Mageia packaging guidelines (yet)  
