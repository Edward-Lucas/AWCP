@echo off
setlocal enabledelayedexpansion
:return
echo adb ���� �ʱ�ȭ...
adb kill-server
adb start-server
:retry
cls
echo ������ �����⿡ ����� ��� ��ġ�� �˻� ���Դϴ�...
echo ------------------------------------------

:: ���� PC�� IP �ּ� Ȯ��
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4"') do set pc_ip=%%i
echo ���� PC�� IP �ּ�: %pc_ip%
echo �����ϰ� ���� �ȵ���̵� ��ġ�� ip�� �����Ͽ� �ּ���.
echo ------------------------------------------
echo 0. ��� ��ġ�� ������ �õ��մϴ�.

:: 192.168���� �����ϴ� IP �ּҸ� ����Ʈ�� ��� (���α׷��� ������ ��ġ�� ip�� ����)
set count=0
for /f "tokens=1" %%i in ('arp -a ^| findstr "192.168" ^| findstr /v "%pc_ip%"') do (
    set /a count+=1
    echo !count!. %%i
    set ip[!count!]=%%i
)

:: ���õ� IP�� ���� ��� ����
if %count%==0 (
    echo ������ �����⿡ ����� ��ġ�� �����ϴ�.
    pause
    exit /b
)

echo ------------------------------------------
echo �����Ϸ��� ����Ʈ�� ���� ���ڸ� �����ϼ���.
set /p choice=IP �ּ� ��Ͽ��� ������ ��ȣ�� �����ϼ��� (0~%count%): 
echo ------------------------------------------

:: "0"�� �Է��ϸ� ��� IP�� ���� �õ�
if %choice%==0 (
    echo ��� IP�� ���� �õ� ��...
    echo ------------------------------------------
    for /l %%i in (1,1,%count%) do (
        set selected_ip=!ip[%%i]!
        echo ���� �õ�: !selected_ip!
        adb connect !selected_ip!
        
        :: adb devices ��ɾ�� ����� ����̽��� �ִ��� Ȯ��
        adb devices > devices.txt
        findstr /i "!selected_ip!" devices.txt > nul
        if !errorlevel!==0 (
            findstr /i "unauthorized" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: ��ġ�� ����Ǿ����ϴ�.
                echo !selected_ip!: �ȵ���̵� ��ġ���� USB ������� ����ϼ���.
                del devices.txt
                pause
                adb devices > devices.txt
                findstr /i "unauthorized" devices.txt > nul
                if !errorlevel!==0 (
                    echo !selected_ip!: ���ῡ ����������, ����ڰ� ������� �����߽��ϴ�.
                    pause
                ) else (
                    echo !selected_ip!: ����� ������ Ȯ�εǾ����ϴ�.
                )
            )
            findstr /i "offline" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: ���ῡ ����������, ��ġ�� �������� �����Դϴ�.
                pause
            )
            findstr /i "5555      device" devices.txt > nul
            if !errorlevel!==0 (
                echo !selected_ip!: �̹� ����Ǿ� �ְų�, ������� ���� ��ġ�Դϴ�.
                echo !selected_ip!: ���������� �ٽ� �����Ͽ����ϴ�.
            )
        ) else (
            echo ���� ����: !selected_ip!
        )
        echo ------------------------------------------
    )
    echo ��� ��ġ�� ������ �õ��߽��ϴ�.
    del devices.txt
    pause
    goto retry
)

:: �Է� ��ȣ�� ��ȿ���� Ȯ��
if %choice% gtr %count% (
    echo �߸��� ��ȣ�Դϴ�. ���α׷��� �����մϴ�.
    pause
    exit /b
)

if %choice% lss 1 (
    echo �߸��� ��ȣ�Դϴ�. ���α׷��� �����մϴ�.
    pause
    exit /b
)

:: ���õ� IP�� ADB ���� �õ�
set selected_ip=!ip[%choice%]!
echo ���õ� IP: %selected_ip%
echo ADB ���� �õ� ��...
adb connect %selected_ip%

:: adb devices ��ɾ�� ����� ����̽��� �ִ��� Ȯ��
adb devices > devices.txt
findstr /i "%selected_ip%" devices.txt > nul
if !errorlevel!==0 (
    findstr /i "unauthorized" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: ��ġ�� ����Ǿ����ϴ�.
        echo %selected_ip%: �ȵ���̵� ��ġ���� USB ������� ����ϼ���.
        del devices.txt
        echo ------------------------------------------
        pause
        adb devices > devices.txt
        findstr /i "unauthorized" devices.txt > nul
        if !errorlevel!==0 (
            echo %selected_ip%: ���ῡ ����������, ����ڰ� ������� �����߽��ϴ�.
            del devices.txt
            echo ------------------------------------------
            pause
            goto return
        ) else (
            echo %selected_ip%: ����� ������ Ȯ�εǾ����ϴ�.
            del devices.txt
            echo ------------------------------------------
            pause
            goto retry
        )
    )
    findstr /i "offline" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: ���ῡ ����������, ��ġ�� �������� �����Դϴ�.
        del devices.txt
        echo ------------------------------------------
        pause
        goto retry
    )
    findstr /i "5555      device" devices.txt > nul
    if !errorlevel!==0 (
        echo %selected_ip%: �̹� ����Ǿ� �ְų�, ������� ���� ��ġ�Դϴ�. 
        echo %selected_ip%: ���������� �ٽ� �����Ͽ����ϴ�.
        del devices.txt
        echo ------------------------------------------
        pause
        goto retry
    )
) else (
    echo ���� ����: %selected_ip%
    del devices.txt
    echo ------------------------------------------
)
pause
goto retry

:: AWCP�� ���� ������ ������ ���Ͽ� �������Դϴ�.
