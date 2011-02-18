%% Объединение данных с отметчика и датчиков давления
% При получении скорости и ускорения в данном случае расчет производился по
% времени между пиками отметчика, а не времени между фронтами
%% Загрузка исходных данных 
pressure = load('/home/nerh/sent/ConvertedData/Режим_1/Pressure_7.mat');
speed = load('/home/nerh/sent/ConvertedData/Режим_1/Speed_7_interp.mat');
%% Обрабатка исходных данных
%Получаем информацию о давлении
cylinder = 2;
mainCylinder = 8;
cylindersSequence = [1,3,6,8,4,2,7,5];
pressureParams = getPressureParams(pressure.loadedFile.data(:,cylinder+1)', 0.5,...
                                                pressure.loadedFile.frequency, 30,10,1);
%Получаем информацию о скорости, ускорении, а также отображение времени на
%угол поворота
speedParams = getSpeedParams(speed.loadedFile.data(:,3)',speed.loadedFile.data(:,4)',...
                                                        speed.loadedFile.frequency,1440);

%% Постороение графика с заменой времени на угол поворота
%нахжожу вмт для заданного цилиндра
tdc = getTDC(speedParams.angle_time.angle(speedParams.circleBeginTime),mainCylinder,cylinder,cylindersSequence);
%за нулевой угол принимаю первую ВМТ
speedParams.angle_time.angle = speedParams.angle_time.angle - tdc(1);
[~,ptime1,ptime2] = intersect(speedParams.angle_time.time, pressure.loadedFile.data(:,1));
[~,stime1,stime2] = intersect(speedParams.angle_time.time,speedParams.speed_absc);
[~,atime1,atime2] = intersect(speedParams.angle_time.time,speedParams.acceleration_absc);
%гафик зависимости давления и скорости от угла
figure
hold on
plotyy(speedParams.angle_time.angle(stime1),speedParams.speed(stime2),...
    speedParams.angle_time.angle(ptime1),pressure.loadedFile.data(ptime2,cylinder+1))
title('pressure + speed')
legend('speed','pressure')
hold off

%гафик зависимости давления и ускорения от угла
figure
hold on
plotyy(speedParams.angle_time.angle(atime1),speedParams.acceleration(atime2),...
    speedParams.angle_time.angle(ptime1),pressure.loadedFile.data(ptime2,cylinder+1))
title('pressure + acceleration')
legend('acceleration','pressure')
hold off

%давление + ВМТ
figure
hold on
plot(speedParams.angle_time.angle(ptime1),pressure.loadedFile.data(ptime2,cylinder+1))
stem(tdc,ones(1,length(tdc))+max(pressure.loadedFile.data(:,cylinder+1)),'r')
title('pressure + TDC')
legend('pressure','TDC')
hold off

%расчет времени между ВМТ и впрыском
[~,tdcTime,~] = intersect(speedParams.angle_time.angle,tdc);
tdcTime = speedParams.angle_time.time(tdcTime);
advanceTime = [];
cycleNo = [];
for i = 1:length(pressureParams.pressurePeakTime)
    %находим момент впрыска, наиболее близкий к текущему пику
    [~,closestInjection] = min(abs(pressureParams.injectionStartTime-pressureParams.pressurePeakTime(i)));
    %находим вмт, наиболее близку к текущему пику
    [~,closestTdc] = min(abs(tdcTime-pressureParams.pressurePeakTime(i)));
    %находим угол для пика давления и момента впрыска
    [~,injectionAngle] = min(abs(speedParams.angle_time.time - pressureParams.injectionStartTime(closestInjection)));
    injectionAngle = speedParams.angle_time.angle(injectionAngle);
    [~,peakAngle] = min(abs(speedParams.angle_time.time - pressureParams.pressurePeakTime(i)));
    peakAngle = speedParams.angle_time.angle(peakAngle);
    %проверяем попадание ВМТ и впрыска в цикл, определяемый текущим пиком
    if abs(peakAngle-tdc(closestTdc))<=360 && abs(peakAngle-injectionAngle)<=360
        advanceTime = [advanceTime pressureParams.injectionStartTime(closestInjection)-tdcTime(closestTdc)];
    else
        advanceTime = [advanceTime NaN];
    end
    cycleNo = [cycleNo i];
end

figure
hold on
plot(pressure.loadedFile.data(:,1),pressure.loadedFile.data(:,cylinder+1))
stem(pressureParams.injectionStartTime,...
    zeros(1,length(pressureParams.injectionStartTime))+max(pressure.loadedFile.data(:,cylinder+1)),'g')
stem(tdcTime,ones(1,length(tdcTime))+max(pressure.loadedFile.data(:,cylinder+1)),'r')
title('pressure + TDC + injection time')
legend('pressure','injection','TDC')
hold off
advanceTime