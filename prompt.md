**Role:** Expert Garmin Connect IQ Developer (Monkey C Specialist).
**Task:** Create a Watch Face for Garmin watches supporting AMOLED, MIP, and MicroLED displays.

### 1. Visual Geometry & Layout

The design is based on a central black ring (circular band) that separates the screen into inner and outer zones. Use the following coordinate system (0° is top/12 o'clock):

* **Central Element:** A thick black ring.
* **Placement Logic:** * **Icons/Letters:** Must be drawn **inside** the black ring.
* **Data Values:** Must be drawn **outside** the ring, aligned radially with their respective icons.


* **Angular Data Points:**
* 18°: Battery (Days) Icon | Value outside.
* 54°: Heart Rate Icon | BPM value outside.
* 78°: Altitude Icon | Meters/Feet value outside.
* 108°: Sun Event (Sunrise/Sunset) Icon | Time of next event outside.
* 132°: Temperature Icon | Temp value outside.
* 156°: Letter "Н" (Day of week) | Day name outside.
* 180°: No icon | Day of month value outside.
* 204°: Letter "М" (Month) | Month name outside.
* 258°: Barometer Icon | Pressure value outside.
* 270°: Calories Icon | Calorie count outside.
* 306°: Steps Icon | Step count outside.
* 342°: Battery (%) Icon | Percentage value outside.



### 2. Functional Requirements

* **Analog Hands:** Implement Hour, Minute, and Second hands.
* **Background:** Inside the ring, implement a faded "Polar Projection World Map" as a background image/vector.
* **Text Constraints:** Do NOT render degree or minute markers as digits. Only render the specific sensor/time data values requested.

### 3. Technical Implementation Details

* **Display Optimization:**
* **AMOLED/MicroLED:** Use high-contrast colors (white text on black/dark gray) and implement a "Burn-in protection" (Always-on Display mode) which shifts pixels or reduces active elements.
* **MIP:** Use 8-bit color palette optimization and high-contrast lines for outdoor readability.


* **Math:** Provide the logic for calculating $X, Y$ coordinates for elements based on the angle $\theta$ and screen radius $R$:

$$X = Center_X + R \cdot \sin(\theta)$$


$$Y = Center_Y - R \cdot \cos(\theta)$$


* **Data Handling:** Use `ActivityMonitor`, `SensorHistory`, and `System.getSystemStats()` to fetch real-time data.

### 4. Output Format

1. **Monkey C Code:** Provide the `View.mc` class with the `onUpdate()` method.
2. **Resource XML:** Define the fonts and drawables (icons).
3. **Optimization Tips:** Explain how to handle the "Tactix" style aesthetic without exceeding memory limits (64kb-128kb).

---
