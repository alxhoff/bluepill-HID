# Cube MX HID

The first step to using the bluepill with USB is to enable the appropriate components and set the clock correctly to generate the required 48MHz clock.

The configuration is quite easy, in connectivity enable USB as a full speed device, you shouldn't need to change any configurations of the USB. Then in middleware, after enabling `USB_DEVICE`, select the "Class for FS IP" to be "Human Interface Device Class (HID)". Avoid selecting the custom HID for now as this is more work to set up and for this basic example we will stick with their generated example (mouse) for now.

![cube mx pinout](.img/pinout.png "Cube MX Pinout")

After enabling USB we must configure the board such that we have a correct clock on the USB lines to enable data transfer. The automatic clock resolved from Cube is usually pretty good but in this case it sucked and I had to find a configuration myself. See the below image and configure your clock to be the same.

![cube mx clock](.img/clock.png "Cube MX Clock")

After doing this you can clock generate code, making sure when asked to use "Makefile" toolchain/IDE as we will just build on the command line and use `openocd` to flash the binary.

Now we need to add a few little changes. I will commit the generated files now and then the modifications so we can see the changes.

For this quick and dirty example, after making the binary, I copied it to replace the elf compiled by [bluepill cmake build](https://github.com/alxhoff/bluepill). Meaning I could just run `make flash` from the [bluepill cmake build](https://github.com/alxhoff/bluepill) build directory to flash the new elf.