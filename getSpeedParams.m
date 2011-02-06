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
%       result.circleEndTime - абсцисса конца каждого цикла
%       result.angle_time - структура, содержащая сопоставление угла
%                           поворота врмени.
%       result.speed - значение мгновенной скорости
%       result.speed_absc - значения абсциссы мгновенной скорости
%       result.acceleration - мгновенное значение ускорения
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
circleEndTime = [];

%мгновенная скорость
mSpeed = [];
%мгновенное ускорение
mAcc = [];

len = length(marker);
dt = 1/freq;

%счетчик количества пересечений оси абсцисс
zeroCrossings = 0;

%время между фронтами
leTime = []; %le = leading edge
teTime = []; %te = tailing edge
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
        else
            %Записываем время между задними фронтами
            teTime = [teTime (i - lastTE)];
            lastTE = i;
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
           circleEndTime = [circleEndTime i-1];
        end
        
        %% Записывем значения угла в текущий момент времени
        crossingTime = [crossingTime i];
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
            circleEndTime = [];
            localMaxFounded = 1;
        end
    end
end

%% Расчет мгновенной скорости и ускорения
    %% Находим мгновенную скорость
[sx mSpeed] = diff_pp(crossingTime*dt,angle(crossingTime));

    %% Определяем значение угла поворота для любого момента времени
for i = 2:len
   if isnan(angle(i)) 
       %находим момент времени наиболее близкий к текущему
       [~, closesTime] = min(abs(sx-i*dt));
       angle(i) = angle(i-1) + mSpeed(closesTime) * dt;
   end
end

    %% устанавливаем нулевым угол соответсвующий началу первого цикла
angle = angle - initialCrossingsCount*markAngle;

    %% находим ускорение
[sx_unique n] = unique(sx,'first');
mSpeed_unique = mSpeed(n);
[ax mAcc] = diff_pp(sx_unique, mSpeed_unique);

%% Запись расчитанных характеристик
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

