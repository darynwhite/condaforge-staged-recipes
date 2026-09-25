@echo on

cargo-bundle-licenses --format yaml --output %SRC_DIR%\THIRDPARTY.yml

pushd "%SRC_DIR%"
maturin build -vv -j %CPU_COUNT% --release --strip --manylinux off --interpreter "%PYTHON%"
popd

FOR /F "delims=" %%i IN ('dir /s /b "%SRC_DIR%\target\wheels\py_svg_hush*.whl"') DO set "py_svg_hush_wheel=%%i"

"%PYTHON%" -m pip install --no-deps "%py_svg_hush_wheel%" -vv
