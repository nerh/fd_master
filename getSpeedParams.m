function [ result ] = getSpeedParams( marker, TDC, freq, marksPerCircle )
%getSpeedParams
%
%Входные параметры:
%   marker - ординаты отметчика
%   TDC - ординаты отметчика (вмт)
%   freq - частота (количество квантов в секунду)
%   marksPerCircle - количество отметок для одного оборота вала
%
%Выходные значения:
%   result - структура содержащая полученную информацию
%       result.circleBeginTime - абсцисса начала каждого цикла ()
%       result.circleEndTime - абсцисса конца каждого цикла
%       result.angle_time - структура, содержащая сопоставление угла
%                           поворота врмени.
%       result.speed - значение мгновенной скорости
%       result.speed_absc - значения абсциссы мгновенной скорости
%       result.acceleration - мгновенное значение ускорения
%       result.acceleration_absc - значения абсциссы ускорения
%       result.leTime - время между передними фронтами отметчика
%       result.teTime - время между задними фронтами отметчика

%угол, соответсвующий одной отметке
markAngle = 360/marksPerCircle;
markAngleRad = degtorad(markAngle);

angle = zeros(1,length(marker))*NaN; %значение угла в ячейках содержащих значение NaN будет рассчитано по мгновенной скорости
angle(1) = 0;
crossingTime = [];

%границы циклов
circleBeginTime = [1];
circleEndTime = [];

%мгновенная скорость
mSpeed = [];
%мгновенное ускорение
mAcc = [];

len = length(marker);
dt = 1/freq;

%счетчик количества пересечений нуля
zeroCrossings = 0;

%между фронтами
leTime = [];
teTime = [];
lastLE = 0;
lastTE = 0;

%находим начало первого цикла
firstCycleBeginTime = find(TDC(1,1:2*marksPerCircle)==max(TDC(1,1:2*marksPerCircle)),1);
firstCycleBeginTimeFounded = 1;

%ищем время начала первого полностью записанного цикла
while (firstCycleBeginTime > 1) && (firstCycleBeginTimeFounded ~= 0)
    if((marker(1,firstCycleBeginTime-1)>0 && marker(1,firstCycleBeginTime) <= 0) ||...
    (marker(1,firstCycleBeginTime-1) < 0 && marker(1,firstCycleBeginTime) >= 0))
        firstCycleBeginTimeFounded = 0;
    else
        firstCycleBeginTime = firstCycleBeginTime - 1;
    end
end

for i = 2:len    
    %отлавливаем пересечение нуля
    if((marker(1,i-1)>0 && marker(1,i) <= 0) || (marker(1,i-1) < 0 && marker(1,i) >= 0))
       %расчитываем время между фронтами
        if((marker(1,i-1)<0 && marker(1,i) >= 0)) %передний фронт
            leTime = [leTime (i - lastLE)];
            lastLE = i;
        else
            teTime = [teTime (i - lastTE)];
            lastTE = i;
        end
       
        zeroCrossings = zeroCrossings+1;
       
        %определяем границы циклов
        if (mod(zeroCrossings,2*marksPerCircle) == 0)
           circleBeginTime = [circleBeginTime i];
           circleEndTime = [circleEndTime i-1];
        end
        
        crossingTime = [crossingTime i];
        angle(1,i) = zeroCrossings*markAngle;    
    end


end

%находим мгновенную скорость
[sx mSpeed] = diff_pp(crossingTime*dt,angle(crossingTime));

%находим значение угла поворота для любого момента времени
for i = 2:len
   if isnan(angle(i)) 
       %находим момент времени наиболее близкий к текущему
       [~, closesTime] = min(abs(sx-i*dt));
       angle(i) = angle(i-1) + mSpeed(closesTime) * dt;
   end
end

%устанавливаем нулевым угол соответсвующий началу первого цикла
angle = angle - angle(firstCycleBeginTime);

%находим ускорение
[sx_unique n] = unique(sx,'first');
mSpeed_unique = mSpeed(n);
[ax mAcc] = diff_pp(sx_unique, mSpeed_unique);

result.angle_time.angle = angle;
result.angle_time.time = (1:length(marker))*dt;
result.speed = mSpeed;
result.speed_absc = sx;
result.acceleration = mAcc;
result.acceleration_absc = ax;
result.leTime = leTime * dt;
result.teTime = teTime * dt;
result.circleBeginTime = circleBeginTime;
result.circleEndTime = circleEndTime;

% figure
% plot(sx,mSpeed)
% 
% figure
% plot(ax,mAcc)

end

