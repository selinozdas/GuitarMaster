# GuitarMaster
A version of well-known game Guitar Hero on FPGA board. 
Our version, Guitar Master, is being played by pressing buttons which are
synchronized according to music’s rhythm. In our project 10 bit music will be used and
every 2 bit will be associated with one button. Those bit pairs will be represented by
different colors(red, green, blue and white). Color boxes will flow through the screen
according to the rhythm which is pre-defined by us. Players need to press the buttons
matching with the color boxes to finish the level. The level completeness will be
represented by a bar. There will be music at the background as base and when players
press decent buttons at proper time button related rhythms will be added to the base
music and increase the level bar. However, when players forget to press to button or
mistakenly press the wrong button the game will give an instant warning sound and
lower the level bar.


The overall project is the SystemVerilog translation of the Verilog project https://github.com/cwilkens/fpga-hero
