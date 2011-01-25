 pressure = load('/home/nerh/sent/ConvertedData/Режим_1/Pressure_2.mat');
 speed = load('/home/nerh/sent/ConvertedData/Режим_1/Speed_2_interp.mat');
 
 pressureParams = getPressureParams(pressure.loadedFile.data(:,3)', 0.5, 25000, 30,10,1);
 speedParams = getSpeedParams(speed.loadedFile.data(:,3)',speed.loadedFile.data(:,4)',25000,1440);

figure
hold on

plot(speedParams.angle_time.angle(1:length(pressure.loadedFile.data(:,3))), pressure.loadedFile.data(:,3))
set(gca,'XTick',0:720:speedParams.angle_time.angle(end))
hold off
