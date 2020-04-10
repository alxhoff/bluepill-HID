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
While you can generate a custom HID device prosject using STM's cube, I find that modifying the standard HID example (a mouse) to be much less hassle, a little grepping will easily show you everything you need to rename if you do not want your descriptor to be labeled as a mouse descriptor.
Following the same process as the [cube](../cube) example to change the descriptor.
Namely, change the descriptor in `usbd_hid.c` in the array `HID_MOUSE_ReportDesc` and then in `hdbd_hid.h` change the `HID_MOUSE_REPORT_DESC_SIZE` to the appropriate size.

You will also need to change the `nInterfaceProtocol` and `bInterfaceSubClass` in `usbd_hid.c` depending on your descriptor.
It should be noted that the descriptor below is not BOOT compatible as the BOOT structure is as follows, see [here](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=79):

- 1 byte for modifiers
- 1 byte for reserved byte
- 6 bytes for keys

and as such a boot compatible struct would look like

``` c
struct bootHID_t {
    uint8_t modifiers;
    uint8_t reserved; // Not set
    uint8_t keys[6];
}
```

# Examples 

## Mouse

To demonstrate and, more importantly document, HID devices I will provide a keyboard example, a mouse example and an example where the two are fused into one homogeneous device that provides both functionalities.

Taking the same descriptor as from the cube desriptor

``` c
0x05,   0x01, // < USAGE_PAGE(generic desktop)
0x09,   0x02, // < USAGE(mouse)
0xA1,   0x01, // < COLLECTION(application)
0x09,   0x01, // <      USAGE(pointer)
0xA1,   0x00, // <      COLLECTION(physical)
0x05,   0x09, // <          USAGE_PAGE(button)
0x19,   0x01, // <          USAGE_MINIMUM(button 1)
0x29,   0x03, // <          USAGE_MAXIMUM(button 3)
0x15,   0x00, // <          LOGICAL_MINIMUM(0)
0x25,   0x01, // <          LOGICAL_MAXIMUM(1)
0x95,   0x03, // <          REPORT_COUNT(3)
0x75,   0x01, // <          REPORT_SIZE(1)
0x81,   0x02, // <          INPUT(data, Var, Abs)
0x95,   0x01, // <          REPORT_COUNT(1)
0x75,   0x05, // <          REPORT_SIZE(5) **padding
0x81,   0x01, // <          INPUT(const, array, Abs)
0x05,   0x01, // <          USAGE_PAGE(generic desktop)
0x09,   0x30, // <          USAGE(x)
0x09,   0x31, // <          USAGE(y)
0x09,   0x38, // <          USAGE(wheel)
0x15,   0x81, // <          LOGICAL_MINIMUM(-127)
0x25,   0x7F, // <          LOGICAL_MAXIMUM(127)
0x75,   0x08, // <          REPORT_SIZE(8)
0x95,   0x03, // <          REPORT_COUNT(3)
0x81,   0x06, // <          INPUT(data, var, rel)
0xC0,         // <      END_COLLECTION
0x09,   0x3c, // <      USAGE(motion wakeup)
0x05,   0xff, // <      USAGE_PAGE(UNKNOWN)
0x09,   0x01, // <      USAGE(pointer)
0x15,   0x00, // <      LOGICAL_MINIMUM(0)
0x25,   0x01, // <      LOGICAL_MAXIMUM(1)
0x75,   0x01, // <      REPORT_SIZE(1)
0x95,   0x02, // <      REPORT_COUNT(2)
0xb1,   0x22, // <      FEATURE(no preferred, variable)
0x75,   0x06, // <      REPORT_SIZE(6)
0x95,   0x01, // <      REPORT_COUNT(1)
0xb1,   0x01, // <      FEATURE(constant)s
0xc0          // < END_COLLECTION
// length =  74
```
This descriptor exposes an application collection consisting of
- A physical collection of 
    - Three buttons (left, right and middle) that are sent in one byte
    - Two 8 bit signed values (between -127 and 127) that are the X and Y axis
    - Followed by a scroll wheel that also has an 8 bit signed value between -127 and 127
- Lastly the function description of the mouse's ability to wake the computer

The `c` struct for this descriptor is 

``` c
struct mouseHID_t {
    uint8_t buttons;
    int8_t x;
    int8_t y;
    int8_t wheel;
};
```
It should also be noted, looking at [this](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=79#page=81) specification, that this descriptor is also BOOT compatible given that the wheel is appended after the required BOOT structure, see [here](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=79#page=69).

No for "funs" sake let's add a report ID to this descriptor as we will later need this when we combine it with a keyboard.
Adding in the `REPORT_ID(1)` (0x85, 0x01) after `USAGE(pointer)` should give the report an ID from 1, also no longer making the mouse boot compatible and as such `bInterfaceSubClass` needs to be set to `0`.

Lastly we must add the id to the struct we send

``` c 
struct mouseHID_t {
    uint8_t id; // always 1
    uint8_t buttons;
    int8_t x;
    int8_t y;
    int8_t wheel;
};
```
``` c
struct mouseHID_t myMouseHID = { .id = 1 };
``` 
This can be found in the [`HID_mouse_config`](HID_mouse_config) folder.

We can now do a simple loop of something like this to move our mouse every second

``` c
mouseHID.x = 100;                                                              

for(;;)                                                                        
{                                                                              
  osDelay(1000);                                                               
  HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);                                  
  USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &mouseHID, sizeof(struct mouseHID_t));
}      
```

To use the example descriptor run

``` bash
cmake -DUSBDevice_HID_CONFIG_DIR=HID_mouse_config ..
make
```

## Keyboard

Now we will use a keyboard example that is slightly differnt to the cube example, as we will add the required lines for supporting "on-keyboard" LEDs.

``` c
// Keyboard 57 bytes
0x05, 0x01,     //  USAGE_PAGE(generic desktop)
0x09, 0x06,     //  USAGE(keyboard)
0xA1, 0x01,     //  COLLECTION(application)
0x85, 0x02,     //      REPORT ID (2)
0x05, 0x07,     //      USAGE_PAGE(keyboard)
// modifiers
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x08,     //      REPORT_COUNT(8)
0x19, 0xE0,     //      USAGE_MINIMUM(left control)
0x29, 0xE7,     //      USAGE_MAXIMUM(right gui)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x01,     //      LOGICAL_MAXIMUM(1)
0x81, 0x02,     //      INPUT(data, var, abs)
// Keycodes
0x95, 0x06,     //      REPORT_COUNT(6)
0x75, 0x08,     //      REPORT_SIZE(8)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x65,     //      LOGICAL_MAXIMUM(101)
0x19, 0x00,     //      USAGE_MINIMUM(0)
0x29, 0x65,     //      USAGE_MAXIMUM(101)
0x81, 0x00,     //      INPUT(data, array, abs)
// LEDs
0x05, 0x08,     //      USAGE_PAGE(LEDs)
0x85, 0x04,     //      REPORT_ID(4aa)
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x05,     //      REPORT_COUNT(5)
0x19, 0x01,     //      USAGE_MINIMUM(num lock)
0x29, 0x05,     //      USAGE_MAXIMUM(Kana)
0x91, 0x02,     //      OUTPUT(data, var, abs)
0x75, 0x03,     //      REPORT_SIZE(3)
0x95, 0x01,     //      REPORT_COUNT(1)
0x91, 0x03,     //      OUTPUT(const, var, abs)  **padding**
0xC0,           //  END_COLLECTION
// Media 37 bytes
0x05, 0x0C,     //  USAGE_PAGE(consumer device)
0x09, 0x01,     //  USAGE(consumer control)
0xA1, 0x01,     //  COLLECTION(application)
0x85, 0x03,     //      REPORT_ID(3)
0x05, 0x0C,     //      USAGE_PAGE(consumer)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x01,     //      LOGICAL_MAXIMUM(1)
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x08,     //      REPORT_COUNT(8)
0x09, 0xB5,     //      USAGE(next track)
0x09, 0xB6,     //      USAGE(prev track)
0x09, 0xB7,     //      USAGE(stop)
0x09, 0xB8,     //      USAGE(eject)
0x09, 0xCD,     //      USAGE(play/pause)
0x09, 0xE2,     //      USAGE(mute)
0x09, 0xE9,     //      USAGE(vol up)
0x09, 0xEA,     //      USAGE(vol down)
0x81, 0x02,     //      INPUT(data, var, abs)
0xC0            //  END_COLLECTION
// Total bytes = 96
```

With a basic micro such as the bluepill we won't really be able to test the LED functionality, but we can test the rest.

The keyboard report is given the id of 2 and the media report an id of 3. Meaning we can send them separatley as media reports are not required anywhere as near as often as keyboard reports.

Our `c` structures will look as follows

``` c
#define MODIFIER_LEFT_CTRL      (1 << 0)
#define MODIFIER_LEFT_SHIFT     (1 << 1)
#define MODIFIER_LEFT_ALT       (1 << 2)
#define MODIFIER_LEFT_GUI       (1 << 3)
#define MODIFIER_RIGHT_CTRL     (1 << 4)
#define MODIFIER_RIGHT_SHIFT    (1 << 5)
#define MODIFIER_RIGHT_ALT      (1 << 6)
#define MODIFIER_RIGHT_GUI      (1 << 7)

struct keyboardHID_t {
    uint8_t id; // Must always be 2
    uint8_t modifiers;
    uint8_t keys[6];
};

#define MEDIA_NEXT_TRACK    (1 << 0)
#define MEDIA_PREV_TRACK    (1 << 1)
#define MEDIA_STOP          (1 << 2)
#define MEDIA_EJECT         (1 << 3)
#define MEDIA_PAUSE         (1 << 4)
#define MEDIA_MUTE          (1 << 5)
#define MEDIA_VOL_UP        (1 << 6)
#define MEDIA_VOL_DOWN      (1 << 7)

struct mediaHID_t {
    uint8_t id; // Must always be 3
    uint8_t keys; 
}
```
``` c
struct keyboardHID_t myKeyboardHID = { .id = 2 };
struct mediaHID_t myMediaHID = { .id = 3 };
```

It should be noted that as the keyboard descriptor contains an ID and does not follow the structure [here](https://www.usb.org/sites/default/files/documents/hid1_11.pdf#page=79#page=69) it is no longer BOOT compatible.

As a key must be pressed and released using a similar loop to the following will send a keypress every second.

``` c
for(;;)             
{
  osDelay(1000);
  keyboardHID.keys[0] = 0x04; // a              
  HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);        
  USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &keyboardHID, sizeof(struct keyboardHID_t));

  osDelay(10);                                                                        
  keyboardHID.keys[0] = 0x00; // Clear button, ie. button released             
  HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);                                  
  USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &keyboardHID, sizeof(struct keyboardHID_t));                   
} 
```
Similarly to the mouse example, this example descriptor can be build using

``` bash
cmake -DUSBDevice_HID_CONFIG_DIR=HID_keyboard_config ..
make
```

# Example

I have written a descriptor (not sure if it works yet) and it looks as follows:

``` c
struct myHID_t {
// MOUSE 76 bytes
0x05,   0x01, // < USAGE_PAGE(generic desktop)
0x09,   0x02, // < USAGE(mouse)
0xA1,   0x01, // < COLLECTION(application)
0x09,   0x01, // <      USAGE(pointer)
0x85,   0x01, // <      REPORT_ID(1)
0xA1,   0x00, // <      COLLECTION(physical)
// Buttons
0x05,   0x09, // <          USAGE_PAGE(button)
0x19,   0x01, // <          USAGE_MINIMUM(button 1)
0x29,   0x03, // <          USAGE_MAXIMUM(button 3)
0x15,   0x00, // <          LOGICAL_MINIMUM(0)
0x25,   0x01, // <          LOGICAL_MAXIMUM(1)
0x95,   0x03, // <          REPORT_COUNT(3)
0x75,   0x01, // <          REPORT_SIZE(1)
0x81,   0x02, // <          INPUT(data, Var, Abs)
0x95,   0x01, // <          REPORT_COUNT(1)
0x75,   0x05, // <          REPORT_SIZE(5) **padding
0x81,   0x01, // <          INPUT(const, array, Abs)
0x05,   0x01, // <          USAGE_PAGE(generic desktop)
// Axes and wheel
0x09,   0x30, // <          USAGE(x)
0x09,   0x31, // <          USAGE(y)
0x09,   0x38, // <          USAGE(wheel)
0x15,   0x81, // <          LOGICAL_MINIMUM(-127)
0x25,   0x7F, // <          LOGICAL_MAXIMUM(127)
0x75,   0x08, // <          REPORT_SIZE(8)
0x95,   0x03, // <          REPORT_COUNT(3)
0x81,   0x06, // <          INPUT(data, var, rel)
0xC0,         // <      END_COLLECTION
// Wakeup
0x09,   0x3c, // <      USAGE(motion wakeup)
0x05,   0xff, // <      USAGE_PAGE(UNKNOWN)
0x09,   0x01, // <      USAGE(pointer)
0x15,   0x00, // <      LOGICAL_MINIMUM(0)
0x25,   0x01, // <      LOGICAL_MAXIMUM(1)
0x75,   0x01, // <      REPORT_SIZE(1)
0x95,   0x02, // <      REPORT_COUNT(2)
0xb1,   0x22, // <      FEATURE(no preferred, variable)
0x75,   0x06, // <      REPORT_SIZE(6)
0x95,   0x01, // <      REPORT_COUNT(1)
0xb1,   0x01, // <      FEATURE(constant)s
0xc0          // < END_COLLECTION
// KEYBOARD 57 bytes
0x05, 0x01,     //  USAGE_PAGE(generic desktop)
0x09, 0x06,     //  USAGE(keyboard)
0xA1, 0x01,     //  COLLECTION(application)
0x85, 0x02,     //      REPORT ID (2)
0x05, 0x07,     //      USAGE_PAGE(keyboard)
// modifiers
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x08,     //      REPORT_COUNT(8)
0x19, 0xE0,     //      USAGE_MINIMUM(left control)
0x29, 0xE7,     //      USAGE_MAXIMUM(right gui)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x01,     //      LOGICAL_MAXIMUM(1)
0x81, 0x02,     //      INPUT(data, var, abs)
// Keycodes
0x95, 0x06,     //      REPORT_COUNT(6)
0x75, 0x08,     //      REPORT_SIZE(8)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x65,     //      LOGICAL_MAXIMUM(101)
0x19, 0x00,     //      USAGE_MINIMUM(0)
0x29, 0x65,     //      USAGE_MAXIMUM(101)
0x81, 0x00,     //      INPUT(data, array, abs)
// LEDs
0x05, 0x08,     //      USAGE_PAGE(LEDs)
0x85, 0x01,     //      REPORT_ID(1)
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x05,     //      REPORT_COUNT(5)
0x19, 0x01,     //      USAGE_MINIMUM(num lock)
0x29, 0x05,     //      USAGE_MAXIMUM(Kana)
0x91, 0x02,     //      OUTPUT(data, var, abs)
0x75, 0x03,     //      REPORT_SIZE(3)
0x95, 0x01,     //      REPORT_COUNT(1)
0x91, 0x03,     //      OUTPUT(const, var, abs)  **padding**
0xC0,           //  END_COLLECTION
// MEDIA 37 bytes
0x05, 0x0C,     //  USAGE_PAGE(consumer device)
0x09, 0x01,     //  USAGE(consumer control)
0xA1, 0x01,     //  COLLECTION(application)
0x85, 0x03,     //      REPORT_ID(3)
0x05, 0x0C,     //      USAGE_PAGE(consumer)
0x15, 0x00,     //      LOGICAL_MINIMUM(0)
0x25, 0x01,     //      LOGICAL_MAXIMUM(1)
0x75, 0x01,     //      REPORT_SIZE(1)
0x95, 0x08,     //      REPORT_COUNT(8)
0x09, 0xB5,     //      USAGE(next track)
0x09, 0xB6,     //      USAGE(prev track)
0x09, 0xB7,     //      USAGE(stop)
0x09, 0xB8,     //      USAGE(eject)
0x09, 0xCD,     //      USAGE(play/pause)
0x09, 0xE2,     //      USAGE(mute)
0x09, 0xE9,     //      USAGE(vol up)
0x09, 0xEA,     //      USAGE(vol down)
0x81, 0x02,     //      INPUT(data, var, abs)
0xC0            //  END_COLLECTION
// Total bytes = 172
};
```

The descriptor contains three application collections that implement the three functions of a keyboard that also has a mouse and media buttons.

Thus the three functions are:

- Standard keyboard with modifyer buttons and status LEDs
- A mouse that sends the following functions
  - 3 buttons: left, right and middle
  - A scroll wheel that has a value between -127 and 127
  - An X and Y axis that have values between -127 and 127
- A set of 8 media keys that send
  - Next track
  - Prev track
  - Stop
  - Eject
  - Play/Pause (manually modified from pdf descriptor becuase the tool sucks)
  - Mute
  - Vol up
  - Vol down

Now as the descriptor has a length of 172 bytes we can place the descriptor into `usbh_hid.c` and replace the appropriate length into `usbd_hid.h`.

Now that we have added the descriptor we need to add the appropriate structures for sending the reports. 
From the PDF you should see that each descriptor has a different IDs

- 1 = mouse
- 2 = modifiers and keypresses
- 3 = media

``` c

struct mouseHID_t {
    uint8_t id; // Must always be 1
    uint8_t buttons;
    int8_t x;
    int8_t y;
    int8_t wheel;
};

#define MODIFIER_LEFT_CTRL      (1 << 0)
#define MODIFIER_LEFT_SHIFT     (1 << 1)
#define MODIFIER_LEFT_ALT       (1 << 2)
#define MODIFIER_LEFT_GUI       (1 << 3)
#define MODIFIER_RIGHT_CTRL     (1 << 4)
#define MODIFIER_RIGHT_SHIFT    (1 << 5)
#define MODIFIER_RIGHT_ALT      (1 << 6)
#define MODIFIER_RIGHT_GUI      (1 << 7)

struct keyboardHID_t {
    uint8_t id; // Must always be 2
    uint8_t modifiers;
    uint8_t keys[6];
};

#define MEDIA_NEXT_TRACK    (1 << 0)
#define MEDIA_PREV_TRACK    (1 << 1)
#define MEDIA_STOP          (1 << 2)
#define MEDIA_EJECT         (1 << 3)
#define MEDIA_PAUSE         (1 << 4)
#define MEDIA_MUTE          (1 << 5)
#define MEDIA_VOL_UP        (1 << 6)
#define MEDIA_VOL_DOWN      (1 << 7)

struct mediaHID_t {
    uint8_t id; // Must always be 3
    uint8_t keys; 
}
```

Now we can send a keyboard report followed by a mouse report with some code similar to

``` c 
  mouseHID.x = 100;
  for(;;)
  {
    osDelay(1000);
    keyboardHID.keys[0] = 0x04; // a
    HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);
    USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &mouseHID, sizeof(struct mouseHID_t));
    osDelay(20);
    USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &keyboardHID, sizeof(struct keyboardHID_t));

    osDelay(20);
    keyboardHID.keys[0] = 0x00; // Clear button, ie. button released
    HAL_GPIO_TogglePin(LED_GPIO_Port, LED_Pin);
    USBD_HID_SendReport(&hUsbDeviceFS, (uint8_t*) &keyboardHID, sizeof(struct keyboardHID_t));
  }
```

This HID decriptor is in the [HID_hybrid_config](HID_hybrid_config) folder and can be built using

``` bash 
 cmake -DUSBDevice_HID_CONFIG_DIR=HID_hybrid_config ..
 make
```