@WDXSEA003 CHTREE002

  .syntax unified
  .cpu cortex-m0
  .thumb
  .global _start

vectors:                                                    @== All those vectors!
  .word 0x20002000                                          @ Stack pointer reset value
  .word _start + 1                                          @ Reset vector (execution start specification)
  .word Default_Handler + 1                                 @ 0x04: NMI handler - just redirecting to default handler for now
  .word HardFault_Handler + 1                               @ 0x06: Hardfault handler vector
  .word Default_Handler + 1                                 @ 0x10: reserved
  .word Default_Handler + 1                                 @ 0x14: reserved
  .word Default_Handler + 1                                 @ 0x18: reserved
  .word Default_Handler + 1                                 @ 0x1C: reserved
  .word Default_Handler + 1                                 @ 0x20: reserved
  .word Default_Handler + 1                                 @ 0x24: reserved
  .word Default_Handler + 1                                 @ 0x28: reserved
  .word Default_Handler + 1                                 @ 0x2C: SVCall vector
  .word Default_Handler + 1                                 @ 0x30: reserved
  .word Default_Handler + 1                                 @ 0x34: reserved
  .word Default_Handler + 1                                 @ 0x38: SysTick vector


HardFault_Handler:                                          @== Exectuted in the event of a hard fault
  LDR R5, PORTB_START
  LDR R6, =0b11100111
  STR R6, [R5, 0x14]
  B HardFault_Handler

Default_Handler:                                            @== Executed in the event of any other fault or exception
  LDR R0, PORTB_START
  LDR R1, =0b11000011
  STR R1, [R0, 0x14]
  B Default_Handler

_start:
  BL LEDInit                                                @ Enable the LEDs
  BL pot_poll_init                                          @ Enable ADC for POT0
    @ enable clock to ADC, Timer 6, GPIOA, GPIOB
    @ set pins to correct modes
    @ pullups for buttons
    @ enable ADC
    @ wait until ADC ready. As per Section 13.4.4: the ADC must be ready before writing to its other registers
    @ select channel and resolution/alignment 
    @ initialise timer: Set ARR, PSR, enable update interrupt
    @ start counter counting
    @ enable the interrupt for the timer in the NVIC

TIM6_ADC_IRQHandler:                                        @== Interrupt Service Routine (for ADC and TIM6)
    @ acknowledge interrupt

    @ ==== Part 2 suggested algoritim ====
    @ Read GPIOB_ODR (remember, we're only interested in the LSB!)
    @ if SW3 is held down: add 1 to it
    @ else: subtract 1 from it
    @ write it back

    @ ==== Part 3 suggested algorithm ====
    @ if SW2 is held down:
        @ kick off an ADC conversion from POT1
        @ modify timer duration using result of conversion
    @ else:
        @ set the IRQ frequency to the default state

    @ return from interrupt here


@== Subroutines

LEDInit:
  LDR R0, RCC_START                                         @ Enable GPIOA and GPIOB RCC Clock
  LDR R2, [R0, 0x14]
  LDR R3, RCC_AHBENR_GPIO_ABEN
  ORRS R2, R2, R3
  STR R2, [R0, 0x14]
  LDR R0, PORTB_START
  LDR R2, PORTB_MODEROUT                                    @ Set Port B Mode to OUTPUT
  STR R2, [R0]
  BX LR


pot_poll_init:                                              @== Inialisation of the pots (ADC etc)
  LDR R0, RCC_START
  LDR R1, [R0, 0x18]                                        @ Enable RCC for ADC
  LDR R2, RCC_APB2ENR_ADC_EN
  ORRS R1, R1, R2
  STR R1, [R0, 0x18]

  LDR R0, PORTA_START                                       @ Set PA5 to ANALOG
  LDR R1, [R0]
  LDR R2, GPIOA_MODER_MODER5
  ORRS R1, R1, R2
  STR R1, [R0]

  LDR R0, ADC1_START                                        @ Select ADC channel 5
  LDR R1, [R0, 0x28]
  LDR R2, ADC_CHSELR_CHSEL5
  ORRS R1, R1, R2
  STR R1, [R0, 0x28]

  LDR R1, [R0, 0x0C]                                        @ Set resolution to 8 bits
  LDR R2, ADC_CFGR1_RES_1
  ORRS R1, R1, R2
  STR R1, [R0, 0x0C]

  LDR R1, [R0, 0x08]                                        @ Set ADEN = 1
  LDR R2, ADC_CR_ADEN
  ORRS R1, R1, R2
  STR R1, [R0, 0x08]

  B pot_poll_init_wait

pot_poll_init_wait:                                         @== Basically wait for the ADC to let us know it is ready
  LDR R0, ADC1_START
  LDR R1, [R0]
  LDR R2, ADC_ISR_ADRDY
  ANDS R1, R1, R2
  CMP R1, #0
  BEQ pot_poll_init_wait
  BX LR

pot_get:                                                    @== Gets the pot value
  LDR R0, ADC1_START                                        @ Starting a conversion
  LDR R1, [R0, 0x08]
  LDR R2, ADC_CR_ADSTART
  ORRS R1, R1, R2
  STR R1, [R0, 0x08]
  B pot_get_wait

pot_get_wait:                                               @== Waits for conversion to be finished
  LDR R1, [R0]
  LDR R2, ADC_ISR_EOC
  ANDS R1, R1, R2
  CMP R1, #0
  BEQ pot_get_wait
  LDR R7, [R0, 0x40]
  LDR R0, PORTB_START
  BX LR

  .align
@== Program Variables
RCC_START:              .word 0x40021000
RCC_AHBENR_GPIO_ABEN:   .word 0x00060000
PORTA_START:            .word 0x48000000
PORTA_MODERIN:          .word 0x28000000
PORTA_PUPDR:            .word 0x55
PORTB_START:            .word 0x48000400
PORTB_MODEROUT:         .word 0x00005555
STACK_1_START:          .word 0x20002000
DELAY_1:                .word 0x000C3500 @ 0.5 secs
VARDELAY_GRAD:          .word 0x00000C65 @ Gradient for the linear pot/dely relationship
RAM_START:              .word 0x20000000

RCC_APB2ENR_ADC_EN:     .word 0x00000200 @ ADC enable bit
GPIOA_MODER_MODER5:     .word 0x00000C00 @ Port A5 analog mode
GPIOA_MODER_MODER6:     .word 0x00003000 @ Port A6 analog mode
ADC1_START:             .word 0x40012400 @ Start of ADC registers
ADC_CHSELR_CHSEL5:      .word 0x00000020 @ Channel 5 select bit
ADC_CHSELR_CHSEL6:      .word 0x00000040 @ Channel 6 select bit
ADC_CFGR1_RES_1:        .word 0x00000010 @ 8 bit resolution bit
ADC_CR_ADEN:            .word 0x00000001 @ ADEN = 1
ADC_ISR_ADRDY:          .word 0x00000001 @ ADC ready bit
ADC_CR_ADSTART:         .word 0x00000004 @ ADC conversion start bit
ADC_ISR_EOC:            .word 0x00000004 @ ADC conversion complete bit
