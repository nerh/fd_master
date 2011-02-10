%% Объединение данных с отметчика и датчиков давления
% При получении скорости и ускорения в данном случае расчет производился по
% времени между пиками отметчика, а не времени между фронтами
%% Загрузка исходных данных 
pressure = load('/home/nerh/sent/ConvertedData/Режим_2/Pressure_7.mat');
speed = load('/home/nerh/sent/ConvertedData/Режим_2/Speed_7_interp.mat');
%% Обрабатка исходных данных
%Получаем информацию о давлении
pressureParams = getPressureParams(pressure.loadedFile.data(:,3)', 0.5, pressure.loadedFile.frequency, 30,10,1);
%Получаем информацию о скорости, ускорении, а также отображение времени на
%угол поворота
speedParams = getSpeedParams(speed.loadedFile.data(:,3)',speed.loadedFile.data(:,4)',speed.loadedFile.frequency,1440);

%% Постороение графика с заменой времени на угол поворота
screenSize = get(0,'ScreenSize');
f1 = figure;
hold on
plot(speedParams.angle_time.angle(1:length(pressure.loadedFile.data(:,3))), pressure.loadedFile.data(:,3))
stem(speedParams.angle_time.angle(speedParams.circleBeginTime), zeros(length(speedParams.circleBeginTime))...
    +max(pressure.loadedFile.data(:,3)),'r')
set(gca,'XTick',0:720:speedParams.angle_time.angle(end))
title('Pressure')
hold off
set(f1,'Position',[0 0 screenSize(3), screenSize(4)]);
figure
plot(speedParams.speed_absc,speedParams.speed*(2*pi/360))
title('Speed')
figure
plot(speedParams.acceleration_absc,speedParams.acceleration*(2*pi/360))
title('Acceleration')
figure
hold on
plot(speedParams.angle_time.angle(speedParams.leAbsc),speedParams.leTime)
set(gca,'XTick',0:4*720:speedParams.angle_time.angle(end))
title('Time')
hold off