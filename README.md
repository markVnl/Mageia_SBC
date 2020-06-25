# Mageia SBC

**NOTE** : This is merely a prove of concept a generic mageia Mageia run's on aarch64 SBC's

However a development image can be downloaded from the Assets at the [release tab](https://github.com/markVnl/Mageia_SBC/releases)

The image can be flashed with [ecther](https://etcher.io/) - or - on linux:  

```
xzcat <image name>.raw.xz | sudo dd of=/dev/sdX bs=4M status=progress && sudo sync
````
As always: **Be sure you got the right device (/dev/sdX) pointing to your sd-card**

>See [UBOOT.md](https://github.com/markVnl/Mageia_SBC/blob/master/UBOOT.md) for flashing Uboot to the SD-Card (this step is not  necessary for Raspberry PI's)

<br>
<br>

After the image booted up you should be able to make a ssh connection:

>Login: root   
>Password: mageia


<br>
<br>
