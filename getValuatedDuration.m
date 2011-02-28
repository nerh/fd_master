function [ valuatedDuration ] = getValuatedDuration( marker, tdc )
%Функця возвращает нормированное относительно продолжительносит цикла время
%между фронтами сигнала
%
%Входные данные:
%   marker - моменты времени, соответствующие переднему или заднему фронту
%            сигнала
%   tdc - границы циклов
%
%Выходные данные:
%   valuatedDuration - нормированное время между фронтами.

valuatedDuration = [];

%отбрасываем значения, не образующие полный цикл
marker = marker((marker>=tdc(1))<tdc(end));

%находим длительности циклов
cycleDuration = diff(tdc);

%нормируем время между фронтами
for i = 2:length(tdc)
   cycleIndices = logical((marker>=tdc(i-1)).*(marker<tdc(i)));
   marker(cycleIndices) = marker(cycleIndices)./cycleDuration(i-1);
   valuatedDuration = [valuatedDuration diff(marker(cycleIndices))];
end

%valuatedDuration = diff(marker);

end

