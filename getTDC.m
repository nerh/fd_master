function [ tdcForCurrentCylinder ] = getTDC( tdc, mainCylinder, currentCylinder, positions )
%getTDC - расчет ВМТ для заданного цилиндра
%
%Входные параметры:
%   tdc - вектор значений вмт в градусах
%   mainCylinder - цилиндр для которого было найдено вмт
%   currentCylinder - цилиндр для которого нужно найти вмт
%   positions - очередность работы цилиндров
%Выходные параметры:
%   tdcForCurrentCylinder - вмт для заданного цилиндра
    dc = positions(currentCylinder) - positions(mainCylinder);
    tdcForCurrentCylinder = tdc + 90*dc;
end

