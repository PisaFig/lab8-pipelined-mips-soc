@echo off
REM Test validation wrapper with Icarus Verilog

echo ============================================
echo Validation Wrapper Test - Icarus Verilog
echo ============================================
echo.

REM Change to script directory parent
cd /d "%~dp0\.."

echo Compiling validation wrapper test...
echo.

iverilog -g2012 -o validation_test.vvp -s validation_wrapper_test ^
    src/pipelined_mips.v ^
    src/datapath.v ^
    src/pipeline_reg.v ^
    src/hazard_unit.v ^
    src/forwarding_unit.v ^
    src/controlunit.v ^
    src/maindec.v ^
    src/auxdec.v ^
    src/alu.v ^
    src/regfile.v ^
    src/signext.v ^
    src/adder.v ^
    src/mux2.v ^
    src/dreg.v ^
    src/hilo.v ^
    src/multu.v ^
    src/mips_top.v ^
    memory/imem.v ^
    memory/dmem.v ^
    src/gpio.v ^
    src/factorial_accel.v ^
    validation_wrapper/clk_gen.v ^
    validation_wrapper/button_debouncer.v ^
    validation_wrapper/hex_to_7seg.v ^
    validation_wrapper/led_mux.v ^
    validation_wrapper/mips_fpga.v ^
    testbench/validation_wrapper_test.v

if errorlevel 1 (
    echo.
    echo ============================================
    echo COMPILATION FAILED!
    echo ============================================
    echo Check the errors above.
    pause
    exit /b 1
)

echo.
echo Compilation successful!
echo.
echo Running simulation...
echo ============================================
echo.

vvp validation_test.vvp

if errorlevel 1 (
    echo.
    echo ============================================
    echo SIMULATION FAILED!
    echo ============================================
    pause
    exit /b 1
)

echo.
echo ============================================
echo Validation Wrapper Test Complete!
echo ============================================
echo.
echo If waveform was generated, view with:
echo   gtkwave validation_wrapper_test.vcd
echo.
pause

