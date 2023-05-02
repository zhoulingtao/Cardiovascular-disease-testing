function [] = main(x,hz)
format short g
%本来我在此处进行了判断，因为如果提供的数据已经进行了归一化等处理，则跳过
%下一步，不用进去预处理，可是后来我发现提供的两个数据中因为不够光滑，导致
%不重新预处理一遍，过于粗糙的曲线会使得R波重复判断，所以直接进行此步。
x=beone(smooth(fil(x)));
%此处进行的是R波的查找,以及查找到的R波进行绘制
R=zeros(500,2);%主要使用差分法进行查找
Q=zeros(500,2);%因为本实验仅使用十秒的数据，所以设置500*2的矩阵足够装下
S=zeros(500,2);%R,Q,S,T,P 分别记录R,Q,S,T,P三波的数据。
T=zeros(500,2);
P=zeros(500,2);
J=zeros(500,1);
d=diff(x);
b=beone(d);
c=diff(b);
num=0;%计算出现多少个R波
for i = 2:length(x)-2
    if (c(i)>=0 && c(i-1)<0 && b(i)<0.3)%设置的阈值0.3
    for j = i:-1:0
        if d(j)<=0 && d(j-1)>0 %避免微小抖动导致的重复
            num=num+1;
            R(num,1)=j;
            R(num,2)=x(j);
        break
        end
    end
    end
end
%绘制曲线
%得到心率大小
%找到R波后向前后寻找到Q波以及S波
for i = 1:num
    for j=R(i,1):-1:2
        if d(j) >= 0 && d(j-1)<=0
            Q(i,1)=j;
            Q(i,2)=x(j);
            break
        end
    end
    for j=R(i,1)+1:length(x)
         if d(j-1) <= 0 && d(j)>=0
            S(i,1)=j;
            S(i,2)=x(j);
            break
        end
    end
end

%接下来是寻找T波以及P波
%在寻找T波的过程中有太多的小波干扰
%如果采用同之前寻找R波的办法，极度容易陷入局部最优
%因此我想到了神经网络中为了避免陷入局部最优的方法，冲量法
%想象有一个小球从S波处滚下，途中有摩擦会使得它的部分速度减少，
%同时下降的坡度会为它积累速度，让它可以冲过小坡
%最后可以停在T波处
for  i =1:num
    energy=(R(i,2)-S(i,2))/10;%设置初始能量，这是参数
    j=S(i,1);%小球滚动起点，从s波开始
    while(true)%不停滚动直到小球因为摩擦失去能量
        if energy<=R(i,2)/10000 || j>= length(x)-10%如果小球能量为0或者翻出界（基本不会），停止
            while(d(j)*d(j+1)>0)%因为很难正好停在P波波峰
                if(d(j)>0) %所以进行微调
                    j=j+1;
                else
                    j=j-1;
                end
            end
            T(i,1)=j;
            T(i,2)=x(j);%记录
            break;
        end    
        if (energy>-d(j))    %如果是下降的坡度
            j=j+1;
            energy=(energy*0.92+d(j)*1.1);%数据是我调好的，可能存在过拟合
        else
            j=j-1;
        end
    end
end

for  i =1:num %寻找p波，我使用的方法是在T波以及Q波之间，从Q 波向前找最大的波
    maxx=Q(i,1);%因为P波处的波不够大，没有一个大波来承受，及其容易出去
    mmax=Q(i,2);%所以就不能用上面的方法
    for j=Q(i,1)-1:-1:2 
        if d(j-1)>=0  &&d(j)<=0&& x(j)>mmax
             maxx=j;
             mmax=x(j);
        elseif d(j-1)>=0  &&d(j)<=0 && mmax-x(j)>=0.01
              break;
        elseif d(j-1)<=0  &&d(j)>=0 && mmax-x(j)>=0.02
              break;
        end
    end
    P(i,1)=maxx;
    P(i,2)=mmax;%记录
end

for  i =1:num %求基线
    if i==1
        dian=(fix(Q(i,1)/3)+1:fix(Q(i,1)/3*2)-1);
    else
        dian=(fix(S(i-1,1)*2/3+Q(i,1)/3)+1:fix(S(i-1,1)/3+Q(i,1)/3*2)-1);
    end
    dian2=x(dian);
    J(i)=mean(dian2);
end
hold on;
plot(x);
plot(Q(1:num,1),Q(1:num,2),'o');%绘制找到的Q波顶点
plot(T(1:num,1),T(1:num,2),'o');%绘制找到的T波顶点
plot(S(1:num,1),S(1:num,2),'o');%绘制找到的S波顶点
plot(P(1:num,1),P(1:num,2),'o');%绘制找到的P波顶点
HR=show(R,num,hz);

disp('您的心率是:');
disp(HR);
flag=0;
disp('您可能患有的疾病是:')
if(mean(R(1:num,2)-J(1:num))/mean(T(1:num,2)-J(1:num))>10)%如果T波过低
    disp('T波异常')
    disp('冠心病、心肌炎、心肌缺血或者低血钾')
    flag=1;
end
if(sum(abs(Q(1:num,2)-J(1:num))>4*T(1:num,2)-J(1:num))/num>0.1)%如果Q波异常
    disp('Q波异常')
    disp('心肌梗塞')
    flag=1;
end
if(HR<60)%如果心率过低
    disp('心率异常')
    disp('窦性心率过缓')
    flag=1;
elseif(HR>100)
    disp('心率异常')
    disp('窦性心动过速')
    flag=1;
end
for i=1:num
    cou=0;cuo=0;
    if(min(S(i,1):T(i,1))>J(i))
        cou=cou+1;
    elseif(max(S(i,1):T(i,1))<J(i))%
        cuo=cuo+1;
    end
end
if(cou/num>0.1)
    disp('ST段异常')
    disp('超急性期或急性期心肌梗死、变异型心绞痛、室壁瘤、急性心包炎、急性心肌炎、心脏手术后心肌损伤、左束支阻滞、左心室肥大以及肥厚型心肌病');
    flag=1;
end
if(cuo/num>0.1)
    disp('ST段异常')
    disp('典型心绞痛、各类心肌病、心室肥大、心肌炎、左束支阻滞、右束支阻滞、预激综合征、自主神经功能紊乱以及慢性心肌缺血');
    flag=1;
end

if(~flag)
    disp('无')
end
disp(' ')
disp('此检测仅适用于正常成年人，检测结果仅供参考，具体疾病情况请询问医生，本检测不对因检测结果造成的损失承担任何责任')
end



