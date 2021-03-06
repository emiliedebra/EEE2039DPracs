/*
 * woodboxstm32f051C6.h
 *
 *  Created on: Oct 3, 2014
 *      Author: Sean Wood - WDXSEA003
 *      		University of Cape Town
 *
 *  This is the header file.
 *
 *  This WoodBox is a collection of commonly used and generally
 *  pesky things that one wants to do with the STM32F051C6, but
 *  don't want to have to place in one's source! Yay!
 */

#ifndef WOODBOXSTM32F051C6_H_
#define WOODBOXSTM32F051C6_H_

#include <stdint.h>
#include "stm32f0xx.h"
#include "eeprom_lib.h"

enum POTSEL {POT0, POT1};

void initLEDs();
void initPB(void);
void initADCPot(int POT);
void delayms(uint32_t length); // Millisecond delay function
void delaypointms(uint32_t length); // Point 1 millisecond delay function
int16_t getPot(void);
int8_t getPB(int button);
void incrementLEDs(int8_t amount);



#endif /* WOODBOXSTM32F051C6_H_ */
