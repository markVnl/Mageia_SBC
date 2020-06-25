# HowTo create an image

The images are created with `appliance-tools`.  
To create your own image based on this repository you need to install this package.

> At the time of writing there is a little [bug/quirk](https://bugs.mageia.org/show_bug.cgi?id=26693) related to the python selinux module.  
> If you encounter this you may (as a workaround) create a simlink :  
> `/usr/lib64/python3.8/site-packages/selinux/_selinux.so -> ../_selinux.so*`  
> (armv7hl)  
> `/usr/lib/python3.8/site-packages/selinux/_selinux.so -> ../_selinux.so*`   

<br>

Creation of the image is defined in kickstart-file found in the `ks` directory.  
The procedure is strait-forward (as an example):

`./sudo build-img.sh ks/Mageia-Uboot-Devel-aarch64-mga.ks`

**NOTE**  
Appliance-tools is not a cross-platform tool: if you want to build an aarch64 image you need to run it on (emulated) aarch64.

<br>
<br>

Have fun;  
Don't be shy to ask questions and raise issues :)

