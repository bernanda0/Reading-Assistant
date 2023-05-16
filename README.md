# ENHANCED READING ASSISTANT WITH ADAPTIVE ENVIRONMENT FEEDBACK

## 1. Introduction to the Problem and the Solution

The act of reading is a common activity for many people, whether it be reading physical books or digital content on gadgets. However, individuals often forget about good reading habits, such as maintaining an appropriate distance from the reading material and ensuring adequate lighting conditions. This can lead to discomfort, eye strain, and a suboptimal reading experience. To address this problem, we have developed an Enhanced Reading Assistant with Adaptive Environment Feedback. This solution is powered by the Arduino Uno R3 microcontroller board. The reading assistant incorporates various hardware components and employs adaptive feedback mechanisms to optimize the reading experience. 

The system has the following features :

1. **Illumi Read**: The assistant incorporates a photoresistor to detect ambient light levels. When the environment becomes dark, it activates an LED to provide additional illumination for reading.

2. **Opti Guard**: The project utilizes an HCSR04 ultrasonic sensor to monitor the distance of objects in front of the reader. If the distance value falls below or equals 16 centimeters, the system activates a buzzer as a warning signal to prevent collisions or accidents.

3. **Display**: Information about the reading environment is displayed using a SPI display 7-Segment module with MAX7219. The displayed information includes the distance in centimeters and the environmental status, indicating whether it is dark and close.

## 2. Hardware Design and Implementation Details

<img src='https://drive.google.com/uc?export=view&id=1_zuMAL0KBxVh98iL9per3l0YEXnDudtb'>

The circuit design incorporates the following base components:

- HCSR04 Sensor and buzzer actuator for distance feedback.
- Photoresistor and LED actuator for light feedback.
- 7-Segment MAX7219 module for information display.

## 3. Software Implementation Details

The software for the reading assistant is written in assembly language to achieve full control and fast performance. The code for the project can be found in the `sketch.S` file. You can refer to this file to examine the code implementation. The functionality of the system is based on the following flowcharts:

1. **System Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1zdHJZx_fL8t9JyieFOO-DrL_5-B5Z_eG" width=720>

2. **Illumi Read Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1d5z9GpsiufcAzCeT8_k1i-DF99oxLBrW" width=128>

3. **Opti Guard Flowchart**
<img src="https://drive.google.com/uc?export=view&id=1T4rZ7Q-ZnmkeV5QanpaMJvK7_h7hHLm2" width=480>

By following the code and examining the flowcharts, you can gain a deeper understanding of the logic and operation of the system.

## 4. Test Results and Performance Evaluation

The system was primarily tested using Proteus simulation. The tests demonstrated that the system functions as desired. The readings from the HCSR04 sensor and photoresistor accurately determine the appropriate actions for the actuators. The use of assembly language programming ensures efficient performance, enabling quick response times and optimal system operation.

The result of the system is shown as below

- The lightfeedback result. The LED will be turned on when the photoresistor detect the lack of light in the surrounding. 
<img src="https://drive.google.com/uc?export=view&id=1yULy5kUx76y-ajocPyGxAEIgMfPvy1BZ" width=360>

- The distance feedback result. When the user getting too close with the reading object (i.e < 16 cm) the buzzer will be turned on to alarm the user. 
<img src="https://drive.google.com/uc?export=view&id=1MMrkEHaPlk5d5921R1NYAGKEImWRVIIA" width=360>

- The current value of the distance and the environmental status (dark and close) will be displayed on the 7-Segment MAX7219 module.
<img src="https://drive.google.com/uc?export=view&id=19Dvm-7ekwWT70YiJkYswGFBMXnmPSLF6" width=720>

If you want to simulate the system in Proteus 8, follow these steps:
1. Open the `sketch.S` code using the Arduino IDE and export the compiled binary.
<img src="https://drive.google.com/uc?export=view&id=1p2zhHyxPjMLRmgHGWp_wRgqLrv-D7liq" width=360>
2. Locate the `.hex` file and copy its path.
<img src="https://drive.google.com/uc?export=view&id=1SEySeSAuC6fZaZTYG7BGK9DJAbdBOGKy" width=240>
3. Open the Proteus project and double click on the Arduino component. It should open a dialog box.
4. In the dialog box, paste the copied path in the "Program File" field.
<img src="https://drive.google.com/uc?export=view&id=1tl45Q1FNmYnzOfqV0Gx1ZPdUMdC938UJ" width=240>
5. Click "OK" to apply the changes.
6. Now, you can enjoy simulating the enhanced reading assistant system in Proteus.

## 5. Conclusion and Future Work

In conclusion, the enhanced reading assistant with adaptive environment feedback provides an effective solution to address common reading habits that can negatively impact the reading experience. By incorporating distance feedback, light feedback, and information display, users can maintain proper reading distance, have adequate lighting, and receive relevant information about the reading environment.

In addition to the features, we plan to incorporate the following enhancements: 

- **Timer**: We intend to add a timer feature that allows users to set a predefined reading time. The assistant will provide notifications or alerts when the reading time is about to expire.

- **Interrupt Button**: To provide more flexibility and control, we will include an interrupt button. This button can be pressed by the user to pause or stop the reading session at any time.
The entire project is coded in assembly language to achieve full control over the microcontroller and ensure fast performance.
