# N-key Roll Over (NKRO) - WIP

A standard "BOOT compatible" HID keyboard can send at most 6 keys per HID report. This is explained in the parent READMEs of this repo. While these keyboards provide the advantage that they can be used in BIOS, they don't offer optimal performance for those wanting large simultaneous key presses (gamers I'm looking at you). To achieve NKRO the keyboards HID descriptor must be changed to structure the keypresses as bit flags instead of byte values.

This means that sending an 'a' press is no longer putting the `0x04` value into one of the report's 6 key bytes but instead you would set the 4th bit in the bitmap that has the same length as the largest keycode you wish to support.

As such, the individual report will be much larger as they will require a bitmap that is, on average, 110+ bits in length. Meaning that using 16+ bytes for the report is a smart idea. Given that you need 1 byte to represent the modifiers (this part does not change)