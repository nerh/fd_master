function [ restoredMarkerTime, restoredMarkerLevel ] = restoreMarker( marker, windowLen, level, top, bottom)
% Восстанавливает ТТЛ-сигнал отметчика
% Входные параметры:
%   marker - ординаты отметчика
%   windowLen - ширина интервала усреднения
%   level - значение уровня
% Выход:
%   restoredMarkerTime - время сигнала
%   restoredMarkerLevel - уровень сигнала
%

switch nargin
    case 1
        windowLen = 10;
        level = 0;
        top = 5;
        bottom = -5;
    case 2
        level = 0;
        top = 5;
        bottom = -5;
    case 3
        top = 5;
        bottom = -5;
end

restoredMarkerTime= [];
restoredMarkerLevel=[];

len = length(marker);
i = 1;
while(i<=len-windowLen)
   window = marker(1,i:(i+windowLen));
   if any(window < level) && any(window >= level) 
      restoredMarkerTime = [restoredMarkerTime (2*i+windowLen)/2];
      lower = find(window<level,1);
      higher = find(window>=level,1);
      if lower<higher
         restoredMarkerLevel = [restoredMarkerLevel top];
      else
         restoredMarkerLevel = [restoredMarkerLevel bottom];
      end
      i = i + windowLen;
   else
       i = i + 1;
   end
end

end

