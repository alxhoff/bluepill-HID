# CMake bluepill HID   

Now the cmake project works in a much smoother fashion, everything is automated and the best part is that there is a variable that can be passed to cmake to allow for you to override the HID config sources.
To make use of your own sources, as is done in the [`HID_config`](HID_config) folder of this repo, invoke cmake and pass in the folder's location as `USBDevice_HID_CONFIG_DIR`.

For example from the root of this cmake example

``` bash
mkdir build
cd build
cmake -DUSBDevice_HID_CONFIG_DIR=HID_config ..
make
```
While you can generate a custom HID device project using STM's cube, I find that modifying the standard HID example (a mouse) to be much less hassle, a little grepping will easily show you everything you need to rename if you do not want your descriptor to be labeled as a mouse descriptor.
Following the same process as the [cube](../cube) example to change the descriptor.
Namely, change the descriptor in `usbd_hid.c` in the array `HID_MOUSE_ReportDesc` and then in `hdbd_hid.h` change the `HID_MOUSE_REPORT_DESC_SIZE` to the appropriate size.

You will also need to change the `nInterfaceProtocol` and `bInterfaceSubClass` in `usbd_hid.c` depending on your descriptor.

# Example

I have written a descriptor (not sure if it works yet) and it looks as follows:

``` c
{
0x05, 0x01,  
0x09, 0x06,
0xA1, 0x01,
0x85, 0x01,
0x05, 0x07, 
0x75, 0x01, 
0x95, 0x08,
0x19, 0xE0,
0x29, 0xE7,
0x15, 0x00,
0x25, 0x01,
0x81, 0x02,
0x75, 0x08,
0x95, 0x01,
0x81, 0x03,
0x95, 0x05,
0x75, 0x01,
0x05, 0x08,
0x85, 0x01,
0x19, 0x01,
0x92, 0x05,
0x01, 0x02,
0x75, 0x03,
0x95, 0x01,
0x91, 0x03,
0x95, 0x06,
0x75, 0x08,
0x09, 0x07,
0x15, 0x00,
0x25, 0x65,
0x81, 0x00,
0xC0,
0x09, 0x02,
0xA1, 0x01,
0x09, 0x01,
0xA1, 0x00,
0x86, 0x02,
0x05, 0x09,
0x19, 0x01,
0x29, 0x03,
0x15, 0x00,
0x25, 0x01,
0x95, 0x03,
0x75, 0x01,
0x81, 0x02,
0x95, 0x01,
0x75, 0x05,
0x81, 0x03,
0x05, 0x01,
0x09, 0x30,
0x09, 0x31,
0x15, 0x81,
0x25, 0x7F,
0x75, 0x08,
0x95, 0x02,
0x81, 0x06,
0xC0,
0xC0,
0x05, 0x0C,
0x09, 0x01,
0xA1, 0x01,
0x85, 0x03,
0x15, 0x00,
0x25, 0x01,
0x75, 0x01,
0x95, 0x08,
0x09, 0xB5,
0x09, 0xB6,
0x09, 0xB7,
0x09, 0xB8,
0x09, 0xCD,
0x09, 0xE2,
0x09, 0xE9,
0x09, 0xEA,
0x81, 0x02,
0xC0};
```
As I cannot be bothered to copy out the complete explination of the descriptor from the descriptor I generated using the windows based HID tool from the USB body.
Please see the [pdf](my_hid.pdf) generated from the let's say....less than enjoyable to use tool. 
Glad I had a windows VM floating around.

The descriptor contains three collections that implement the three functions of a keyboard that also has a mouse and media buttons.

Thus the three functions are:

- Standard keyboard with modifyer buttons and status LEDs
- A mouse that sends 3 button presses and an X and Y axis
- A set of 8 media keys that send
  - Next track
  - Prev track
  - Stop
  - Eject
  - Play/Pause (manually modified from pdf descriptor becuase the tool sucks)
  - Mute
  - Vol up
  - Vol down

  Now as the descriptor has a length of 148 bytes we can place the descriptor into `usbh_hid.c` and replace the appropriate length into `usbd_hid.h`.

  I will commit now and then change the descriptor so that a nice clean patch is generated.