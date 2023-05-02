function HR=show(y,num,hz)
time=mean(diff(y(1:num,1)))/hz;%平均心动周期
HR=1/time*60;%计算心率
plot(y(1:num,1),y(1:num,2),'o');%绘制找到的R波顶点
set(gca,'Xlim',[0 1000]);
end