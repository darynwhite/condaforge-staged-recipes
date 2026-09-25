@echo on
setlocal enabledelayedexpansion

pushd "%SRC_DIR%"
if exist "%SRC_DIR%\target\wheels\py_svg_hush*.whl" del /q "%SRC_DIR%\target\wheels\py_svg_hush*.whl"
cargo-bundle-licenses --format yaml --output %SRC_DIR%\THIRDPARTY.yml
maturin build -vv -j %CPU_COUNT% --release --strip --interpreter "%PYTHON%"
popd

set "wheel_count=0"
FOR /F "delims=" %%i IN ('dir /b /a-d "%SRC_DIR%\target\wheels\py_svg_hush*.whl"') DO (
    set /a wheel_count+=1
    set "py_svg_hush_wheel=%SRC_DIR%\target\wheels\%%i"
)

if not "!wheel_count!"=="1" (
    echo Expected exactly one py_svg_hush wheel, found !wheel_count!
    dir /b "%SRC_DIR%\target\wheels\py_svg_hush*.whl"
    exit /b 1
)

"%PYTHON%" -m pip install --no-deps "!py_svg_hush_wheel!" -vv
