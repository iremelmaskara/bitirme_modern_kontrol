clear all
clc;
%%%%% parametreler %%%%%%%%%%%%
kazanc=0.98;
to=115e-3;
Ref=1;
%%%%%%%%%%%%% ACTF %%%%%%%%%%%%%
ACTF= tf(kazanc,[to,1])
%%%%%%% T nin bulunması %%%%%%%%
% T nin bulunması
[n,d]=tfdata(ACTF);  
n = cell2mat(n);  % 'n' hücresini sayısal vektöre dönüştürme n = {1, 2, 3};    % n bir hücre dizisi 
d = cell2mat(d);  % 'd' hücresini sayısal vektöre dönüştürme n = cell2mat(n);   % n şimdi bir sayısal vektördür: n = [1 2 3]
payda_kokleri = roots(d);
max_kok=max(abs(payda_kokleri));
min_kok=min(abs(payda_kokleri));
kt=10;
T=1/(kt*min_kok);
%%%%%% derecenin bulunması%%%%%%
KES_derecesi=length(d)-1;
n=KES_derecesi;
%%%%%%% Z donusum %%%%%%%%%%%%%%
z_donusum_ACTF = c2d(ACTF, T, 'zoh');
[num,den]=tfdata(z_donusum_ACTF);
num= cell2mat(num); 
den= cell2mat(den);  
%%%%%%%%% Matris form %%%%%%%%%% ayrık zaman ac durum denklemleri
[A, B, C, D]=tf2ss(num, den)

%%%% artırılmış durum uzay matrisleri %%%%%%

% Aa matrisi
Aa = [A, 0;
     -C, 1];
disp('Aa matrisi:');
disp(Aa);

% Ba matrisi
Ba = [B;
      0];
disp('Ba matrisi:');
disp(Ba);

% Ca matrisi
Ca = [C,0];
disp('Ca matrisi:');
disp(Ca);

% Birim matris (Aa boyutunda)
I = eye(size(Aa));
disp('Birim matris (I):');
disp(I);

%%%%%%%%%%%%%%%%%%%%%%%%% isterler %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yuzde_asim=4.32;   %yüz ile çarpılmış
a=pi^2+log(yuzde_asim/100)^2;
ksi=-log(yuzde_asim/100)/sqrt(a);  %ksi=0.707;
ts=6/min_kok; % yüzde 2 kiriterine gore 6 tau zamanda yerleşsin
wn=4/(ksi*ts);


karakteristik_denk=[1 2*ksi*wn wn^2];
karakteristik_denk_kok= roots(karakteristik_denk);
karakteristik_denk_ayrik_zaman_baskin_kokleri= exp(karakteristik_denk_kok * T);
birinci_kok=karakteristik_denk_ayrik_zaman_baskin_kokleri(1);
ikinci_kok=karakteristik_denk_ayrik_zaman_baskin_kokleri(2);

% s1 = -ksi*wn + 1j*wn*sqrt(1 - ksi^2);
% s2 = -ksi*wn - 1j*wn*sqrt(1 - ksi^2);
% z1= exp(s1 * T);
% z2= exp(s2 * T);

ornek_ikinci_der_sis_katakteristik_denk = poly([birinci_kok ikinci_kok]);

%%%%%%%%%%%% Katsayıların bulunması %%%%%%%%%%%%%%%%%%%%
syms z
detM = det((z * I) - Aa);
detM_sade = vpa(collect(detM, z), 4);  % Tüm terimleriyle düzenlenmiş gösterim
disp('|zI - A| karakteristik denklem:')
disp(detM_sade)

%%% Kontrol edilen sistem için
%  a_matrisini oluşturalım
detM_poly = sym2poly(detM_sade);                 % Katsayıları vektör olarak al
a_matrisi_katsayilar = detM_poly(2:end).';       % En büyük dereceli terim hariç
disp('a_matrisi_katsayiları:');
disp(a_matrisi_katsayilar);

%%% Benzetilmek istenilen karakteristik denklem için (wn ve ksi) 
% şapkalı_a matrisinı bulalım 
 sapkali_a_katsayilari = ornek_ikinci_der_sis_katakteristik_denk(2:end).';
disp('şapkalı a katsayıları:');
disp(sapkali_a_katsayilari);


w= [1, a_matrisi_katsayilar(1);
     0, 1];    
disp('w matrisi:');
disp(w);

V=[Ba, Aa*Ba];
disp('V matrisi:');
disp(V);
rank(V);

%%%% K'nın bulunması
a_fark=sapkali_a_katsayilari - a_matrisi_katsayilar;
K_transpozu=([w'*V']^-1)*a_fark;  % bass gura yöntemi
K_katsayisi=K_transpozu';
K_katsayisi_sade=vpa(K_katsayisi,4);  %sadeleştirme
disp('K matrisi:');
disp(K_katsayisi_sade);

K_acker = acker(Aa, Ba, karakteristik_denk_ayrik_zaman_baskin_kokleri);
disp('K_acker matrisi:');
disp(K_acker);
