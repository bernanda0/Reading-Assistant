# ENHANCED READING ASSISTANT WITH ADAPTIVE ENVIRONMENT FEEDBACK

This project aims to create an enhanced reading assistant using the Arduino Uno R3 with Atmega328p microcontroller. The assistant provides adaptive environment feedback to optimize the reading experience. It utilizes various sensors and components to dynamically adjust the reading conditions based on the surrounding environment.

## Main Features:
1. **Illumi Read**: The assistant incorporates a photoresistor to detect ambient light levels. When the environment becomes dark, it activates an LED to provide additional illumination for reading.

2. **Opti Guard**: The project utilizes an HCSR04 ultrasonic sensor to monitor the distance of objects in front of the reader. If the distance value falls below or equals 16 centimeters, the system activates a buzzer as a warning signal to prevent collisions or accidents.

3. **Display**: Information about the reading environment is displayed using a SPI display 7-Segment module with MAX7219. The displayed information includes the distance in centimeters and the environmental status, indicating whether it is dark and close.

In addition to the above features, we plan to incorporate the following enhancements: (not yet implemented)

4. **Timer**: We intend to add a timer feature that allows users to set a predefined reading time. The assistant will provide notifications or alerts when the reading time is about to expire.

5. **Interrupt Button**: To provide more flexibility and control, we will include an interrupt button. This button can be pressed by the user to pause or stop the reading session at any time.

The entire project is coded in assembly language to achieve full control over the microcontroller and ensure fast performance.

By combining these features, the enhanced reading assistant provides an adaptive and interactive reading experience. The assembly coding allows for efficient control and quick response, enhancing the overall performance of the system.

## The Circuit
<img src='https://drive.google.com/uc?export=view&id=1_zuMAL0KBxVh98iL9per3l0YEXnDudtb'>

To simulate the system in Proteus 8, follow these steps:
1. Open the `sketch.S` code using the Arduino IDE and export the compiled binary.
<img src="https://drive.google.com/uc?export=view&id=1p2zhHyxPjMLRmgHGWp_wRgqLrv-D7liq" width=360>
2. Locate the `.hex` file and copy its path.
<img src="https://drive.google.com/uc?export=view&id=1SEySeSAuC6fZaZTYG7BGK9DJAbdBOGKy" width=240>
3. Open the Proteus project and double click on the Arduino component. It should open a dialog box.
4. In the dialog box, paste the copied path in the "Program File" field.
<img src="https://drive.google.com/uc?export=view&id=1tl45Q1FNmYnzOfqV0Gx1ZPdUMdC938UJ" width=240>
5. Click "OK" to apply the changes.
6. Now, you can enjoy simulating the enhanced reading assistant system in Proteus.

## How to operate

To operate the enhanced reading assistant system in the simulation:

1. Control the flashlight by moving the red up arrow and down arrow icon near the photoresistor. 
<img src="https://drive.google.com/uc?export=view&id=1yULy5kUx76y-ajocPyGxAEIgMfPvy1BZ" width=360>
2. Control the distance by also moving the red left arrow and right arrow icon. 
<img src="https://drive.google.com/uc?export=view&id=1MMrkEHaPlk5d5921R1NYAGKEImWRVIIA" width=360>
3. The current value of the distance and the environmental status (dark and close) will be displayed on the 7-Segment MAX7219 module.
<img src="https://drive.google.com/uc?export=view&id=19Dvm-7ekwWT70YiJkYswGFBMXnmPSLF6" width=720>

## The code
The assembly code for the project can be found in the `sketch.S` file. You can refer to this file to examine the code implementation. The functionality of the system is based on the following flowcharts:

1. **System Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1zdHJZx_fL8t9JyieFOO-DrL_5-B5Z_eG" width=720>

2. **Illumi Read Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1d5z9GpsiufcAzCeT8_k1i-DF99oxLBrW" width=128>

3. **Opti Guard Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1T4rZ7Q-ZnmkeV5QanpaMJvK7_h7hHLm2" width=480>

By following the code and examining the flowcharts, you can gain a deeper understanding of the logic and operation of the system.

## Documentation
