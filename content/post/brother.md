+++
date = "2014-11-02T19:09:43+01:00"
tags = ["brother", "scanner", "printer"]
title = "Brother DCP-7060D scanner/printer with linux, scan with USB 3.0 solved"
+++

### What's the matter, Brother ?

Well Brother is a brand that is very proud of its Linux support and publish updated drivers each six months. With this thought in my mind I took the chance to buy one. My choice was a laser printer / scanner : *DCP-7060D*, because it's cheaper than ink based printer  and I need like everyone else a scanner too. And it's where it don't works. I can't scan images since months !

#### Installing the drivers

Not really hard, Brother distributes .deb files for each part of your hardware. One for scanning, one for printing, one for magickey. It's installing, it's installed and when you want to detect your printer, well :

```bash
 $ lsusb | grep Brother
Bus 002 Device 005: ID 04f9:0249 Brother Industries, Ltd 
$ 
```

It works. It prints as well, you have many tutorials and people that are saying that it is now working very well with the last drivers.

But on a recent computer, there IS **NO WAY to scan** properly. During months I tried different technics that should have work.

* I tried to purge and reinstall drivers so many times that I lost count
* I put the right rules for *udev*
* I tried scanimage, xsane, saned, got lost in so many forum threads and every time it finished the same way

**The scan crashed during the execution.**

### And I found the solution, that was not where I expected.

I managed before to scan with this hardware and it was with my previous computer but I never thought that it could be a hardware problem. **But it was.**
My new computer is more more advanced than the old one and the motherboard has **usb 3.0** ports.

To fix this you have to go into your *BIOS* Settings and put these values :

* Legacy support : change it from **auto** to **enable**
* XHCI pre-boot support to **disabled** instead on **enabled**

It seems that new motherboards are not dealing very well with Brother hardware, at least my old **DCP-7060D** so every « auto » mode for usb must be forgotten. And finally.

**It works. It's scanning.**