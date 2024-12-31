@echo off
setlocal enabledelayedexpansion
:return
echo adb 서버 초기화...
adb kill-server
adb start-server
:retry
cls
echo 동일한 공유기에 연결된 모든 장치를 검색 중입니다...
echo ------------------------------------------

:: 현재 PC의 IP 주소 확인
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4"') do set pc_ip=%%i
echo 현재 PC의 IP 주소: %pc_ip%
echo 연결하고 싶은 안드로이드 장치의 ip를 선택하여 주세요.
echo ------------------------------------------
echo 0. 모든 장치에 연결을 시도합니다.

:: 192.168으로 시작하는 IP 주소를 리스트로 출력 (프로그램을 실행한 장치의 ip를 제외)
set count=0
for /f "tokens=1" %%i in ('arp -a ^| findstr "192.168" ^| findstr /v "%pc_ip%"') do (
    set /a count+=1
    echo !count!. %%i
    set ip[!count!]=%%i
)

:: 선택된 IP가 없는 경우 종료
if %count%==0 (
    echo 동일한 공유기에 연결된 장치가 없습니다.
    pause
    exit /b
)

echo ------------------------------------------
echo 종료하려면 리스트에 없는 숫자를 선택하세요.
set /p choice=IP 주소 목록에서 연결할 번호를 선택하세요 (0~%count%): 
echo ------------------------------------------

:: "0"을 입력하면 모든 IP에 연결 시도
if %choice%==0 (
    echo 모든 IP에 연결 시도 중...
    echo ------------------------------------------
    for /l %%i in (1,1,%count%) do (
        set selected_ip=!ip[%%i]!
        echo 연결 시도: !selected_ip!
        adb connect !selected_ip!
        
        :: adb devices 명령어로 연결된 디바이스가 있는지 확인
        adb devices > devices.txt
        findstr /i "!selected_ip!" devices.txt > nul
        if !errorlevel!==0 (
            findstr /i "unauthorized" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: 장치와 연결되었습니다.
                echo !selected_ip!: 안드로이드 장치에서 USB 디버깅을 허용하세요.
                del devices.txt
                pause
                adb devices > devices.txt
                findstr /i "unauthorized" devices.txt > nul
                if !errorlevel!==0 (
                    echo !selected_ip!: 연결에 성공했으나, 사용자가 디버깅을 차단했습니다.
                    pause
                ) else (
                    echo !selected_ip!: 디버깅 권한이 확인되었습니다.
                )
            )
            findstr /i "offline" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: 연결에 성공했으나, 장치가 오프라인 상태입니다.
                pause
            )
            findstr /i "5555      device" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: 이미 연결되어 있거나, 디버깅이 허용된 장치입니다.
                echo !selected_ip!: 성공적으로 다시 연결하였습니다.
            )
        ) else (
            echo 연결 실패: !selected_ip!
        )
        echo ------------------------------------------
    )
    echo 모든 장치에 연결을 시도했습니다.
    del devices.txt
    pause
    goto retry
)

:: 입력 번호가 유효한지 확인
if %choice% gtr %count% (
    echo 잘못된 번호입니다. 프로그램을 종료합니다.
    pause
    exit /b
)

if %choice% lss 1 (
    echo 잘못된 번호입니다. 프로그램을 종료합니다.
    pause
    exit /b
)

:: 선택된 IP로 ADB 연결 시도
set selected_ip=!ip[%choice%]!
echo 선택된 IP: %selected_ip%
echo ADB 연결 시도 중...
adb connect %selected_ip%

:: adb devices 명령어로 연결된 디바이스가 있는지 확인
adb devices > devices.txt
findstr /i "%selected_ip%" devices.txt > nul
if !errorlevel!==0 (
    findstr /i "unauthorized" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: 장치와 연결되었습니다.
        echo %selected_ip%: 안드로이드 장치에서 USB 디버깅을 허용하세요.
        del devices.txt
        echo ------------------------------------------
        pause
        adb devices > devices.txt
        findstr /i "unauthorized" devices.txt > nul
        if !errorlevel!==0 (
            echo %selected_ip%: 연결에 성공했으나, 사용자가 디버깅을 차단했습니다.
            del devices.txt
            echo ------------------------------------------
            pause
            goto return
        ) else (
            echo %selected_ip%: 디버깅 권한이 확인되었습니다.
            del devices.txt
            echo ------------------------------------------
            pause
            goto retry
        )
    )
    findstr /i "offline" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: 연결에 성공했으나, 장치가 오프라인 상태입니다.
        del devices.txt
        echo ------------------------------------------
        pause
        goto retry
    )
    findstr /i "5555      device" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: 이미 연결되어 있거나, 디버깅이 허용된 장치입니다. 
        echo %selected_ip%: 성공적으로 다시 연결하였습니다.
        del devices.txt
        echo ------------------------------------------
        pause
        goto retry
    )
) else (
    echo 연결 실패: %selected_ip%
    del devices.txt
    echo ------------------------------------------
)
pause
goto retry

:: AWCP의 무단 수정과 배포에 대하여 부정적입니다.
