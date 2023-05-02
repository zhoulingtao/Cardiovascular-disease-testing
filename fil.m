function y = fil(x)%此函数用于滤波
fs=250;low=0.3;high=30;
[b,a] = butter(3,[49*2/fs 51*2/fs],'stop');
fil_sig_0 = filtfilt(b,a,x);
[b1,a1]=butter(3,low/(fs/2),'high');
fil_sig_1 = filtfilt(b1,a1,fil_sig_0);
[b2,a2]=butter(3,high/(fs/2),'low');
fil_sig = filtfilt(b2,a2,fil_sig_1);
y = fil_sig;
end

