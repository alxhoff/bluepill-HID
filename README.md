# bluepill HID
Human Interface Device (HID) example for the bluepill (STM32F103C8T6)

Last night as I couldn't sleep I had the idea that I should see if the bluepill, which I made a [build](https://github.com/alxhoff/bluepill) for a couple of days ago, could do USB HID, aka could the bluepill send HID commands to the computer and emulate a mouse or keyboard.

I played around with this a few years ago when I was working on [this](https://github.com/alxhoff/STM32-Mechanical-Keyboard) keyboard project. But the project has been dead for a while and the code itself isn't exactly great. But after how quick and easy it was with a bluepill I might just revive the old project.

This repo contains a few examples, one is a longer, but pure CubeMX generated example. There are then multiple examples to show HIDs for either a mouse, keyboard and a user defined composite device. All examples in the cmake folder are built using the [bluepill cmake build](https://github.com/alxhoff/bluepill). Each can be found in the respective folders in this repo.

# Notes on USB descriptors

I am writing this here as it is not necessarily HID specific but I will no need to reference back to this when I return to doing HID stuff in a years time.
My problem is that the LED reports from host pc -> device are not being handled by the default mouse example provided by cube. 

Looking at the documentation [here](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=76) there is a lot of information on setting up USB descriptors for HID devices.
Even luckier, the example is for a keyboard and mouse device that exposes two interfaces, enabling boot protocol. 
Exactly what I need to know!
[This](https://www.beyondlogic.org/usbnutshell/usb5.shtml) website also provides some good insight into it all as the USB documentation is pretty average.

The STM cube generated USB descriptors are as follows:

## Device Descriptor

The device descriptor describes the device as a whole, it. one per device.

From [`usbd_desc.c`](cmake/Src/usbd_desc.c):

```
__ALIGN_BEGIN uint8_t USBD_FS_DeviceDesc[USB_LEN_DEV_DESC] __ALIGN_END =
{
  0x12,                       /*bLength */
  USB_DESC_TYPE_DEVICE,       /*bDescriptorType*/
  0x00,                       /*bcdUSB */
  0x02,
  0x00,                       /*bDeviceClass*/
  0x00,                       /*bDeviceSubClass*/
  0x00,                       /*bDeviceProtocol*/
  USB_MAX_EP0_SIZE,           /*bMaxPacketSize*/
  LOBYTE(USBD_VID),           /*idVendor*/
  HIBYTE(USBD_VID),           /*idVendor*/
  LOBYTE(USBD_PID_FS),        /*idProduct*/
  HIBYTE(USBD_PID_FS),        /*idProduct*/
  0x00,                       /*bcdDevice rel. 2.00*/
  0x02,
  USBD_IDX_MFC_STR,           /*Index of manufacturer  string*/
  USBD_IDX_PRODUCT_STR,       /*Index of product string*/
  USBD_IDX_SERIAL_STR,        /*Index of serial number string*/
  USBD_MAX_NUM_CONFIGURATION  /*bNumConfigurations*/
};
```
- **nLength** - Size of USB device descriptor, decimal 18
- **bDescriptorType** - looking in `usbd_def.h` we see that this is 1, a constant value to indicate DEVICE descriptors
- **bcdUSB** - USB specification number that device complies to, USB 2.0
- **bDeviceClass** - Specifies class code as assigned by USB Org, zero implies that each interface spcifies it's own class.
- **bDeviceSubClass** - Same deal as above
- **bDeviceProtocol** - Protocol assigned by USB Org, tied to subclass so 0 at the moment
- **bMaxPacketSize** - Maximum packet size, valid is 8, 16, 32 and 64. Default is 64.
- **idVendor** and **idProduct** -  Self explanitory
- **bcdDevice*** - Device release number
- **bNumConfigurations** - Numper of possible configurations, we only want one

## Configuration Descriptor

Each configuration has a configuration descriptor that gives information on the things such as device power and the number of interfaces the device has when in a certain configuration. 
As our device only has one configuration we only need one configuration descriptor.

From [`usbd_hid.c`](cmake/HID_keyboard_config/usbd_hid.c):

*Note*: Looking at the [figure](https://www.beyondlogic.org/usbnutshell/usb5.shtml#anchor) under 'Configuration Descriptors' we see that 

> When the configuration descriptor is read, it returns the entire configuration hierarchy which includes all related interface and endpoint descriptors. The wTotalLength field reflects the number of bytes in the hierarchy.

Therefore the configuration descriptor is inface the concatination of

- Configuration descriptor
- Interface descriptor
- HID descriptor 
- Endpoint descriptor

``` c 
/* USB HID device Configuration Descriptor */
__ALIGN_BEGIN static uint8_t USBD_HID_CfgDesc[USB_HID_CONFIG_DESC_SIZ]  __ALIGN_END =
{
  0x09, /* bLength: Configuration Descriptor size */
  USB_DESC_TYPE_CONFIGURATION, /* bDescriptorType: Configuration */
  USB_HID_CONFIG_DESC_SIZ,
  /* wTotalLength: Bytes returned */
  0x00,
  0x01,         /*bNumInterfaces: 1 interface*/
  0x01,         /*bConfigurationValue: Configuration value*/
  0x00,         /*iConfiguration: Index of string descriptor describing
  the configuration*/
  0xE0,         /*bmAttributes: bus powered and Support Remote Wake-up */
  0x32,         /*MaxPower 100 mA: this current is used for detecting Vbus*/
  
  /************** Descriptor of Joystick Mouse interface ****************/
  /* 09 */
  0x09,         /*bLength: Interface Descriptor size*/
  USB_DESC_TYPE_INTERFACE,/*bDescriptorType: Interface descriptor type*/
  0x00,         /*bInterfaceNumber: Number of Interface*/
  0x00,         /*bAlternateSetting: Alternate setting*/
  0x01,         /*bNumEndpoints*/
  0x03,         /*bInterfaceClass: HID*/
  0x00,         /*bInterfaceSubClass : 1=BOOT, 0=no boot*/
  0x01,         /*nInterfaceProtocol : 0=none, 1=keyboard, 2=mouse*/
  0,            /*iInterface: Index of string descriptor*/
  /******************** Descriptor of Joystick Mouse HID ********************/
  /* 18 */
  0x09,         /*bLength: HID Descriptor size*/
  HID_DESCRIPTOR_TYPE, /*bDescriptorType: HID*/
  0x11,         /*bcdHID: HID Class Spec release number*/
  0x01,
  0x00,         /*bCountryCode: Hardware target country*/
  0x01,         /*bNumDescriptors: Number of HID class descriptors to follow*/
  0x22,         /*bDescriptorType*/
  HID_MOUSE_REPORT_DESC_SIZE,/*wItemLength: Total length of Report descriptor*/
  0x00,
  /******************** Descriptor of Mouse endpoint ********************/
  /* 27 */
  0x07,          /*bLength: Endpoint Descriptor size*/
  USB_DESC_TYPE_ENDPOINT, /*bDescriptorType:*/
  HID_EPIN_ADDR,     /*bEndpointAddress: Endpoint Address (IN)*/
  0x03,          /*bmAttributes: Interrupt endpoint*/
  HID_EPIN_SIZE, /*wMaxPacketSize: 4 Byte max */
  0x00,
  HID_FS_BINTERVAL,          /*bInterval: Polling Interval (10 ms)*/
  /* 34 */
} ;
```

It appears that by default STM provides 4 configuration descriptors.
Each descriptor explains the following:

### Configuration Descriptor

- **bLength** - length of descriptor, 9 bytes is normal.
- **bDescriptorType** - 2 for configuration descriptor
- **wTotalLength** - 34 bytes in total for the 4 sequential descriptors
- **bNumInterfaces** - By default the mouse device only exposes one interface
- **bConfigurationValue** - Numeric ID to select this configuration
- **iConfiguration** -  String descriptor
- **bmAttributes** - Power attributes
- **MaxPower** - represented in 2mA units

### Interface Descriptor

- **bLength** - length of descriptor, 9 bytes is normal.
- **bDescriptorType** - 4 for interface descriptor
- **bInterfaceNumber** - Zero-based value identifying the interface this descriptor is describing
- **bNumEndpoints** - Number of endpoints used by this interface, excluding endpoint zero
- **bInterfaceClass** - Class code, 3 = HID
- **bInterfaceSubClass** -  Subclass code, 0 = no subclass, 1 = boot interface 
- **bInterfaceProtocol** - Protocol class, 0 = none, 1 = keyboard, 2 = mouse
- **iInterface** - string describing interface

### [HID Descriptor](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=32)

- **bLength** - length of descriptor, 9 bytes is normal.
- **bDescriptorType** - 0x21 for HID descriptor
- **bcdHID** - binary-coded deimap specifying HID release, 0x11
- **bDescriptorType** - Report descriptor type - 0x22 = HID report descriptor
- **wDescriptorLenght** - Length of report descriptor, found in `usbd_hid.c`

### Endpoint Descriptor
- **bLength** - length of descriptor, 9 bytes is normal.
- **bDescriptorType** - 0x05 for endpoint descriptor
- **bEndpointAddress** - Given as 0x81 (0b10000001), encoded as:
    - Bit 0-3: endpoint number, ie. 1
    - Bit 4-6: reserved
    - Bit 7: direction, 0 for OUT and 1 for In, ie. IN
- **bmAttributes** - Describes the endpoints attributes, bits 0 and 1 give the transfer type
    - 00: Control
    - 01: Isochronous
    - 10: Bulk
    - 11: Interrupt
    For entire byte description see [this](https://www.beyondlogic.org/usbnutshell/usb5.shtml) page.
- **wMaxPacketSize** - Maximum packet size this endpoint is capable of sending
- **bInterval** - Interval for polling endpoint for data transfers. In milliseconds.

This default is for a mouse, below I will write up the necessary descriptors needed to add LEDs to a keyboard and then finally to combine a keyboard and mouse.

## Example keyboard device description vs Mouse device description

### Device Descriptor

| Part        | Keyboard           | Mouse  |
| ------------- |:-------------:| -----:|
| bLength | 0x12 | 0x12 |
| bDescriptorType | 0x1 | 0x1 |
| bcdUSB | 0x0200 | 0x0002 |
| bDeviceClass | 0x00 | 0x00 |
| bDeviceSubClass | 0x00 | 0x00 |
| bDeviceProtocol | 0x00 | 0x00 |
| bMaxPacketSize0 | 0x08 | 0x64 |
| idVendor  | xxxx | xxxx |
| idProduct | xxxx | xxxx |
| bcdDevice | xxxx | xxxx |
| iManufacturer | xx | xx |
| iProduct | xx | xx |
| iSerialNumber | xx | xx |
| bNumConfigurations | 0x01 | 0x01 |

### Configuration Descriptor

| Part        | Keyboard           | Mouse  |
| ------------- |:-------------:| -----:|
| bLength | 0x09 | 0x09 |
| bDescriptorType | 0x02 | 0x02 |
| wTotalLength | 59 | 34 |
| bNumInterfaces | 0x01 | 0x01 |
| bConfigurationValue | 0x01 | 0x01 |
| iConfiguration | 1 | 0 |
| bmAttributes | 0x20 | 0xE0 | <- Difference
| MaxPower | 0x32 | 0x32 |


### Interface Descriptor

| Part        | Keyboard           | Mouse  |
| ------------- |:-------------:| -----:|
| bLength | 0x09 | 0x09 |
| bDescriptorType | 0x04 | 0x04 |
| bInterfaceNumber | 0 | 0 |
| bAlternateSetting | 0 | 0 |
| bNumEndpoints | 1 | 1 |
| bInterfaceClass | 0x03 | 0x03 |
| bInterfaceSubClass | 0x01 | 0x01 |
| bInterfaceProtocol | 0x02 | 0x02 |
| iInterface | 0 | 0 |

### HID Descriptor

| Part        | Keyboard           | Mouse  |
| ------------- |:-------------:| -----:|
| bLength | 0x09 | 0x09 |
| bDescriptorType | 0x21 | 0x21 |
| bcdHID | 0x0101 | 0x0101 |
| bCountryCode | 0 | 0 |
| bNumDescriptors | 1 | 1 |
| bDescriptorType | 0x22 | 0x22 |
| wDescriptorLength | xx | xx |


### Endpoint Descriptor

| Part        | Keyboard           | Mouse  |
| ------------- |:-------------:| -----:|
| bLength | 0x07 | 0x07 |
| bDescriptorType | 0x05 | 0x05 |
| bEndpointAddress | 0x81 | 0x81 |
| bmAttributes | 0x03 | 0x03 |
| wMaxPacketSize | 0x09 | 32 |
| bInterval | 0x0A | 0x0A |

