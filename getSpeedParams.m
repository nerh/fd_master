%% Обработка данных с отметчика
%% Описание функции
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
%       result.angle_time - структура, содержащая сопоставление угла
%                           поворота врмени.
%       result.speed - значение мгновенной скорости (рад/сек)
%       result.speed_absc - значения абсциссы мгновенной скорости
%       result.acceleration - мгновенное значение ускорения (рад/сек)
%       result.acceleration_absc - значения абсциссы ускорения
%       result.leTime - время между передними фронтами отметчика
%       result.teTime - время между задними фронтами отметчика

%% Инициализация

%угол, соответсвующий одной отметке
markAngle = 360/marksPerCircle;
markAngleRad = degtorad(markAngle);

angle = zeros(1,length(marker))*NaN; %значение угла в ячейках содержащих значение NaN будет рассчитано по мгновенной скорости
angle(1) = 0;
crossingTime = [];

%границы циклов (между двумя пиками отметчика)
circleBeginTime = [1];

%мгновенная скорость
mSpeed = [];
%мгновенное ускорение
mAcc = [];
%мгновенная скорость по времени между передними фронтами
mSpeedLE = [];
mSpeedAngle = [];
%мгновенное ускорение по времени между передними фронтами
mAccLE = [];
mAccAngle = [];
%мгновенная скорость по времени между задними фронтами
mSpeedTE = [];
%мгновенное ускорение по времени между задними фронтами
mAccTE = [];

len = length(marker);
dt = 1/freq;

%счетчик количества пересечений оси абсцисс
zeroCrossings = 0;

%время между фронтами
leTime = []; %le = leading edge
teTime = []; %te = tailing edge
leAbsc = [];
teAbsc = [];
%время обнаружения последнего фронта
lastLE = 0;
lastTE = 0;

%угол, на который был повернут вал в момент обнаружения первого локального
%максимума ординаты отметчика
initialCrossingsCount = NaN;

%локальный максимум ординта отметчика ВМТ
localMax = -inf;
%время обнаружения локального максимума
localMaxTime = 0;
%количество пересечений на момент обнаружения локального максимума
crossingsCountForLocalMax =  0;
%время пересечения, предшествующего максимуму
crossingTimeBeforeTDC = 0;
%время последнего пересечения
lastCrossingTime = 0;
%признак обнаружения локального максимума
localMaxFounded = 0;

%% Определение угла поворота и времени между фронтами
for i = 2:len    
    %отлавливаем пересечение нуля
    if((marker(1,i-1)>0 && marker(1,i) <= 0) || (marker(1,i-1) < 0 && marker(1,i) >= 0))
       %% расчитываем время между фронтами
        if((marker(1,i-1)<0 && marker(1,i) >= 0)) %передний фронт
            %Записываем время между передними фронтами
            leTime = [leTime (i - lastLE)];
            lastLE = i;
            leAbsc = [leAbsc i];
        else
            %Записываем время между задними фронтами
            teTime = [teTime (i - lastTE)];
            lastTE = i;
            %teAbsc = [teAbsc i];
        end
       %% считаем количество пересечений
        zeroCrossings = zeroCrossings+1;
        
       %% записываем время пересечения
        if localMaxFounded==0
            lastCrossingTime = i;
        end
       
        %% определяем границы циклов
        if (mod(zeroCrossings-initialCrossingsCount,2*marksPerCircle) == 0)
           circleBeginTime = [circleBeginTime i];
        end
        
        %% Записывем значения угла в текущий момент времени
        %crossingTime = [crossingTime i];
        angle(1,i) = zeroCrossings*markAngle;    

        %% Ищем локальный максимум
        % Локальный максимум ищется в промежутке от 0 до 720 градусов
        %обновляем значение максимума
        if zeroCrossings < 2*marksPerCircle
            if TDC(1,i) > localMax
                localMax = TDC(1,i);
                localMaxTime = i;
                crossingTimeBeforeTDC = lastCrossingTime;
                crossingsCountForLocalMax = zeroCrossings;
            end
        end
        %устанавливаем начало первого цикла
        if zeroCrossings == 2*marksPerCircle
            initialCrossingsCount = crossingsCountForLocalMax;
            circleBeginTime = crossingTimeBeforeTDC;
            localMaxFounded = 1;
        end
    end
end

%% Расчет мгновенной скорости и ускорения
    %% Находим мгновенную скорость
%[sx mSpeed] = diff_pp(crossingTime*dt,angle(crossingTime));
%[sxTE mSpeedTE] = diff_pp(teAbsc*dt,angle(teAbsc));
[sxLE mSpeedLE] = diff_pp(leAbsc*dt,angle(leAbsc));

    %% Определяем значение угла поворота для любого момента времени
for i = 2:len
   if isnan(angle(i)) 
       %находим момент времени наиболее близкий к текущему
       [~, closestTime] = min(abs(sxLE-i*dt));
       angle(i) = angle(i-1) + mSpeedLE(closestTime) * dt;
   end
end

    %% устанавливаем нулевым угол соответсвующий началу первого цикла
%angle = angle - initialCrossingsCount*markAngle;

    %% находим ускорение
[sxLE_unique n] = unique(sxLE,'first');
mSpeedLE_unique = mSpeedLE(n);
[axLE mAccLE] = diff_pp(sxLE_unique, mSpeedLE_unique);

%[sxTE_unique n] = unique(sxTE,'first');
%mSpeedTE_unique = mSpeedTE(n);
%[axTE mAccTE] = diff_pp(sxTE_unique, mSpeedTE_unique);

%% Запись расчитанных характеристик
result.angle_time.angle = angle;
result.angle_time.time = (1:length(marker))*dt;
result.speed = mSpeedLE*pi/180;
result.speed_absc = sxLE;
result.speed_angle = mSpeedAngle;
result.acceleration = mAccLE*pi/180;
result.acceleration_absc = axLE;
result.leTime = leTime * dt;
result.leAbsc = leAbsc;
result.teTime = teTime * dt;
result.circleBeginTime = circleBeginTime;

%% Визуализация результатов
% figure
% hold on
% %plot(sx,mSpeed,'g')
% plot(sxLE,mSpeedLE,'r')
% plot(sxTE,mSpeedTE,'g')
% title('speed')
% set(gca,'XTick',0:720:angle(end))
% hold off
% 
% figure 
% hold on
% plot(axLE,mAccLE,'r')
% plot(axTE,mAccTE,'g')
% title('acceleration')
% set(gca,'XTick',0:720:angle(end))
% hold off
% 
% figure 
% hold on
% plot(angle(leAbsc),leTime*dt,'r')
% plot(angle(teAbsc),teTime*dt,'g')
% title('time(angle)')
% set(gca,'XTick',0:720:angle(end))
% hold off
% 
% figure
% plot(ax,mAcc)

end

